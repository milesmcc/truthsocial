# frozen_string_literal: true

require 'rails_helper'

describe TvAccountsLoginWorker do
  subject { described_class.new }

  let(:us) { Country.find_by!(name: 'United States') }
  let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'user'), country: us) }
  let(:scopes) { 'read:accounts' }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }

  describe 'perform' do
    context 'when there is a TV session created' do
      before do
        Fabricate(:tv_device_session, doorkeeper_access_token: token)
      end

      it 'doesnt do anything' do
        result = subject.perform(user.account.id, token.id)
        expect(result).to be_nil
        expect(a_request(:post, %r{\Ahttps://vstream.truthsocial.com/.+/client/login\z})).not_to have_been_made
      end
    end

    context 'when there isnt a TV account created' do
      it 'it throws a MissingAccountError exception' do
        expect { subject.perform(user.account.id, token.id) }.to raise_error Tv::MissingAccountError
      end
    end

    context 'when there isnt a TV session created' do
      context 'when the api request for login is successful' do
        before do
          stub_request(:post, %r{\Ahttps://vstream.truthsocial.com/.+/client/login\z}).to_return(status: 200, body: { key: 123 }.to_json)
          Fabricate(:tv_account, account: user.account)
        end

        it 'creates a TV session record' do
          subject.perform(user.account.id, token.id)
          tv_device_session = TvDeviceSession.first
          expect(TvDeviceSession.count).to eq(1)
          expect(tv_device_session.oauth_access_token_id).to eq(token.id)
          expect(tv_device_session.tv_session_id).not_to be_nil
        end
      end

      context 'when the api request for login fails' do
        before do
          stub_request(:post, %r{\Ahttps://vstream.truthsocial.com/.+/client/login\z}).to_return(status: 500, body: { error: 'error' }.to_json)
          Fabricate(:tv_account, account: user.account)
        end

        it 'it throws a LoginError exception' do
          expect { subject.perform(user.account.id, token.id) }.to raise_error Tv::LoginError
        end

        it 'doesnt create a TV session records' do
          expect { subject.perform(user.account.id, token.id) }.to raise_error Tv::LoginError
          expect(TvAccount.count).to eq(1)
          expect(TvDeviceSession.count).to eq(0)
        end
      end
    end
  end
end
