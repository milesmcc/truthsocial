# frozen_string_literal: true

class GroupSearchService
  def initialize(query, options = {})
    @query = query
    @limit = options[:limit].to_i
    @offset = options[:offset].to_i
  end

  def call
    search_service_results.compact.uniq
  end

  private

  attr_reader :query, :limit, :offset

  def search_service_results
    return [] if limit < 1

    exact_match + search_results
  end

  def exact_match
    return [] unless offset.zero?

    return @exact_match if defined?(@exact_match)

    @exact_match = Group.where(Group.arel_table[:display_name].lower.eq query.to_s.downcase)

    if @exact_match&.first&.discarded?
      @exact_match = []
      return []
    end

    @exact_match
  end

  def search_results
    return [] if limit_for_non_exact_results.zero?

    Group.kept
         .includes(:group_stat, :tags)
         .references(:group_stat)
         .where('display_name ILIKE :search OR note ILIKE :search', search: "%#{ActiveRecord::Base.sanitize_sql_like(query)}%")
         .limit(limit)
         .offset(offset)
         .order(members_count: :desc, display_name: :asc)
  end

  def limit_for_non_exact_results
    if exact_match?
      limit - 1
    else
      limit
    end
  end

  def exact_match?
    exact_match.present?
  end
end
