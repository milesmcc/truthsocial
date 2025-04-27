# frozen_string_literal: true

class REST::V2::Status::MentionSerializer < Panko::Serializer
  attributes :id, :username, :url, :acct

  def id
    object.account_id.to_s
  end

  def username
    object.account_username
  end

  def url
    ActivityPub::TagManager.instance.url_for(object.account)
  end

  def acct
    object.account.pretty_acct
  end
end
