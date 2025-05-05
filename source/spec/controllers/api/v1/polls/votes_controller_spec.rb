require 'rails_helper'

RSpec.describe Api::V1::Polls::VotesController, type: :controller do
  render_views

  let(:user)   { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:scopes) { 'write:statuses' }
  let(:token)  { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }

  before { allow(controller).to receive(:doorkeeper_token) { token } }

  describe 'POST #create' do
    let(:poll) { Fabricate(:poll) }

    before do
      post :create, params: { poll_id: poll.id, choices: [poll.options.last.option_number.to_s] }
    end

    it 'returns http success' do
      expect(response).to have_http_status(200)
    end

    it 'creates a vote' do
      vote = PollVote.where(poll_id: poll.id, account: user.account).first

      expect(vote).to_not be_nil
      expect(vote.option_number).to eq 1
    end

    it 'updates the stats' do
      Procedure.process_poll_option_statistics_queue
      expect(StatisticPollOption.where(poll_id: poll.id, option_number: 0).first).to eq nil
      expect(StatisticPollOption.where(poll_id: poll.id, option_number: 1).first.votes).to eq 1

      expect(StatisticPoll.where(poll_id: poll.id).first.votes).to eq 1
      expect(StatisticPoll.where(poll_id: poll.id).first.voters).to eq 1
    end
  end
end
