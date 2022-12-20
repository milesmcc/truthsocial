# frozen_string_literal: true

class Settings::ProfilesController < Settings::BaseController
  before_action :set_account, :set_features

  # TODO: profile feature toggle
  SHOWN_FEATURES = {
    'locked' => false, # overridden in the model, safe to hide
    'bot_account' => false, # actor_type defaults to null, safe to hide
    'metadata' => false, # must be set by a user so we can safely hide this.
    'verification' => false, # must be set by the user, safe to hide
    'move_to' => false, # safe to hide
    'move_from' => false, # safe to hide
    'delete' => false, # safe to hide
  }

  def show
    @account.build_fields
  end

  def update
    if UpdateAccountService.new.call(@account, account_params)
      ActivityPub::UpdateDistributionWorker.perform_async(@account.id)
      redirect_to settings_profile_path, notice: I18n.t('generic.changes_saved_msg')
    else
      @account.build_fields
      render :show
    end
  end

  private

  def account_params
    params.require(:account).permit(:display_name, :location, :website, :note, :avatar, :header, :locked, :bot, :discoverable, fields_attributes: [:name, :value])
  end

  def set_account
    @account = current_account
  end

  def set_features
    @features = SHOWN_FEATURES
  end
end
