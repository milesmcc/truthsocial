require 'rails_helper'

RSpec.describe AccountsHelper, type: :helper do
  def set_not_embedded_view
    params[:controller] = "not_#{StatusesHelper::EMBEDDED_CONTROLLER}"
    params[:action] = "not_#{StatusesHelper::EMBEDDED_ACTION}"
  end

  def set_embedded_view
    params[:controller] = StatusesHelper::EMBEDDED_CONTROLLER
    params[:action] = StatusesHelper::EMBEDDED_ACTION
  end

  describe '#display_name' do
    it 'uses the display name when it exists' do
      account = Account.new(display_name: "Display", username: "Username")

      expect(helper.display_name(account)).to eq "Display"
    end

    it 'uses the username when display name is nil' do
      account = Account.new(display_name: nil, username: "Username")

      expect(helper.display_name(account)).to eq "Username"
    end
  end

  describe '#acct' do
    it 'is fully qualified for embedded local accounts' do
      allow(Rails.configuration.x).to receive(:local_domain).and_return('local_domain')
      set_embedded_view
      account = Account.new(domain: nil, username: 'user')

      acct = helper.acct(account)

      expect(acct).to eq '@user'
    end

    it 'is fully qualified for non embedded local accounts' do
      allow(Rails.configuration.x).to receive(:local_domain).and_return('local_domain')
      set_not_embedded_view
      account = Account.new(domain: nil, username: 'user')

      acct = helper.acct(account)

      expect(acct).to eq '@user'
    end
  end
end
