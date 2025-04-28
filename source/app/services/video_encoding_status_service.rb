# frozen_string_literal: true

class VideoEncodingStatusService < BaseService
  include LinksParserConcern
  include UploadVideoConcern

  def call(status_id, video_id, url = nil, attempts = 0)
    @url = url || parse_urls
    @status_id = status_id
    @video_id = video_id
    @url = url
    @attempts = attempts

    return if @url.nil? || video_id.nil? || status_id.nil?

    if video_encoded?
      video_status(:complete)
    elsif give_up?
      video_status(:failed)
    else
      try_again
    end

  rescue HTTP::Error, OpenSSL::SSL::SSLError, Addressable::URI::InvalidURIError, Mastodon::HostValidationError, Mastodon::LengthValidationError => e
    Rails.logger.info "Error Checking to see if video is encoded #{@video_id}: #{e}"
    try_again
    nil
  end

  def give_up?
    @attempts >= 690 # stop polling after 24 hours
  end

  def try_again
    @attempts += 1
    video_status(:in_progress) if @attempts == 20 # distribute raw video at this point
    VideoPollingWorker.perform_in(delay, @status_id, @video_id, @url, @attempts)
  end

  def delay
    case @attempts
    when 0..20 # less than 10 minutes
      30.seconds
    when 21..47 # between 10 minutes and 30 minutes
      45.seconds
    when 48..78 # between 30 minutes and 60 minutes
      60.seconds
    else
      120.seconds
    end
  end

  def video_status(enum_value)
    status = Status.find(@status_id)
    media = status.media_attachments.select(&:video?).first
    media.processing = enum_value
    media.save
  end

end
