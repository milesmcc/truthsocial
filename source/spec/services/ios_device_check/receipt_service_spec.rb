require 'rails_helper'

RSpec.describe IosDeviceCheck::ReceiptService, type: :service do
  ENV['ENGINEERING_RP_ID'] = 'APP_ID'
  ENV['APPLE_APP_ATTEST_SERVER'] = 'https://data-development.appattest.apple.com/v1/attestationData'
  let(:user) { Fabricate(:user) }
  let(:receipt) { Base64.strict_encode64("RECEIPT") }
  let(:previous_receipt) { Base64.strict_encode64("PREVIOUS_RECEIPT") }
  let(:new_receipt) { 'NEW_RECEIPT' }
  let(:public_key) { OpenSSL::PKey::EC.new("prime256v1").generate_key.public_key.to_bn.to_s(2) }
  let(:public_key2) { OpenSSL::PKey::EC.new("prime256v1").generate_key.public_key.to_bn.to_s(2) }
  let(:attest_receipt) { false }
  let(:field_values) do
    {
      2 => 'APP_ID',
      3 => public_key,
      4 => 'client_hash',
      5 => 'token',
      6 => 'RECEIPT',
      12 => Time.now.utc,
      17 => 1,
      19 => 1.day.from_now,
      21 => 3.months.from_now
    }
  end

  let(:credential) do
    WebauthnCredential.create!(user_id: user.id,
                               external_id: Base64.urlsafe_encode64(SecureRandom.random_bytes(16)),
                               public_key: Base64.strict_encode64(public_key),
                               nickname: 'NICKNAME2',
                               sign_count: 0,
                               receipt: receipt,
                               fraud_metric: 0,
                               receipt_updated_at: nil)
  end

  subject { IosDeviceCheck::ReceiptService.new(entity_id: user.id, credential_id: credential.id, attest_receipt: attest_receipt, token: 'token') }

  describe "successful receipt verifications" do
    before do
      allow(subject).to receive(:retrieve_fraud_metrics).and_return(new_receipt)
      allow(subject).to receive(:verify_and_decode).and_return([[], double('asn1')])
      allow(subject).to receive(:extract_field_values).and_return(field_values)
      allow(subject).to receive(:validate_receipt_certificates).and_return(nil)
    end

    it "should verify a new receipt" do
      subject.call

      credential.reload
      expect(credential.receipt).to eq(Base64.strict_encode64(new_receipt))
      expect(credential.fraud_metric).to eq(1)
      expect(credential.receipt_updated_at).to be_a Time
    end

    context "when receipt_type is 'ATTEST'" do
      let(:attest_receipt) { true }

      it "should verify an attestation receipt and a new receipt" do
        field_values[6] = 'ATTEST'

        subject.call

        credential.reload
        expect(credential.receipt).to eq(Base64.strict_encode64(new_receipt))
        expect(credential.fraud_metric).to eq(1)
        expect(credential.receipt_updated_at).to be_a Time
      end
    end

    context "when populated receipt_updated_at" do
      let(:creation_time) { 2.weeks.ago.utc }
      let(:credential) do
        WebauthnCredential.create!(user_id: user.id,
                                   external_id: Base64.urlsafe_encode64(SecureRandom.random_bytes(16)),
                                   public_key: Base64.strict_encode64(public_key),
                                   nickname: 'USB key',
                                   sign_count: 0,
                                   receipt: receipt,
                                   fraud_metric: 0,
                                   receipt_updated_at: creation_time)
      end

      it "should return true if refreshing receipt even though creation time is considered invalid" do
        field_values[12] = creation_time

        subject.call

        credential.reload
        expect(credential.receipt).to eq(Base64.strict_encode64(new_receipt))
        expect(credential.fraud_metric).to eq(1)
        expect(credential.receipt_updated_at).to be_a Time
      end
    end
  end

  describe "invalid receipt verification flows" do
    it 'should raise error if receipt fails validation' do
      allow(subject).to receive(:retrieve_fraud_metrics).and_return(new_receipt)
      allow(subject).to receive(:validate_receipt).and_raise(StandardError)

      expect { subject.call }.to raise_error(Mastodon::ReceiptVerificationError)
    end

    context "when receipt_type is 'ATTEST'" do
      let(:attest_receipt) { true }

      it 'should raise error if attest_receipt and if receipt fails validation' do
        allow(subject).to receive(:validate_receipt).and_raise(StandardError.new('Error'))

        expect { subject.call }.to raise_error(Mastodon::ReceiptVerificationError).with_message('Error')
      end
    end

    context "edge cases" do
      let(:previous_creation_time) { 1.hour.from_now.utc }
      let!(:previous_credential) do
        WebauthnCredential.create!(user_id: user.id,
                                   external_id: Base64.urlsafe_encode64(SecureRandom.random_bytes(16)),
                                   public_key: Base64.strict_encode64(public_key2),
                                   nickname: 'NICKNAME1',
                                   sign_count: 0,
                                   receipt: previous_receipt,
                                   fraud_metric: 0,
                                   receipt_updated_at: previous_creation_time)
      end

      before do
        allow(subject).to receive(:verify_and_decode).and_return([[], double('asn1')])
        allow(subject).to receive(:extract_field_values).and_return(field_values)
        allow(subject).to receive(:validate_receipt_certificates).and_return(nil)
      end

      context "paths outside of fraud metric validation" do
        before do
          allow(subject).to receive(:retrieve_fraud_metrics).and_return(new_receipt)
          allow(WebauthnCredential).to receive(:decode_receipt).with(encoded_receipt: previous_receipt).and_return({ creation_time: (Time.now - 1).utc })
        end

        it "should raise error if invalid app id" do
          field_values[2] = 'INVALID'
          allow(Rails.logger).to receive(:error)

          expect { subject.call }.to raise_error(Mastodon::ReceiptVerificationError)
          expect(Rails.logger).to have_received(:error).with("App attest error: Invalid app_id for user_id: #{user.id} and credential: #{credential.id}")
        end

        it "should raise error if creation time is less than the previous receipt's creation time" do
          allow(WebauthnCredential).to receive(:decode_receipt).with(encoded_receipt: previous_receipt).and_return({ creation_time: previous_creation_time })
          allow(Rails.logger).to receive(:error)

          expect { subject.call }.to raise_error(Mastodon::ReceiptVerificationError)
          expect(Rails.logger).to have_received(:error).with("App attest error: Invalid creation time: #{field_values[12]} for user_id: #{user.id} and credential: #{credential.id}, previous credential id: #{previous_credential.id}, previous receipt creation time: #{previous_creation_time}")
        end

        it "should raise error if invalid public key" do
          field_values[3] = 'INCORRECT_PUBLIC_KEY'
          allow(Rails.logger).to receive(:error)

          expect { subject.call }.to raise_error(Mastodon::ReceiptVerificationError)
          expect(Rails.logger).to have_received(:error).with("App attest error: Attested_public_key does not match credential public key for user_id: #{user.id} and credential: #{credential.id}")
        end

        it "should alarm if the fraud metric is above the fraud metric threshold" do
          risk_metric = 21
          field_values[17] = risk_metric
          allow(Rails.logger).to receive(:error)

          subject.call

          credential.reload
          expect(credential.receipt).to eq(Base64.strict_encode64(new_receipt))
          expect(credential.fraud_metric).to eq(risk_metric)
          expect(credential.receipt_updated_at).to be_a Time
          expect(Rails.logger).to have_received(:error).with("App attest error: The risk metric associated with credential: #{credential.id} and user_id: #{user.id} is above the risk metric threshold at: #{risk_metric}.")
        end
      end

      context "fraud metric retrieval verification" do
        let(:attest_receipt) { true }

        it "should raise error if API call to retrieve fraud metric fails with a non 200 status code" do
          allow(WebauthnCredential).to receive(:decode_receipt).with(encoded_receipt: previous_receipt).and_return({ creation_time: (Time.now - 1).utc })
          field_values[19] = Time.now.utc
          status = 400

          stub_request(:post, "https://data-development.appattest.apple.com/v1/attestationData").
            with(
              body: receipt,
              headers: {
                'Authorization'=>'bearer token',
                'Connection'=>'close',
                'Host'=>'data-development.appattest.apple.com',
                'User-Agent'=>'http.rb/4.4.1'
              }).
            to_return(status: status, body: "", headers: {})

          expect { subject.call }.to raise_error(Mastodon::ReceiptVerificationError).with_message "Receipt for credential: #{credential.id} failed to refresh with status code: #{status}"
        end
      end
    end
  end
end
