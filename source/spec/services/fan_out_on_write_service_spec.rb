require 'rails_helper'

RSpec.describe FanOutOnWriteService, type: :service do
  let(:tom)   { Fabricate(:account, username: 'tom') }
  let(:status)   { Fabricate(:status, text: 'Hello @alice #test', account: tom) }
  let!(:alice)    { Fabricate(:account, username: 'alice') }
  let(:bob) { Fabricate(:account, username: 'bob') }

  subject { FanOutOnWriteService.new }

  before do
    bob.follow!(tom)

    ProcessMentionsService.new.call(status, ['alice'])
    ProcessHashtagsService.new.call(status)

    subject.call(status)
  end

  def home_feed_of(account)
    HomeFeed.new(account).get(10).map(&:id)
  end

  it 'delivers status to home timeline' do
    expect(home_feed_of(tom)).to include status.id
  end

  it 'delivers status to local followers' do
    pending 'some sort of problem in test environment causes this to sometimes fail'
    expect(home_feed_of(bob)).to include status.id
  end

  it 'delivers status to hashtag' do
    expect(TagFeed.new(Tag.find_by(name: 'test'), alice).get(20).map(&:id)).to include status.id
  end

  it 'delivers status to public timeline' do
    expect(PublicFeed.new(alice).get(20).map(&:id)).to include status.id
  end
end
