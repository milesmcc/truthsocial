# frozen_string_literal: true

class Api::V1::Tv::ProgrammeGuidesController < Api::BaseController
  skip_before_action :require_authenticated_user!
  WHITELISTED_CHANNELS = %w(oan newsmax rav wn)

  def show
    channel_name = WHITELISTED_CHANNELS.find { |ch| ch == params[:name] }
    not_found and return unless channel_name

    begin
      service_name = "PTv::ProgrammeGuides::#{channel_name.capitalize}Service".constantize
      epg = service_name.new.call
    rescue
      render xml: {}.to_xml(root: 'tv')
      return
    end

    render xml: epg.to_xml
  end
end
