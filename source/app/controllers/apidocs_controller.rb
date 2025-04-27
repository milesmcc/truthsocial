class ApidocsController < Api::BaseController
  include Swagger::Blocks

  skip_before_action :require_authenticated_user!
  before_action :reject_unless_visible

  swagger_root do
    key :swagger, '2.0'
    info do
      key :title, 'Truth Social API'
    end
    security_definition :api_key do
      key :type, :apiKey
      key :name, :Authorization
      key :in, :header
    end
    tag do
      key :name, 'Chats'
      key :name, 'Policy'
      key :name, 'Admin'
      key :name, 'Ads'
      key :name, 'Accounts'
      key :name, 'Reports'
      key :name, 'App Attest'
      key :name, 'App Integrity'
      key :name, 'OAuth Tokens'
      key :name, 'Groups'
      key :name, 'Statuses'
      key :name, 'Tags'
      key :name, 'Instance'
      key :name, 'Notifications'
      key :name, 'Feeds'
      key :name, 'Carousels'
      key :name, 'Tv'
      key :name, 'Password'
      key :name, 'Recommendations'
      key :name, 'Push Notifications'
      key :name, 'Verify SMS'
    end
    key :consumes, ['application/json']
    key :produces, ['application/json']
  end

  SWAGGERED_CLASSES = [
    self,
    Documentation::Models::Avatar,
    Documentation::Models::Chat,
    Documentation::Models::ChatMessage,
    Documentation::Models::ChatMessageReaction,
    Documentation::Models::ChatSearchResult,
    Documentation::Models::MediaAttachment,
    Documentation::Models::ChatEvent,
    Documentation::Models::ChatSearchPreview,
    Documentation::Models::Report,
    Documentation::Models::Policy,
    Documentation::Models::Account,
    Documentation::Models::WebauthnCredential,
    Documentation::Models::Receipt,
    Documentation::Models::OneTimeChallenge,
    Documentation::Models::OauthToken,
    Documentation::Models::Group,
    Documentation::Models::GroupMembership,
    Documentation::Models::GroupRelationship,
    Documentation::Models::GroupSuggestion,
    Documentation::Models::Status,
    Documentation::Models::Poll,
    Documentation::Models::Tag,
    Documentation::Models::TagSearch,
    Documentation::Models::GroupTag,
    Documentation::Models::Instance,
    Documentation::Models::Tombstone,
    Documentation::Models::Notification,
    Documentation::Models::Feed,
    Documentation::Models::GroupCarousel,
    Documentation::Models::AccountCredential,
    Documentation::Models::Tv,
    Documentation::Models::TvChannelGuide,
    Documentation::Models::TvCarousel,
    Documentation::Models::Error,
    Documentation::Models::CountryCode,
    Documentation::Controllers::AdminGroupsStatusesController,
    Documentation::Controllers::ChatsController,
    Documentation::Controllers::ChatMessagesController,
    Documentation::Controllers::ReactionsController,
    Documentation::Controllers::ChatSilencesController,
    Documentation::Controllers::ChatSearchController,
    Documentation::Controllers::ChatEventsController,
    Documentation::Controllers::AccountCredentialsController,
    Documentation::Controllers::ReportsController,
    Documentation::Controllers::PoliciesController,
    Documentation::Controllers::InteractiveAdsController,
    Documentation::Controllers::WebauthnCredentialsController,
    Documentation::Controllers::GroupsController,
    Documentation::Controllers::StatusesController,
    Documentation::Controllers::ReblogsController,
    Documentation::Controllers::StatusesControllerV2,
    Documentation::Controllers::IosDeviceCheck::ChallengeController,
    Documentation::Controllers::IosDeviceCheck::AttestController,
    Documentation::Controllers::IosDeviceCheck::AssertController,
    Documentation::Controllers::IosDeviceCheck::RateLimitController,
    Documentation::Controllers::OauthTokensController,
    Documentation::Controllers::TagsController,
    Documentation::Controllers::InstancesController,
    Documentation::Controllers::AdminTagsController,
    Documentation::Controllers::NotificationsController,
    Documentation::Controllers::MutesController,
    Documentation::Controllers::FeedsController,
    Documentation::Controllers::Carousels::GroupsController,
    Documentation::Controllers::AdminAccountsController,
    Documentation::Controllers::AndroidDeviceCheck::ChallengeController,
    Documentation::Controllers::AndroidDeviceCheck::IntegrityController,
    Documentation::Controllers::RegistrationsController,
    Documentation::Controllers::FavouritesController,
    Documentation::Controllers::Tv::ChannelsController,
    Documentation::Controllers::PasswordsController,
    Documentation::Controllers::Recommendations::SuppressionsController,
    Documentation::Controllers::PushNotifications::AnalyticsController,
    Documentation::Controllers::CountriesController,
  ].freeze

  def index
    render json: Swagger::Blocks.build_root_json(SWAGGERED_CLASSES)
  end

  def reject_unless_visible
    raise Mastodon::NotPermittedError unless ActiveModel::Type::Boolean.new.cast(ENV['API_DOCS_VISIBLE'])
  end
end
