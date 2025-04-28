# frozen_string_literal: true

class Api::V1::InstancesController < Api::BaseController
  skip_before_action :set_cache_headers
  skip_before_action :require_authenticated_user!

  def show
    expires_in 3.minutes, public: true
    render_with_cache json: {}, serializer: REST::InstanceSerializer, root: 'instance'
  end
end
