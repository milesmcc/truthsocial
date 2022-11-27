# frozen_string_literal: true

module AccountControllerConcern
  extend ActiveSupport::Concern

  include AccountOwnedConcern

  FOLLOW_PER_PAGE = 12

  included do
    layout 'public'

    before_action :set_instance_presenter
    before_action :set_link_headers, if: -> { request.format.nil? || request.format == :html }
  end

  private

  def set_instance_presenter
    @instance_presenter = InstancePresenter.new
  end

  def set_link_headers
    response.headers['Link'] = LinkHeader.new(
      [
        actor_url_link,
      ]
    )
  end


  def actor_url_link
    [
      ActivityPub::TagManager.instance.uri_for(@account),
      [%w(rel alternate), %w(type application/activity+json)],
    ]
  end

end
