# frozen_string_literal: true

class Api::V1::VerifySms::CountriesController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read }, only: [:index]
  before_action :require_user!

  def index
    codes = Country.sms_countries.pluck(:code)
    render json: { codes: codes }, status: 200
  end
end
