require 'rails_helper'

RSpec.describe MuteService, type: :service do
  before do
    account.follow!(followed)
    Redis.current.zincrby("interactions:#{account.id}", 10, bob.id)
    Redis.current.zincrby("interactions:#{account.id}", 10, target_account.id)
    Redis.current.zincrby("followers_interactions:#{account.id}:#{current_week}", 10, followed.id)
  end

  subject do
    -> { described_class.new.call(account, target_account) }
  end

  let(:account) { Fabricate(:account) }
  let(:target_account) { Fabricate(:account) }
  let(:bob) { Fabricate(:user, email: 'bob@example.com', account: Fabricate(:account, username: 'bob')).account }
  let(:followed) { Fabricate(:user, email: 'followed@example.com', account: Fabricate(:account, username: 'followed')).account }
  let(:current_week) { Time.now.strftime('%U').to_i }

  describe 'home timeline' do
    let(:status) { Fabricate(:status, account: target_account) }
    let(:other_account_status) { Fabricate(:status) }
    let(:home_timeline_key) { FeedManager.instance.key(:home, account.id) }

    before do
      allow_any_instance_of(Redisable).to receive(:redis_timelines).and_return(Redis.current)
      Redis.current.del(home_timeline_key)
    end

    it "clears account's statuses" do
      FeedManager.instance.push_to_home(account, status)
      FeedManager.instance.push_to_home(account, other_account_status)

      is_expected.to change {
        Redis.current.zrange(home_timeline_key, 0, -1)
      }.from([status.id.to_s, other_account_status.id.to_s]).to([other_account_status.id.to_s])
    end
  end

  it 'mutes account' do
    is_expected.to change {
      account.muting?(target_account)
    }.from(false).to(true)
  end

  context 'without specifying a notifications parameter' do
    it 'mutes notifications from the account' do
      is_expected.to change {
        account.muting_notifications?(target_account)
      }.from(false).to(true)
    end
  end

  context 'with a true notifications parameter' do
    subject do
      -> { described_class.new.call(account, target_account, notifications: true) }
    end

    it 'mutes notifications from the account' do
      is_expected.to change {
        account.muting_notifications?(target_account)
      }.from(false).to(true)
    end
  end

  context 'with a false notifications parameter' do
    subject do
      -> { described_class.new.call(account, target_account, notifications: false) }
    end

    it 'does not mute notifications from the account' do
      is_expected.to_not change {
        account.muting_notifications?(target_account)
      }.from(false)
    end
  end

  context 'interactions score for not-followed account' do
    subject do
      -> { described_class.new.call(account, target_account) }
    end

    it 'removes interactions record' do
      is_expected.to change {
        Redis.current.zrange("interactions:#{account.id}", 0, -1)
      }.from([bob.id.to_s, target_account.id.to_s]).to([bob.id.to_s])
    end
  end

  context 'interactions score for followed account' do
    subject do
      -> { described_class.new.call(account, followed, notifications: false) }
    end

    it 'removes followers interactions record' do
      is_expected.to change {
        Redis.current.zrange("followers_interactions:#{account.id}:#{current_week}", 0, -1)
      }.from([followed.id.to_s]).to([])
    end
  end
end
