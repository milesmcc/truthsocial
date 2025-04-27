# frozen_string_literal: true

class PostStatusService < BaseService
  include Redisable

  MIN_SCHEDULE_OFFSET = 5.minutes.freeze

  # Post a text status update, fetch and notify remote users mentioned
  # @param [Account] account Account from which to post
  # @param [Hash] options
  # @option [String] :text Message
  # @option [Enumerable] :mentions Optional list of usernames
  # @option [Status] :thread Optional status to reply to
  # @option [Boolean] :sensitive
  # @option [String] :visibility
  # @option [Group] :group Optional group to post to, `visibility` must be set to 'group' in that case
  # @option [String] :spoiler_text
  # @option [String] :language
  # @option [String] :scheduled_at
  # @option [Hash] :poll Optional poll to attach
  # @option [Enumerable] :media_ids Optional array of media IDs to attach
  # @option [Doorkeeper::Application] :application
  # @option [String] :idempotency Optional idempotency key
  # @option [Boolean] :with_rate_limit
  # @option [String] :ip_address IP address of where the request originated
  # @return [Status]
  def call(account, options = {})
    @account                = account
    @options                = options
    @text                   = @options[:text] || ''
    @in_reply_to            = @options[:thread]
    @quote_id               = @options[:quote_id]
    @mentions               = @options[:mentions] || []
    @ip_address             = @options[:ip_address] || ''
    @group                  = @options[:group]
    @group_timeline_visible = @options[:group_timeline_visible]
    @group_visibility       = @options[:group_visibility]
    @domain                 = @options[:domain]

    @links_service = process_links_service

    return idempotency_duplicate if idempotency_given? && idempotency_duplicate?

    @media = validate_media!
    preprocess_attributes!
    preprocess_quote!

    if scheduled?
      schedule_status!
    else
      process_status!
      postprocess_status!
      bump_potential_friendship!
      publish_status_event
      export_prometheus_metric
    end

    redis.setex(idempotency_key, 3_600, @status.id) if idempotency_given?

    send_video_to_upload_worker

    @status
  end

  private

  def publish_status_event
    EventProvider::EventProvider.new('status.created', StatusCreatedEvent, @status, @ip_address).call unless @group_visibility == :members_only
  end

  def status_from_uri(uri)
    ActivityPub::TagManager.instance.uri_to_resource(uri, Status)
  end

  def quote_from_url(url)
    return nil if url.nil?

    quote = ResolveURLService.new.call(url)
    status_from_uri(quote.uri) if quote
  rescue
    nil
  end

  def preprocess_attributes!
    @sensitive    = (@options[:sensitive].nil? ? @account.user&.setting_default_sensitive : @options[:sensitive]) || @options[:spoiler_text].present?
    @text         = @options.delete(:spoiler_text) if @text.blank? && @options[:spoiler_text].present?
    @visibility   = @options[:visibility] || @account.user&.setting_default_privacy
    @visibility   = :unlisted if @visibility&.to_sym == :public && @account.silenced?
    @scheduled_at = @options[:scheduled_at]&.to_datetime
    @scheduled_at = nil if scheduled_in_the_past?

    md = @text.match(/RT:\s*\[\s*(https:\/\/.+?)\s*\]/)

    if @quote_id.nil? && md
      @quote_id = quote_from_url(md[1])&.id
      @text.sub!(/RT:\s*\[.*?\]/, '')
    end

    @text = @links_service.resolve_urls(@text)
  rescue ArgumentError
    raise ActiveRecord::RecordInvalid
  end

  def preprocess_quote!
    if @quote_id.present?
      quote = Status.find(@quote_id)
      @quote_id = quote.reblog_of_id.to_s if quote.reblog?
    end
  end

  def process_status!
    # The following transaction block is needed to wrap the UPDATEs to
    # the media attachments when the status is created
    ApplicationRecord.transaction do
      @status = @account.statuses.create!(status_attributes)
      ProcessMentionsService.new.call(@status, @mentions, @in_reply_to)
    end

    process_hashtags_service.call(@status)
    @links_service.call(@status)
  end

  def schedule_status!
    status_for_validation = @account.statuses.build(status_attributes)

    if status_for_validation.valid?
      status_for_validation.destroy

      # The following transaction block is needed to wrap the UPDATEs to
      # the media attachments when the scheduled status is created

      ApplicationRecord.transaction do
        @status = @account.scheduled_statuses.create!(scheduled_status_attributes)
      end
    else
      raise ActiveRecord::RecordInvalid
    end
  end

  def postprocess_status!
    LinkCrawlWorker.perform_async(@status.id, nil, @domain) unless @status.spoiler_text? || video_status?
    PostDistributionService.new.distribute_to_author(@status)
    # PollExpirationNotifyWorker.perform_at(@status.poll.expires_at, @status.poll.id) if @status.poll
  end

  #
  # @return [Array] Returns an empty array if there are no media_ids or if media_ids is not an Enumerable.
  # Otherwise, it returns the media attachments associated with the account that have not been assigned a status yet.
  #
  # @raise [Mastodon::ValidationError] If there are more than 4 media attachments or if a poll is present.
  # @raise [Mastodon::ValidationError] If any of the media attachments are not processed yet.
  #
  def validate_media!
    return [] if @options[:media_ids].blank? || !@options[:media_ids].is_a?(Enumerable)

    if @options[:media_ids].size > 4 || @options[:poll].present?
      raise Mastodon::ValidationError, I18n.t('media_attachments.validations.too_many')
    end

    media_ids = @options[:media_ids].map(&:to_i)
    media = @account
            .media_attachments
            .where(status_id: nil)
            .where(id: media_ids)
            .sort_by { |m| media_ids.index(m.id) }

    if media.any? { |m| !m.video? && m.not_processed? }
      raise Mastodon::ValidationError, I18n.t('media_attachments.validations.not_ready')
    end

    media
  end

  def video_upload_enabled?
    ENV['VIDEO_REMOTE_UPLOAD_ENABLED'] == 'true'
  end

  def send_video_to_upload_worker
    @media.each do |m|
      UploadVideoStatusWorker.perform_async(m.id, @status.id) if m.video?
    end
  end

  def language_from_option(str)
    ISO_639.find(str)&.alpha2
  end

  def process_hashtags_service
    ProcessHashtagsService.new
  end

  def process_links_service
    ProcessStatusLinksService.new
  end

  def scheduled?
    @scheduled_at.present?
  end

  def idempotency_key
    "idempotency:status:#{@account.id}:#{@options[:idempotency]}"
  end

  def idempotency_given?
    @options[:idempotency].present?
  end

  def idempotency_duplicate
    if scheduled?
      @account.schedule_statuses.find(@idempotency_duplicate)
    else
      @account.statuses.find(@idempotency_duplicate)
    end
  end

  def idempotency_duplicate?
    @idempotency_duplicate = redis.get(idempotency_key)
  end

  def scheduled_in_the_past?
    @scheduled_at.present? && @scheduled_at <= Time.now.utc + MIN_SCHEDULE_OFFSET
  end

  def bump_potential_friendship!
    if @status.reply? && @account.id != @status.in_reply_to_account_id
      ActivityTracker.increment('activity:interactions')
      InteractionsTracker.new(@account.id, @status.in_reply_to_account_id, :reply, @account.following?(@status.in_reply_to_account_id), @status.group).track
    elsif @status.quote? && @account.id != @status.quote.account_id
      ActivityTracker.increment('activity:interactions')
      InteractionsTracker.new(@account.id, @status.quote.account_id, :quote, @account.following?(@status.quote.account_id), @status.quote.group).track
    end
  end

  def status_attributes
    {
      text: @text,
      media_attachments: @media || [],
      thread: @in_reply_to,
      group: @group,
      group_timeline_visible: @group_timeline_visible || false,
      polls: poll_attributes,
      has_poll: @options[:poll].present?,
      sensitive: @sensitive,
      spoiler_text: @options[:spoiler_text] || '',
      visibility: @visibility,
      language: language_from_option(@options[:language]) || @account.user&.setting_default_language&.presence || LanguageDetector.instance.detect(@text, @account),
      application: @options[:application],
      rate_limit: @options[:with_rate_limit],
      quote_id: @quote_id,
    }.compact
  end

  def scheduled_status_attributes
    {
      scheduled_at: @scheduled_at,
      media_attachments: @media || [],
      params: scheduled_options,
    }
  end

  def poll_attributes
    return if @options[:poll].blank?
    @options[:poll][:options_attributes] = @options[:poll].delete(:options).map.with_index { |v, i| { option_number: i, text: v } }
    [Poll.new(@options[:poll])]
  end

  def scheduled_options
    @options.tap do |options_hash|
      options_hash[:in_reply_to_id]  = options_hash.delete(:thread)&.id
      options_hash[:group_id]        = options_hash.delete(:group)&.id
      options_hash[:application_id]  = options_hash.delete(:application)&.id
      options_hash[:scheduled_at]    = nil
      options_hash[:idempotency]     = nil
      options_hash[:with_rate_limit] = false
    end
  end

  def export_prometheus_metric
    metric_type = @in_reply_to ? :replies : :statuses
    Prometheus::ApplicationExporter.increment(metric_type)
  end

  def video_status?
    video_upload_enabled? && @media.any?(&:video?)
  end
end
