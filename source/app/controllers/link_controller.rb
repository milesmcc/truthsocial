# frozen_string_literal: true

class LinkController < ApplicationController
  layout 'public'

  before_action :set_body_classes

  rescue_from ActiveRecord::RecordNotFound do
    render 'link/missing', status: :not_found
  end

  def show
    @link = Link.find(link_id)
    @link_url = URI.parse(@link.url).to_s
    InspectLinkWorker.perform_if_needed(@link)

    redirect_to URI.parse(@link_url).to_s, status: 301 if @link.normal? || @link.review? || @link.whitelisted?
    #render("confirm") if @link.normal? || @link.review?
  end

  private

  def link_id
    params[:id]
  end

  def set_body_classes
    @hide_navbar = true
  end
end
