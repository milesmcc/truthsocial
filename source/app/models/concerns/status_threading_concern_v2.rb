# frozen_string_literal: true

module StatusThreadingConcernV2
  extend ActiveSupport::Concern
  include Redisable
  include LinksParserConcern

  def ancestors_v2(limit, account = nil, offset = 0)
    StatusRepliesV2.new(self).ancestors_v2(limit, account, offset)
  end

  def descendants_v2(limit, account = nil, offset = 0, sort = :trending)
    StatusRepliesV2.new(self).descendants_v2(limit, account, offset, sort)
  end

end