# frozen_string_literal: true

class REST::InstanceSerializer < ActiveModel::Serializer
  include RoutingHelper

  attributes :uri, :title, :short_description, :description, :email,
             :version, :urls, :thumbnail, :languages, :registrations,
             :approval_required, :invites_enabled, :configuration,
             :feature_quote, :rules

  def uri
    Rails.configuration.x.local_domain
  end

  def title
    Setting.site_title
  end

  def short_description
    Setting.site_short_description
  end

  def description
    Setting.site_description
  end

  def email
    Setting.site_contact_email
  end

  def version
    is_staging = ActiveModel::Type::Boolean.new.cast(ENV['IS_STAGING'])
    "#{Mastodon::Version} (compatible; TruthSocial 1.0.0#{is_staging ? '+unreleased' : ''})"
  end

  def thumbnail
    instance_presenter.thumbnail ? full_asset_url(instance_presenter.thumbnail.file.url) : full_pack_url('media/images/preview.jpg')
  end

  def urls
    { streaming_api: Rails.configuration.x.streaming_api_base_url }
  end

  def configuration
    ads_configuration = JSON.parse(ENV.fetch('ADS_CONFIGURATION', '[{}]'))

    {
      statuses: {
        max_characters: StatusLengthValidator::MAX_CHARS,
        max_media_attachments: 4,
        characters_reserved_per_url: URLPlaceholder::LENGTH,
      },

      chats: {
        max_characters: ChatMessage::MAX_CHARS,
        max_messages_per_minute: ChatMessage::MAX_MESSAGES_PER_MIN,
        max_media_attachments: ENV.fetch('MAX_ATTACHMENTS_ALLOWED_PER_MESSAGE', 4).to_i,
      },

      media_attachments: {
        supported_mime_types: MediaAttachment::IMAGE_MIME_TYPES + MediaAttachment::VIDEO_MIME_TYPES,
        image_size_limit: MediaAttachment::IMAGE_LIMIT,
        image_matrix_limit: Attachmentable::MAX_MATRIX_LIMIT,
        video_size_limit: MediaAttachment::VIDEO_LIMIT,
        video_frame_rate_limit: MediaAttachment::MAX_VIDEO_FRAME_RATE,
        video_matrix_limit: MediaAttachment::MAX_VIDEO_MATRIX_LIMIT,
        video_duration_limit: MediaAttachment::MAX_VIDEO_DURATION_LIMIT,
      },

      polls: {
        max_options: PollValidator::MAX_OPTIONS,
        max_characters_per_option: PollValidator::MAX_OPTION_CHARS,
        min_expiration: PollValidator::MIN_EXPIRATION,
        max_expiration: PollValidator::MAX_EXPIRATION,
      },

      ads: {
        algorithm: {
          name: ads_configuration[0]&.[]('value'),
          configuration: {
            frequency: ads_configuration[1]&.[]('value').to_i,
            phase_min: ads_configuration[2]&.[]('value').to_f,
            phase_max: ads_configuration[3]&.[]('value').to_f,
          },
        },
      },
      groups: {
        max_characters_name: ENV.fetch('MAX_GROUP_NAME_CHARS', 35).to_i,
        max_characters_description: ENV.fetch('MAX_GROUP_NOTE_CHARS', 160).to_i,
        max_admins_allowed: ENV.fetch('MAX_GROUP_ADMINS_ALLOWED', 10).to_i,
      },
    }
  end

  def languages
    [I18n.default_locale]
  end

  def registrations
    Setting.registrations_mode != 'none' && !Rails.configuration.x.single_user_mode
  end

  def approval_required
    Setting.registrations_mode == 'approved'
  end

  def invites_enabled
    Setting.min_invite_role == 'user'
  end

  def feature_quote
    true
  end

  def rules
    ActiveModelSerializers::SerializableResource.new(Rule.ordered, each_serializer: REST::RuleSerializer).as_json
  end

  private

  def instance_presenter
    @instance_presenter ||= InstancePresenter.new
  end
end
