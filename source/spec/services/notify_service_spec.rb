require 'rails_helper'

RSpec.describe NotifyService, type: :service do
  subject do
    -> { described_class.new.call(recipient, type, activity) }
  end

  let(:user) { Fabricate(:user) }
  let(:recipient) { user.account }
  let(:sender) { Fabricate(:account, domain: 'example.com', url: 'http://example.com/account') }
  let(:activity) { Fabricate(:follow, account: sender, target_account: recipient) }
  let(:type) { :follow }

  it { is_expected.to change(Notification, :count).by(1) }

  it 'does not notify when sender is blocked' do
    recipient.block!(sender)
    is_expected.to_not change(Notification, :count)
  end

  it 'does not notify when recipient is blocked' do
    sender.block!(recipient)
    is_expected.to_not change(Notification, :count)
  end

  it 'does not notify when sender is muted with hide_notifications' do
    recipient.mute!(sender, notifications: true)
    is_expected.to_not change(Notification, :count)
  end

  it 'does notify when sender is muted without hide_notifications' do
    recipient.mute!(sender, notifications: false)
    is_expected.to change(Notification, :count)
  end

  it 'does not notify when sender\'s domain is blocked' do
    recipient.block_domain!(sender.domain)
    is_expected.to_not change(Notification, :count)
  end

  it 'does still notify when sender\'s domain is blocked but sender is followed' do
    recipient.block_domain!(sender.domain)
    recipient.follow!(sender)
    is_expected.to change(Notification, :count)
  end

  it 'does not notify when sender is silenced and not followed' do
    sender.silence!
    is_expected.to_not change(Notification, :count)
  end

  it 'does not notify when recipient is suspended' do
    recipient.suspend!
    is_expected.to_not change(Notification, :count)
  end

  context 'for direct messages' do
    let(:activity) { Fabricate(:mention, account: recipient, status: Fabricate(:status, account: sender, visibility: :direct)) }
    let(:type)     { :mention }

    before do
      user.settings.interactions = user.settings.interactions.merge('must_be_following_dm' => enabled)
    end

    context 'if recipient is supposed to be following sender' do
      let(:enabled) { true }

      it 'does not notify' do
        is_expected.to_not change(Notification, :count)
      end

      context 'if the message chain initiated by recipient, but is not direct message' do
        let(:reply_to) { Fabricate(:status, account: recipient) }
        let(:activity) { Fabricate(:mention, account: recipient, status: Fabricate(:status, account: sender, visibility: :direct, thread: reply_to)) }

        it 'does not notify' do
          is_expected.to_not change(Notification, :count)
        end
      end

      context 'if the message chain initiated by recipient and is direct message' do
        let(:reply_to) { Fabricate(:status, account: recipient, visibility: :direct) }
        let(:activity) { Fabricate(:mention, account: recipient, status: Fabricate(:status, account: sender, visibility: :direct, thread: reply_to)) }

        it 'does notify' do
          is_expected.to change(Notification, :count)
        end
      end
    end

    context 'if recipient is NOT supposed to be following sender' do
      let(:enabled) { false }

      it 'does notify' do
        is_expected.to change(Notification, :count)
      end
    end
  end

  describe 'reblogs' do
    let(:status)   { Fabricate(:status, account: Fabricate(:account)) }
    let(:activity) { Fabricate(:status, account: sender, reblog: status) }
    let(:type)     { :reblog }

    it 'shows reblogs by default' do
      recipient.follow!(sender)
      is_expected.to change(Notification, :count)
    end

    it 'shows reblogs when explicitly enabled' do
      recipient.follow!(sender, reblogs: true)
      is_expected.to change(Notification, :count)
    end

    it 'shows reblogs when disabled' do
      recipient.follow!(sender, reblogs: false)
      is_expected.to change(Notification, :count)
    end
  end

  describe 'user_approved' do
    let(:user) { Fabricate(:user, approved: false) }

    before do
      ActionMailer::Base.deliveries.clear

      notification_emails = user.settings.notification_emails
      user.settings.notification_emails = notification_emails.merge('user_approved' => true)
      user.update(approved: true)
    end

    it 'creates a notification' do
      is_expected.to change(Notification, :count)
    end

    it 'sends an email' do
      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(ActionMailer::Base.deliveries[0].subject).to eq(I18n.t('notification_mailer.user_approved.title', name: user.account.username))
    end

    it 'builds the right notification json' do
      notification = ActiveModelSerializers::SerializableResource.new(
        Notification.last,
        serializer: Mobile::NotificationSerializer,
        scope: OpenStruct.new(device_token: "a"),
        scope_name: :current_push_subscription
      ).as_json

      expect(notification[:message]).to eq(I18n.t('notification_mailer.user_approved.subject'))
    end
  end

  context do
    let(:asshole)  { Fabricate(:account, username: 'asshole') }
    let(:reply_to) { Fabricate(:status, account: asshole) }
    let(:activity) { Fabricate(:mention, account: recipient, status: Fabricate(:status, account: sender, thread: reply_to)) }
    let(:type)     { :mention }

    it 'does not notify when conversation is muted' do
      recipient.mute_conversation!(activity.status.conversation)
      is_expected.to_not change(Notification, :count)
    end

    it 'does not notify when it is a reply to a blocked user' do
      recipient.block!(asshole)
      is_expected.to_not change(Notification, :count)
    end
  end

  context do
    let(:sender) { recipient }

    it 'does not notify when recipient is the sender' do
      is_expected.to_not change(Notification, :count)
    end
  end

  describe 'email' do
    before do
      ActionMailer::Base.deliveries.clear

      notification_emails = user.settings.notification_emails
      user.settings.notification_emails = notification_emails.merge('follow' => enabled)
    end

    context 'when email notification is enabled' do
      let(:enabled) { true }

      it 'sends email' do
        is_expected.to change(ActionMailer::Base.deliveries, :count).by(1)
      end
    end

    context 'when email notification is disabled' do
      let(:enabled) { false }

      it "doesn't send email" do
        is_expected.to_not change(ActionMailer::Base.deliveries, :count).from(0)
      end
    end
  end

  describe 'whale users' do
    let(:user) { Fabricate(:user, account: Fabricate(:account, whale: true))}
    let(:recipient) { user.account }

    context 'if a whale user is followed' do
      let(:activity) { Fabricate(:follow, account: sender, target_account: recipient) }
      let(:type) { :follow }

      it 'does not notify immediately' do
        group_notifications_service = double(:group_notifications_service)
        allow(group_notifications_service).to receive(:call)
        allow(GroupNotificationsService).to receive(:new).and_return(group_notifications_service)

        is_expected.to_not change(Notification, :count)

        expect(GroupNotificationsService).to have_received(:new)
        expect(group_notifications_service).to have_received(:call)
      end
    end

    context 'if a whale\'s status is favourited' do
      let(:status)   { Fabricate(:status, account: recipient) }
      let(:activity) { Fabricate(:favourite, account: sender, status: status) }
      let(:type) { :favourite }

      it 'does not notify immediately' do
        group_notifications_service = double(:group_notifications_service)
        allow(group_notifications_service).to receive(:call)
        allow(GroupNotificationsService).to receive(:new).and_return(group_notifications_service)

        is_expected.to_not change(Notification, :count)

        expect(GroupNotificationsService).to have_received(:new)
        expect(group_notifications_service).to have_received(:call)
      end
    end

    context 'if a whale\'s status is rebloged' do
      let(:status)   { Fabricate(:status, account: recipient) }
      let(:activity) { Fabricate(:favourite, account: sender, status: status) }
      let(:type) { :reblog }

      it 'does not notify immediately' do
        group_notifications_service = double(:group_notifications_service)
        allow(group_notifications_service).to receive(:call)
        allow(GroupNotificationsService).to receive(:new).and_return(group_notifications_service)

        is_expected.to_not change(Notification, :count)

        expect(GroupNotificationsService).to have_received(:new)
        expect(group_notifications_service).to have_received(:call)
      end
    end

    context 'if a whale is mentioned in a status created by others' do
      let(:reply_to) { Fabricate(:status, account: sender) }
      let(:activity) { Fabricate(:mention, account: recipient, status: Fabricate(:status, account: sender, thread: reply_to)) }
      let(:type)     { :mention }

      it 'does notify' do
        is_expected.to change(Notification, :count)
      end
    end

    context 'if a whale is mentioned in a status created by the whale' do
      let(:reply_to) { Fabricate(:status, account: recipient) }
      let(:activity) { Fabricate(:mention, account: recipient, status: Fabricate(:status, account: sender, thread: reply_to)) }
      let(:type)     { :mention }

      it 'does not notify immediately' do
        group_notifications_service = double(:group_notifications_service)
        allow(group_notifications_service).to receive(:call)
        allow(GroupNotificationsService).to receive(:new).and_return(group_notifications_service)

        is_expected.to_not change(Notification, :count)

        expect(GroupNotificationsService).to have_received(:new)
        expect(group_notifications_service).to have_received(:call)
      end
    end

    context 'if a whale is mentioned at a deeper level in a status created by the whale' do
      let(:commenter) { Fabricate(:account)}
      let(:reply_to_1) { Fabricate(:status, account: recipient) }
      let(:reply_to_2) { Fabricate(:status, account: commenter, thread: reply_to_1) }
      let(:activity) { Fabricate(:mention, account: recipient, status: Fabricate(:status, account: sender, thread: reply_to_2)) }
      let(:type)     { :mention }

      it 'does not notify immediately' do
        group_notifications_service = double(:group_notifications_service)
        allow(group_notifications_service).to receive(:call)
        allow(GroupNotificationsService).to receive(:new).and_return(group_notifications_service)

        is_expected.to_not change(Notification, :count)

        expect(GroupNotificationsService).to have_received(:new)
        expect(group_notifications_service).to have_received(:call)
      end
    end
  end

  describe 'all' do
    let(:notification) { Fabricate(:notification, account: recipient, activity: activity) }

    it 'includes the right JSON "extend" key' do
      body = ActiveModelSerializers::SerializableResource.new(
        notification,
        serializer: Mobile::NotificationSerializer,
        scope: OpenStruct.new(device_token: "a"),
        scope_name: :current_push_subscription
      ).as_json

      expect(body[:extend].first['key']).to eq('truthLink')
      expect(body[:extend].first['val']).to eq(sender.url)
      expect(body[:extend].second['key']).to eq('title')
      expect(body[:extend].second['val']).to eq('Truth Social')
      expect(body[:extend].third['key']).to eq('accountId')
      expect(body[:extend].third['val']).to eq(recipient.id.to_s)
    end
  end
end
