require 'rails_helper'

describe Scheduler::DeviceVerificationCleanupWorker do
  subject { described_class.new }

  let!(:old_ios_verification) { Fabricate(:device_verification, details: old_ios_details, created_at: 7.months.ago) }
  let!(:old_android_verification) { Fabricate(:device_verification, details: old_android_details, created_at: 7.months.ago) }
  let!(:new_ios_verification) { Fabricate(:device_verification, details: new_details) }
  let(:old_ios_details) do
    {
      assertion_errors: [],
      external_id: 'ID',
      version: 1,
      date: Time.now.to_i,
      assertion: 'ASSERTION',
      user_id: 'USER_ID'
    }
  end

  let(:old_android_details) do
    {
      verdict: "VERDICT",
      integrity_errors: [],
      date: Time.now.to_i,
      integrity_token: 'TOKEN',
      version: 2,
      device_model: 'DEVICE MODEL',
      app_licensing_verdict: 'APP_LICENSING_VERDICT',
      app_recognition_verdict: 'APP_RECOGNITION_VERDICT',
      device_recognition_verdict: [],
      client_version: 'CLIENT_VERSION',
    }
  end

  let(:new_details) do
    {
      assertion_errors: [],
      external_id: 'ID2',
      version: 1,
      date: Time.now.to_i,
      assertion: 'ASSERTION2',
      user_id: 'USER_ID2'
    }
  end
  let(:user)  { Fabricate(:user) }
  let(:scopes)  { 'read write' }
  let!(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }

  it 'removes old device verification records' do
    status = Fabricate(:status)
    verification_status = DeviceVerificationStatus.create!(verification: old_android_verification, status: status)
    token_credential = token.integrity_credentials.create!(verification: old_android_verification, user_agent: 'USER AGENT', last_verified_at: Time.now.utc)

    subject.perform

    expect { old_ios_verification.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect { old_android_verification.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect { verification_status.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect { token_credential.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect(new_ios_verification.reload).to be_persisted
  end
end
