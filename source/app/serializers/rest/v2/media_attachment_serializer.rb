# frozen_string_literal: true

class REST::V2::MediaAttachmentSerializer < Panko::Serializer
  include RoutingHelper

  attributes :id,
             :type,
             :url,
             :preview_url,
             :external_video_id,
             :remote_url,
             :preview_remote_url,
             :text_url,
             :meta,
             :description,
             :blurhash,
             :tv

  def id
    object.id.to_s
  end

  def url
    if object.type != 'video' && object.not_processed?
      nil
    elsif object.needs_redownload?
      media_proxy_url(object.id, :original)
    else
      full_asset_url(object.file.url(:original))
    end
  end

  def remote_url
    object.remote_url.presence
  end

  def preview_url
    # TODO: replace the image and upload it to CDN
    if object.type == 'video'
      if object.thumbnail.present?
        full_asset_url(object.thumbnail.url(:original))
      else
        # Depricated: Video previews and now stored on the MediaAttachment
        # This remains for backwards compatibility.
        object.external_video_id && object.status.preview_card&.image? ? full_asset_url(object.status.preview_card.image.url(:original)) : full_asset_url('/icons/missing.png')
      end
    elsif object.needs_redownload?
      media_proxy_url(object.id, :small)
    elsif object.thumbnail.present?
      full_asset_url(object.thumbnail.url(:original))
    elsif object.file.styles.key?(:small)
      full_asset_url(object.file.url(:small))
    end
  end

  def preview_remote_url
    object.thumbnail_remote_url.presence
  end

  def text_url
    object.local? ? medium_url(object) : nil
  end

  def meta
    object.file.meta
  end

  def external_video_id
    return nil if object.not_processed?
    object.external_video_id
  end

  def tv
    REST::V2::TvProgramSerializer.new.serialize(context[:tv_program]) if context && context[:tv_program]
  end
end
