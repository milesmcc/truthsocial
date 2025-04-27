# frozen_string_literal: true

class REST::V2::Status::ThreadSerializer < REST::V2::StatusSerializer
  attributes :in_reply_to,
             :favourites_count,
             :reblogs_count,
             :replies_count

  def in_reply_to
    nil
  end

  def favourites_count
    -1
  end

  def reblogs_count
    -1
  end

  def replies_count
    -1
  end
end
