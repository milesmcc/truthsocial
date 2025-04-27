# frozen_string_literal: true

require 'rails_helper'

describe ActivityPub::UpdatePollSerializer do
  let(:account) { Fabricate(:account) }
  let(:poll)    { Fabricate(:poll) }
  let!(:status) { Fabricate(:status, account: account) }

  before(:each) do
    @serialization = ActiveModelSerializers::SerializableResource.new(status, serializer: ActivityPub::UpdatePollSerializer, adapter: ActivityPub::Adapter)
  end

  subject { JSON.parse(@serialization.to_json) }

  xit 'has a Update type' do
    expect(subject['type']).to eql('Update')
  end

  xit 'has an object with Question type' do
    expect(subject['object']['type']).to eql('Question')
  end

  xit 'has the correct actor URI set' do
    expect(subject['actor']).to eql(ActivityPub::TagManager.instance.uri_for(account))
  end
end
