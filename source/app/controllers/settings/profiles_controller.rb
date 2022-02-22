# frozen_string_literal: true

class Settings::ProfilesController < Settings::BaseController
  before_action :set_account, :set_features

  SHOWN_FEATURES = {
    'locked' => false,
    'bot_account' => false,
    'metadata' => false,
    'verification' => false,
    'move_to' => false,
    'move_from' => false,
    'delete' => false,
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
