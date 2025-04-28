require 'rails_helper'

RSpec.describe Notification, type: :model do
  describe '#target_status' do
    let(:notification) { Fabricate(:notification, activity: activity) }
    let(:status)       { Fabricate(:status) }
    let(:reblog)       { Fabricate(:status, reblog: status) }
    let(:favourite)    { Fabricate(:favourite, status: status) }
    let(:mention)      { Fabricate(:mention, status: status) }
    let(:invite)       { Fabricate(:invite) }
    let(:user)         { Fabricate(:user, approved: false) }

    context 'activity is reblog' do
      let(:activity) { reblog }

      it 'returns status' do
        expect(notification.target_status).to eq status
      end
    end

    context 'activity is favourite' do
      let(:type)     { :favourite }
      let(:activity) { favourite }

      it 'returns status' do
        expect(notification.target_status).to eq status
      end
    end

    context 'activity is mention' do
      let(:activity) { mention }

      it 'returns status' do
        expect(notification.target_status).to eq status
      end
    end
  end

  describe '#type' do
    it 'returns :reblog for a Status' do
      notification = Notification.new(activity: Status.new)
      expect(notification.type).to eq :reblog
    end

    it 'returns :mention for a Mention' do
      notification = Notification.new(activity: Mention.new)
      expect(notification.type).to eq :mention
    end

    it 'returns :favourite for a Favourite' do
      notification = Notification.new(activity: Favourite.new)
      expect(notification.type).to eq :favourite
    end

    it 'returns :follow for a Follow' do
      notification = Notification.new(activity: Follow.new)
      expect(notification.type).to eq :follow
    end

    it 'returns :invite for a Invite' do
      notification = Notification.new(activity: Invite.new)
      expect(notification.type).to eq :invite
    end

    it 'returns :user_approved for a User' do
      notification = Notification.new(activity: User.new)
      expect(notification.type).to eq :user_approved
    end

    it 'returns :verify_sms_prompt' do
      notification = Notification.new(activity: User.new, type: 'verify_sms_prompt')
      expect(notification.type).to eq :verify_sms_prompt
    end
  end

  describe '.preload_cache_collection_target_statuses' do
    subject do
      described_class.preload_cache_collection_target_statuses(notifications) do |target_statuses|
        # preload account for testing instead of using cache_collection
        Status.preload(:account).where(id: target_statuses.map(&:id))
      end
    end

    context 'notifications are empty' do
      let(:notifications) { [] }

      it 'returns []' do
        is_expected.to eq []
      end
    end

    context 'notifications are present' do
      before do
        notifications.each(&:reload)
      end

      let(:mention)        { Fabricate(:mention) }
      let(:status)         { Fabricate(:status) }
      let(:reblog)         { Fabricate(:status, reblog: Fabricate(:status)) }
      let(:follow)         { Fabricate(:follow) }
      let(:follow_request) { Fabricate(:follow_request) }
      let(:favourite)      { Fabricate(:favourite) }
      let(:poll)           { Fabricate(:poll) }
      let(:invite)         { Fabricate(:invite) }
      let(:user)           { Fabricate(:user, approved: true) }

      let(:notifications) do
        [
          Fabricate(:notification, type: :mention, activity: mention),
          Fabricate(:notification, type: :status, activity: status),
          Fabricate(:notification, type: :reblog, activity: reblog),
          Fabricate(:notification, type: :follow, activity: follow),
          Fabricate(:notification, type: :follow_request, activity: follow_request),
          Fabricate(:notification, type: :favourite, activity: favourite),
          Fabricate(:notification, type: :poll, activity: poll),
          Fabricate(:notification, type: :invite, activity: invite),
          Fabricate(:notification, type: :user_approved, activity: user),
          Fabricate(:notification, type: :verify_sms_prompt, activity: user),
        ]
      end

      it 'preloads target status' do
        # mention
        expect(subject[0].type).to eq :mention
        expect(subject[0].association(:mention)).to be_loaded
        expect(subject[0].mention.association(:status)).to be_loaded

        # status
        expect(subject[1].type).to eq :status
        expect(subject[1].association(:status)).to be_loaded

        # reblog
        expect(subject[2].type).to eq :reblog
        expect(subject[2].association(:status)).to be_loaded
        expect(subject[2].status.association(:reblog)).to be_loaded

        # follow: nothing
        expect(subject[3].type).to eq :follow
        expect(subject[3].target_status).to be_nil

        # follow_request: nothing
        expect(subject[4].type).to eq :follow_request
        expect(subject[4].target_status).to be_nil

        # favourite
        expect(subject[5].type).to eq :favourite
        expect(subject[5].association(:favourite)).to be_loaded
        expect(subject[5].favourite.association(:status)).to be_loaded

        # poll
        expect(subject[6].type).to eq :poll
        expect(subject[6].association(:poll)).to be_loaded
        expect(subject[6].poll.association(:status)).to be_loaded

        # invite
        expect(subject[7].type).to eq :invite
        expect(subject[7].invite.association(:users)).to be_loaded

        # user_approved
        expect(subject[8].type).to eq :user_approved
        expect(subject[8].association(:user)).to be_loaded

        # verify_sms_prompt
        expect(subject[9].type).to eq :verify_sms_prompt
        expect(subject[9].association(:user)).to be_loaded
      end

      it 'replaces to cached status' do
        # mention
        expect(subject[0].type).to eq :mention
        expect(subject[0].target_status.association(:account)).to be_loaded
        expect(subject[0].target_status).to eq mention.status

        # status
        expect(subject[1].type).to eq :status
        expect(subject[1].target_status.association(:account)).to be_loaded
        expect(subject[1].target_status).to eq status

        # reblog
        expect(subject[2].type).to eq :reblog
        expect(subject[2].target_status.association(:account)).to be_loaded
        expect(subject[2].target_status).to eq reblog.reblog

        # follow: nothing
        expect(subject[3].type).to eq :follow
        expect(subject[3].target_status).to be_nil

        # follow_request: nothing
        expect(subject[4].type).to eq :follow_request
        expect(subject[4].target_status).to be_nil

        # favourite
        expect(subject[5].type).to eq :favourite
        expect(subject[5].target_status.association(:account)).to be_loaded
        expect(subject[5].target_status).to eq favourite.status

        # poll
        expect(subject[6].type).to eq :poll
        expect(subject[6].target_status.association(:account)).to be_loaded
        expect(subject[6].target_status).to eq poll.status
      end
    end
  end
end
