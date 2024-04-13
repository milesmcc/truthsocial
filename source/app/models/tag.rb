# frozen_string_literal: true
# == Schema Information
#
# Table name: tags
#
#  id                  :bigint(8)        not null, primary key
#  name                :string           default(""), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  usable              :boolean
#  trendable           :boolean          default(TRUE), not null
#  listable            :boolean
#  reviewed_at         :datetime
#  requested_review_at :datetime
#  last_status_at      :datetime
#  max_score           :float
#  max_score_at        :datetime
#

class Tag < ApplicationRecord
  extend Queriable
  include Paginable

  has_and_belongs_to_many :statuses
  has_and_belongs_to_many :accounts

  has_many :featured_tags, dependent: :destroy, inverse_of: :tag

  HASHTAG_SEPARATORS = "_\u00B7\u200c"
  HASHTAG_NAME_RE    = "([[:word:]_][[:word:]#{HASHTAG_SEPARATORS}]*[[:alpha:]#{HASHTAG_SEPARATORS}][[:word:]#{HASHTAG_SEPARATORS}]*[[:word:]_])|([[:word:]_]*[[:alpha:]][[:word:]_]*)"
  HASHTAG_RE         = /(?:^|[^\/\)\w])#(#{HASHTAG_NAME_RE})/i

  validates :name, presence: true, format: { with: /\A(#{HASHTAG_NAME_RE})\z/i }
  validate :validate_name_change, if: -> { !new_record? && name_changed? }

  before_create :unlist_bannable_tags

  scope :reviewed, -> { where.not(reviewed_at: nil) }
  scope :unreviewed, -> { where(reviewed_at: nil) }
  scope :pending_review, -> { unreviewed.where.not(requested_review_at: nil) }
  scope :usable, -> { where(usable: [true, nil]) }
  scope :listable, -> { where(listable: [true, nil]) }
  scope :trendable, -> { where(trendable: true).where.not(max_score: nil).order(max_score: :desc, last_status_at: :desc) }
  scope :only_trendable, -> { where(trendable: true).order(max_score: :desc, last_status_at: :desc) }
  scope :recently_used, ->(account) { joins(:statuses).where(statuses: { id: account.statuses.select(:id).limit(1000) }).group(:id).order(Arel.sql('count(*) desc')) }
  scope :matches_name, ->(term) { where(arel_table[:name].lower.matches("#{sanitize_sql_like(Tag.normalize(term.downcase))}%", nil, true)) } # Search with case-sensitive to use B-tree index
  scope :search, ->(query) { where('LOWER(tags.name) LIKE :search', search: "%#{sanitize_sql_like(query&.downcase)}%") }

  update_index 'tags', :self

  def contains_prohibited_terms?
    name_downcase = name.downcase
    Status::PROHIBITED_TERMS_ON_INDEX.any? { |term| name_downcase.include? term }
  end

  def to_param
    name
  end

  def usable
    boolean_with_default('usable', true)
  end

  alias usable? usable

  def listable
    boolean_with_default('listable', true)
  end

  alias listable? listable

  def trendable
    boolean_with_default('trendable', Setting.trendable_by_default)
  end

  alias trendable? trendable

  def requires_review?
    reviewed_at.nil?
  end

  def reviewed?
    reviewed_at.present?
  end

  def requested_review?
    requested_review_at.present?
  end

  def use!(account, status: nil, at_time: Time.now.utc)
    TrendingTags.record_use!(self, account, status: status, at_time: at_time)
  end

  def trending?
    TrendingTags.trending?(self)
  end

  def history
    days = []

    1.upto(6) do |i|
      day = i.days.ago.beginning_of_day.to_i

      days << {
        day: day.to_s,
        uses: Redis.current.get("activity:tags:#{id}:#{day}") || '0',
        accounts: Redis.current.pfcount("activity:tags:#{id}:#{day}:accounts").to_s,
      }
    end

    days
  end

  class << self
    def find_or_create_by_names(name_or_names)
      Array(name_or_names).map(&method(:normalize)).uniq { |str| str.mb_chars.downcase.to_s }.map do |normalized_name|
        tag = matching_name(normalized_name).first || create(name: normalized_name)

        yield tag if block_given?

        tag
      end
    end

    # options = [in_search_query text, in_limit smallint, in_offset integer]
    def search_for(*options)
      execute_query('select mastodon_api.search_tags ($1, $2, $3)', options).to_a.first['search_tags']
    end

    def find_normalized(name)
      matching_name(name).first
    end

    def find_normalized!(name)
      find_normalized(name) || raise(ActiveRecord::RecordNotFound)
    end

    def matching_name(name_or_names)
      names = Array(name_or_names).map { |name| normalize(name.downcase) }

      if names.size == 1
        where(arel_table[:name].lower.eq(names.first))
      else
        where(arel_table[:name].lower.in(names))
      end
    end

    def normalize(str)
      str.gsub(/\A#/, '')
    end
  end

  private

  def unlist_bannable_tags
    banned_words = BannedWord.pluck(:word)
    regexp = Regexp.new(banned_words.join('|'), true)
    bannable = regexp === name

    if bannable
      self.listable = false
      self.trendable = false
    end
  end

  def validate_name_change
    errors.add(:name, I18n.t('tags.does_not_match_previous_name')) unless name_was.mb_chars.casecmp(name.mb_chars).zero?
  end
end
