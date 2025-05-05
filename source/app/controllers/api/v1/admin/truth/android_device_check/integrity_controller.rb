# frozen_string_literal: true

class Api::V1::Admin::Truth::AndroidDeviceCheck::IntegrityController < Api::BaseController
  before_action -> { doorkeeper_authorize! :'admin:write' }
  before_action :require_staff!
  before_action :require_assertion_header!
  before_action :set_registration

  include Assertable

  def create; end

  private

  def require_assertion_header!
    raise Mastodon::UnprocessableAssertion, 'Integrity Error: Missing assertion header' if request.headers['x-tru-assertion'].blank?
  end

  def set_registration
    @registration = Registration.find_by!(token: params[:token])
  end

  def validate_client
    true
  end

  def asserting?
    true
  end

  def handle_assertion_errors?
    true
  end
end
