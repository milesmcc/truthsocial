require 'rails_helper'

RSpec.describe InteractiveAdsService, type: :service do
  describe "#call" do
    let(:user) { Fabricate(:user, role: 'user', sms: '234-555-2344', account: Fabricate(:account, username: 'bob')) }
    let(:ad_id) { SecureRandom.uuid }
    let(:title) { "Ad" }
    let(:provider) { "PROVIDER" }
    let(:asset_url) { "https://test.com/test.jpg" }
    let(:click_url) { "https://test.com/c" }
    let(:impression_url) { "https://test.com/i" }
    let(:params) do
      {
        'account_id' => user.account.id.to_s,
        'title' => title,
        'provider_name' => provider,
        'asset_url' => asset_url,
        'click_url' => click_url,
        'impression_url' => impression_url,
        'ad_id' => ad_id
      }
    end

    subject { described_class.new(params: params) }

    before do
      allow(PreviewCard).to receive(:create!).with({ad:true, title: title, provider_name: provider, image_remote_url: asset_url, url: click_url }).and_return(Fabricate(:preview_card))
    end

    it "should create an empty status with a preview card and an ad" do
      subject.call

      new_status = Status.last
      expect(new_status.content).to be_empty
      expect(new_status.preview_card).to eq(PreviewCard.last)
      expect(Ad.last.id).to eq ad_id
      expect(Ad.last.status).to eq Status.last
      expect(Status.last.ad).to eq Ad.last
    end

    it 'should not create duplicate status if ad is created with the same id' do
      status = Status.create!(account: user.account, interactive_ad: true)
      Ad.create!(id: ad_id, organic_impression_url: impression_url, status: status)
      allow(Rails.logger).to receive(:error)

      response = subject.call

      expect(response).to eq(nil)
      expect(Rails.logger).to have_received(:error).with "Ads error: Ad of id #{ad_id} already exists"
    end

    it 'should not create duplicate status if account id is invalid' do
      status = Status.create!(account: user.account, interactive_ad: true)
      Ad.create!(id: ad_id, organic_impression_url: impression_url, status: status)
      allow(Rails.logger).to receive(:error)

      invalid_account_id = 'BAD'
      params['account_id'] = invalid_account_id
      response = described_class.new(params: params).call

      expect(response).to eq(nil)
      expect(Rails.logger).to have_received(:error).with "Ads error: Couldn't find Account with 'id'=#{invalid_account_id}"
    end
  end
end
