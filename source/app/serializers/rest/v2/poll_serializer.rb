# frozen_string_literal: true

class REST::V2::PollSerializer < Panko::Serializer
  attributes :id,
             :expires_at,
             :expired,
             :multiple,
             :votes_count,
             :voters_count,
             :voted,
             :own_votes,
             :options,
             :emojis

  def id
    object.id.to_s
  end

  def expired
    object.expired?
  end

  def voted
    return false unless context[:current_user]

    if context && context[:optimistic_data] && context[:optimistic_data][:voted]
      context[:optimistic_data] && context[:optimistic_data][:voted]
    else
      object.voted?(context[:current_user].account)
    end
  end

  def own_votes
    return [] unless context[:current_user]

    if context && context[:optimistic_data] && context[:optimistic_data][:own_votes]
      context[:optimistic_data] && context[:optimistic_data][:own_votes]
    else
      object.own_votes(context[:current_user].account)
    end
  end

  def current_user?
    !context[:current_user].nil?
  end

  def options
    if context && context[:optimistic_data] && context[:optimistic_data][:options]
      context[:optimistic_data] && context[:optimistic_data][:options]
    else
      object.loaded_poll_options
    end
  end

  def emojis
    []
  end

  def votes_count
    if context && context[:optimistic_data] && context[:optimistic_data][:votes_count]
      context[:optimistic_data][:votes_count]
    else
      object.votes_count
    end
  end

  def voters_count
    if context && context[:optimistic_data] && context[:optimistic_data][:voters_count]
      context[:optimistic_data][:voters_count]
    else
      object.voters_count
    end
  end
end
