# frozen_string_literal: true

class Api::V1::Polls::VotesController < Api::BaseController
  include Authorization

  before_action -> { doorkeeper_authorize! :write, :'write:statuses' }
  before_action :require_user!
  before_action :set_poll

  def create
    VoteService.new.call(current_account, @poll, vote_params[:choices])
    update_optimistic_data
    render json: REST::V2::PollSerializer.new(context: { optimistic_data: @optimistic_data, current_user: current_user }).serialize(@poll)
  end

  private

  def set_poll
    @poll = Poll.find(params[:poll_id])
    @optimistic_data = { votes_count: @poll.votes_count.to_i, voters_count: @poll.voters_count.to_i, own_votes: @poll.own_votes(current_account), options: @poll.loaded_options }
    authorize @poll.status, :show?
  rescue Mastodon::NotPermittedError
    not_found
  end

  def update_optimistic_data
    @optimistic_data[:voters_count] += 1
    vote_params[:choices].each do |choice|
      @optimistic_data[:votes_count] += 1
      @optimistic_data[:own_votes].push(choice.to_i) unless @optimistic_data[:own_votes].include?(choice.to_i)
      @optimistic_data[:options][choice.to_i][:votes_count] += 1 if @optimistic_data[:options][choice.to_i]
    end
    @optimistic_data[:voted] = true
  end

  def vote_params
    params.permit(choices: [])
  end
end
