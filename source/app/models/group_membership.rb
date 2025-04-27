# == Schema Information
#
# Table name: group_memberships
#
#  id         :bigint(8)        not null, primary key
#  account_id :bigint(8)        not null
#  group_id   :bigint(8)        not null
#  role       :enum             default("user"), not null
#  created_at :datetime         not null
#  notify     :boolean          default(FALSE), not null
#
class GroupMembership < ApplicationRecord
  include Paginable
  include GroupRelationshipCacheable

  belongs_to :group
  belongs_to :account

  enum role: {
    user:      'user',
    admin:     'admin',
    owner:     'owner',
  }, _suffix: :role

  validates_with MaxGroupAdminValidator, on: [:create, :update]

  scope :recent, -> { reorder(id: :desc) }
  scope :default_memberships, (lambda do
    joins(:account)
    .merge(Account.without_suspended
                  .includes(:account_follower, :account_following, :account_status)
                  .references(:account_follower, :account_following, :account_status))
      .order(
        Arel.sql(
          "case role
           when 'owner' then 1
           when 'admin' then 2
           when 'user' then 3
           end"
        )
      ).where(role: %w(owner admin user))
  end)
  scope :search, ->(query) { joins(:account).where('display_name ilike :search OR username ilike :search', search: "%#{sanitize_sql_like(query.to_s)}%") }

  after_create :increment_cache_counters
  after_destroy :decrement_cache_counters

  def local?
    false # Force uri_for to use uri attribute
  end

  class << self
    def paginate_by_limit_offset(limit, params)
      query = order(arel_table[:id].desc).limit(limit)
      query = query.offset(params[:offset]) if params[:offset].present?
      query
    end
  end

  private

  def increment_cache_counters
    group&.increment_count!(:members_count)
  end

  def decrement_cache_counters
    group&.decrement_count!(:members_count)
  end
end
