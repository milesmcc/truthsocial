require 'rails_helper'

RSpec.describe PostStatusService, type: :service do
  subject { PostStatusService.new }
  before do
    acct = Fabricate(:account, username: 'ModerationAI')
    Fabricate(:user, admin: true, account: acct)
    stub_request(:post, ENV['MODERATION_TASK_API_URL']).to_return(status: 200, body: request_fixture('moderation-response-0.txt'))
  end

  it 'creates a new status' do
    account = Fabricate(:account)
    text = 'test status update'

    status = subject.call(account, text: text)

    expect(status).to be_persisted
    expect(status.text).to eq text
  end

  it 'creates a new response status' do
    in_reply_to_status = Fabricate(:status)
    account = Fabricate(:account)
    text = 'test status update'

    status = subject.call(account, text: text, thread: in_reply_to_status)

    expect(status).to be_persisted
    expect(status.text).to eq text
    expect(status.thread).to eq in_reply_to_status
  end

  it 'schedules a status' do
    account = Fabricate(:account)
    future  = Time.now.utc + 2.hours

    status = subject.call(account, text: 'Hi future!', scheduled_at: future)

    expect(status).to be_a ScheduledStatus
    expect(status.scheduled_at).to eq future
    expect(status.params['text']).to eq 'Hi future!'
  end

  it 'does not immediately create a status when scheduling a status' do
    account = Fabricate(:account)
    media = Fabricate(:media_attachment)
    future  = Time.now.utc + 2.hours

    status = subject.call(account, text: 'Hi future!', media_ids: [media.id], scheduled_at: future)

    expect(status).to be_a ScheduledStatus
    expect(status.scheduled_at).to eq future
    expect(status.params['text']).to eq 'Hi future!'
    expect(media.reload.status).to be_nil
    expect(Status.where(text: 'Hi future!').exists?).to be_falsey
  end

  it 'creates response to the original status of boost' do
    boosted_status = Fabricate(:status)
    in_reply_to_status = Fabricate(:status, reblog: boosted_status)
    account = Fabricate(:account)
    text = 'test status update'

    status = subject.call(account, text: text, thread: in_reply_to_status)

    expect(status).to be_persisted
    expect(status.text).to eq text
    expect(status.thread).to eq boosted_status
  end

  it 'creates a sensitive status' do
    status = create_status_with_options(sensitive: true)

    expect(status).to be_persisted
    expect(status).to be_sensitive
  end

  it 'creates a status with spoiler text' do
    spoiler_text = 'spoiler text'

    status = create_status_with_options(spoiler_text: spoiler_text)

    expect(status).to be_persisted
    expect(status.spoiler_text).to eq spoiler_text
  end

  it 'creates a sensitive status when there is a CW but no text' do
    status = subject.call(Fabricate(:account), text: '', spoiler_text: 'foo')

    expect(status).to be_persisted
    expect(status).to be_sensitive
  end

  it 'creates a status with empty default spoiler text' do
    status = create_status_with_options(spoiler_text: nil)

    expect(status).to be_persisted
    expect(status.spoiler_text).to eq ''
  end

  it 'creates a status with the given visibility' do
    status = create_status_with_options(visibility: :private)

    expect(status).to be_persisted
    expect(status.visibility).to eq 'private'
  end

  it 'creates a status with limited visibility for silenced users' do
    status = subject.call(Fabricate(:account, silenced: true), text: 'test', visibility: :public)

    expect(status).to be_persisted
    expect(status.visibility).to eq 'unlisted'
  end

  it 'creates a status for the given application' do
    application = Fabricate(:application)

    status = create_status_with_options(application: application)

    expect(status).to be_persisted
    expect(status.application).to eq application
  end

  it 'creates a status with a language set' do
    account = Fabricate(:account)
    text = 'This is an English text.'

    status = subject.call(account, text: text)

    expect(status.language).to eq 'en'
  end

  it 'processes mentions' do
    mention_service = double(:process_mentions_service)
    allow(mention_service).to receive(:call)
    allow(ProcessMentionsService).to receive(:new).and_return(mention_service)
    account = Fabricate(:account)

    status = subject.call(account, text: 'test status update')

    expect(ProcessMentionsService).to have_received(:new)
    expect(mention_service).to have_received(:call).with(status, [], nil)
  end

  it 'processes hashtags' do
    hashtags_service = double(:process_hashtags_service)
    allow(hashtags_service).to receive(:call)
    allow(ProcessHashtagsService).to receive(:new).and_return(hashtags_service)
    account = Fabricate(:account)

    status = subject.call(account, text: 'test status update')

    expect(ProcessHashtagsService).to have_received(:new)
    expect(hashtags_service).to have_received(:call).with(status)
  end

  it 'gets distributed' do
    post_distribution_service = double(:post_distribution_service)
    allow(post_distribution_service).to receive(:distribute_to_author)
    allow(PostDistributionService).to receive(:new).and_return(post_distribution_service)

    allow(DistributionWorker).to receive(:perform_async)
    allow(ActivityPub::DistributionWorker).to receive(:perform_async)

    account = Fabricate(:account)

    status = subject.call(account, text: 'test status update')

    expect(post_distribution_service).to have_received(:distribute_to_author).with(status)
    # expect(ActivityPub::DistributionWorker).to have_received(:perform_async).with(status.id)
  end

  it 'crawls links' do
    allow(LinkCrawlWorker).to receive(:perform_async)
    account = Fabricate(:account)

    status = subject.call(account, text: 'test status update')

    expect(LinkCrawlWorker).to have_received(:perform_async).with(status.id, nil, nil)
  end

  context 'includes media attachment' do
    before :example do
      stub_request(:post, ENV['MODERATION_TASK_API_URL'])
        .to_return(status: 200, body: request_fixture('moderation-response-0.txt'))
        .to_return(status: 200, body: request_fixture('moderation-image-response.txt'))
    end
    it 'attaches the given media to the created status' do
      account = Fabricate(:account)
      media = Fabricate(:media_attachment, account: account)

      status = subject.call(
        account,
        text: 'test status update',
        media_ids: [media.id],
      )

      expect(media.reload.status).to eq status
    end
    it 'returns medias in the same order as they are defined in media_ids[] whhen creating a status' do
      account = Fabricate(:account)
      media1 = Fabricate(:media_attachment, account: account)
      media2 = Fabricate(:media_attachment, account: account)
      media3 = Fabricate(:media_attachment, account: account)
      media4 = Fabricate(:media_attachment, account: account)

      status = subject.call(
        account,
        text: 'test attachments order',
        media_ids: [media2.id, media1.id, media4.id, media3.id],
      )

      expect(status.reload.media_attachments).to eq [media2, media1, media4, media3]
    end
  end

  it 'does not attach media from another account to the created status' do
    account = Fabricate(:account)
    media = Fabricate(:media_attachment, account: Fabricate(:account))

    status = subject.call(
      account,
      text: 'test status update',
      media_ids: [media.id],
    )

    expect(media.reload.status).to eq nil
  end

  it 'does not allow attaching more than 4 files' do
    account = Fabricate(:account)

    expect do
      subject.call(
        account,
        text: 'test status update',
        media_ids: [
          Fabricate(:media_attachment, account: account),
          Fabricate(:media_attachment, account: account),
          Fabricate(:media_attachment, account: account),
          Fabricate(:media_attachment, account: account),
          Fabricate(:media_attachment, account: account),
        ].map(&:id),
      )
    end.to raise_error(
      Mastodon::ValidationError,
      I18n.t('media_attachments.validations.too_many'),
    )
  end

  it 'allows attaching multiple videos and images' do
    allow(UploadVideoStatusWorker).to receive(:perform_async).exactly(2).times

    account = Fabricate(:account)
    video = Fabricate(:media_attachment, type: :video, account: account)
    video2 = Fabricate(:media_attachment, type: :video, account: account)
    image = Fabricate(:media_attachment, type: :image, account: account)

    video.update(type: :video)

    expect do
      subject.call(
        account,
        text: 'test status update',
        media_ids: [
          video,
          image,
          video2,
        ].map(&:id),
      )
    end.not_to raise_error

    expect(UploadVideoStatusWorker).to have_received(:perform_async).exactly(2).times
  end

  it 'returns existing status when used twice with idempotency key' do
    account = Fabricate(:account)
    status1 = subject.call(account, text: 'test', idempotency: 'meepmeep')
    status2 = subject.call(account, text: 'test', idempotency: 'meepmeep')
    expect(status2.id).to eq status1.id
  end

  def create_status_with_options(**options)
    subject.call(Fabricate(:account), options.merge(text: 'test'))
  end

  context 'posting to a group' do
    let(:acct) { Fabricate(:account, username: 'bob') }
    let(:group) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: acct) }

    before do
      group.memberships.create!(account: acct, role: :owner)
    end

    it 'creates a status that is displayable on the home timeline if a group is attached' do
      status = subject.call(acct, text: 'test', visibility: :group, group: group, group_timeline_visible: true)

      expect(status).to be_persisted
      expect(status.visibility).to eq 'group'
      expect(status.group_timeline_visible).to eq true
    end
  end

  context 'interactions tracking' do
    let(:bob) { Fabricate(:user, email: 'bob@example.com', account: Fabricate(:account, username: 'bob')) }
    let(:alice) { Fabricate(:user, email: 'alice@example.com', account: Fabricate(:account, username: 'alice')) }
    let(:in_reply_to_status) { Fabricate(:status, account: bob.account) }
    let(:quote_status) { Fabricate(:status, account: bob.account) }
    let(:text) { 'test status update' }
    let(:current_week) { Time.now.strftime('%U').to_i }

    context 'with a reply from a not-followed account' do
      let(:initial_score) { 5 }

      before do
        Redis.current.set("interactions_score:#{bob.account_id}:#{current_week}", 5)
        status = subject.call(alice.account, text: text, thread: in_reply_to_status)
      end

      it 'creates interactions record' do
        expect(Redis.current.zrange("interactions:#{alice.account_id}", 0, -1)).to eq [bob.account_id.to_s]
        expect(Redis.current.zrange("followers_interactions:#{alice.account_id}:#{current_week}", 5, -1)).to eq []
      end

      it 'increments target account score for interactions' do
        expect(Redis.current.get("interactions_score:#{bob.account_id}:#{current_week}")).to eq (initial_score + InteractionsTracker::WEIGHTS[:reply]).to_s
      end
    end

    context 'with a reply from a followed account' do
      let(:initial_score) { 10 }

      before do
        Redis.current.set("interactions_score:#{bob.account_id}:#{current_week}", 10)
        alice.account.follow!(bob.account)
        status = subject.call(alice.account, text: text, thread: in_reply_to_status)
      end

      it 'creates followers interactions record' do
        expect(Redis.current.zrange("interactions:#{alice.account_id}", 0, -1)).to eq []
        expect(Redis.current.zrange("followers_interactions:#{alice.account_id}:#{current_week}", 0, -1)).to eq [bob.account_id.to_s]
      end

      it 'increments target account score for interactions' do
        expect(Redis.current.get("interactions_score:#{bob.account_id}:#{current_week}")).to eq (initial_score + InteractionsTracker::WEIGHTS[:reply]).to_s
      end
    end

    context 'group status reply' do
      let(:initial_score) { 10 }
      let(:group) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: alice.account, statuses_visibility: :members_only) }
      let(:reply_status) { Fabricate(:status, account: bob.account, visibility: 'group', group: group) }

      before do
        GroupMembership.create!(account: bob.account, group: group, role: :owner)
        GroupMembership.create!(account: alice.account, group: group, role: :user)
        subject.call(alice.account, text: text, thread: reply_status, group: group, group_visibility: :members_only, visibility: :group)
      end

      it 'creates groups interactions record' do
        expect(Redis.current.zrange("groups_interactions:#{alice.account_id}:#{current_week}", 0, -1, with_scores: true)).to eq [[group.id.to_s, 1.0]]
      end
    end

    context 'with a quote from a not-followed account' do
      let(:initial_score) { 5 }

      before do
        Redis.current.set("interactions_score:#{bob.account_id}:#{current_week}", initial_score)
        status = subject.call(alice.account, text: text, quote_id: quote_status.id)
      end

      it 'creates interactions record' do
        expect(Redis.current.zrange("interactions:#{alice.account_id}", 0, -1)).to eq [bob.account_id.to_s]
        expect(Redis.current.zrange("followers_interactions:#{alice.account_id}:#{current_week}", 5, -1)).to eq []
      end

      it 'increments target account score for interactions' do
        expect(Redis.current.get("interactions_score:#{bob.account_id}:#{current_week}")).to eq (initial_score + InteractionsTracker::WEIGHTS[:quote]).to_s
      end
    end

    context 'with a quote from a followed account' do
      let(:initial_score) { 10 }

      before do
        Redis.current.set("interactions_score:#{bob.account_id}:#{current_week}", 10)
        alice.account.follow!(bob.account)
        status = subject.call(alice.account, text: text, quote_id: quote_status.id)
      end

      it 'creates followers interactions record' do
        expect(Redis.current.zrange("interactions:#{alice.account_id}", 0, -1)).to eq []
        expect(Redis.current.zrange("followers_interactions:#{alice.account_id}:#{current_week}", 0, -1)).to eq [bob.account_id.to_s]
      end

      it 'increments target account score for interactions' do
        expect(Redis.current.get("interactions_score:#{bob.account_id}:#{current_week}")).to eq (initial_score + InteractionsTracker::WEIGHTS[:quote]).to_s
      end
    end

    context 'group quote' do
      let(:group) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: alice.account, statuses_visibility: :members_only) }
      let(:group_quote) { Fabricate(:status, account: bob.account, group: group, visibility: :group) }

      before do
        GroupMembership.create!(account: bob.account, group: group, role: :owner)
        GroupMembership.create!(account: alice.account, group: group, role: :user)
        subject.call(alice.account, text: text, quote_id: group_quote.id, group: group, visibility: :group)
      end

      it 'creates groups interactions record' do
        expect(Redis.current.zrange("groups_interactions:#{alice.account_id}:#{current_week}", 0, -1, with_scores: true)).to eq [[group.id.to_s, 10.0]]
      end
    end

    context 'link shortener' do
      it 'processes links' do
        status_text = 'test_status'

        links_service = double(:process_links_service)
        allow(links_service).to receive(:resolve_urls).and_return(status_text)
        allow(links_service).to receive(:call)

        allow(ProcessStatusLinksService).to receive(:new).and_return(links_service)
        account = Fabricate(:account)

        status = subject.call(account, text: status_text)

        expect(ProcessStatusLinksService).to have_received(:new)
        expect(links_service).to have_received(:resolve_urls).with(status.text)
        expect(links_service).to have_received(:call).with(status)
      end

      it 'replaces urls pointing to the link shortener with their original url' do
        stub_request(:get, 'https://example.com/').to_return(status: 200)
        account = Fabricate(:account)

        status = subject.call(account, text: 'Check this out https://example.com')
        status_1 = subject.call(account, text: "Hello https://links.#{Rails.configuration.x.web_domain}/link/#{status.links.first.id}")

        expect(status_1.text).to eq('Hello https://example.com')
      end

      it 'replaces urls pointing to the link shortener with query parms with their original url' do
        stub_request(:get, 'https://example.com/').to_return(status: 200)
        account = Fabricate(:account)

        status = subject.call(account, text: 'Check this out https://example.com')
        status_1 = subject.call(account, text: "Hello https://links.#{Rails.configuration.x.web_domain}/link/#{status.links.first.id}/?test")

        expect(status_1.text).to eq('Hello https://example.com')
      end

      it 'does not replace urls to the link shortener with nonexistent id' do
        link = "https://links.#{Rails.configuration.x.web_domain}/link/2222"
        stub_request(:get, 'https://example.com/').to_return(status: 200)
        stub_request(:get, link).to_return(status: 200)

        account = Fabricate(:account)
        status_1 = subject.call(account, text: "Hello #{link}")

        expect(status_1.text).to eq("Hello #{link}")
      end
    end
  end
end
