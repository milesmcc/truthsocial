# frozen_string_literal: true

module Settings
  module Exports
    class UserInvitesController < BaseController
      include ExportControllerConcern

      before_action :require_staff!

      def index
        @result = @export.to_user_invites_csv
        redirect_to '/settings/export'
      end
    end
  end
end
