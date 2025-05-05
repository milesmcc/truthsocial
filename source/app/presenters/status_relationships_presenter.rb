# frozen_string_literal: true

class StatusRelationshipsPresenter
  attr_reader :reblogs_map, :favourites_map, :mutes_map, :pins_map,
              :bookmarks_map, :groups_map, :polls_map

  def initialize(statuses, current_account_id = nil, group_id = nil, **options)
    if current_account_id.nil?
      @reblogs_map    = {}
      @favourites_map = {}
      @bookmarks_map  = {}
      @groups_map     = {}
      @mutes_map      = {}
      @pins_map       = {}
      @polls_map      = {}
    else
      statuses            = statuses.compact
      status_ids          = statuses.flat_map { |s| [s.id, s.reblog_of_id] }.uniq.compact
      conversation_ids    = statuses.filter_map(&:conversation_id).uniq
      pinnable_status_ids = statuses.map(&:proper).filter_map { |s| s.id if s.account_id == current_account_id && %w(public unlisted).include?(s.visibility) }
      pinnable_group_status_ids = statuses.map(&:proper).filter_map { |s| s.id if s.group_visibility? }

      @reblogs_map     = Status.reblogs_map(status_ids, current_account_id).merge(options[:reblogs_map] || {})
      @favourites_map  = Status.favourites_map(status_ids, current_account_id).merge(options[:favourites_map] || {})
      @bookmarks_map   = {}
      @mutes_map       = Status.mutes_map(conversation_ids, current_account_id).merge(options[:mutes_map] || {})
      @group_pins_map  = Status.pins_map(pinnable_group_status_ids, current_account_id, group_id).merge(options[:pins_map] || {})
      @pins_map        = group_id ? @group_pins_map : Status.pins_map(pinnable_status_ids, current_account_id, group_id).merge(options[:pins_map] || {})
      @groups_map      = Status.groups_map(statuses)
      @polls_map       = Status.polls_map(statuses, current_account_id)
    end
  end
end
