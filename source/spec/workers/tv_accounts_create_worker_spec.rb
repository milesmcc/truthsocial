# frozen_string_literal: true

require 'rails_helper'

describe TvAccountsCreateWorker do
  subject { described_class.new }

  let(:us) { Country.find_by!(name: 'United States') }
  let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'user'), country: us) }
  let(:scopes) { 'read:accounts' }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }

  describe 'perform' do
    context 'when there is a TV account created and p_profile_id exists' do
      before do
        Fabricate(:tv_account, account: user.account)
      end

      it 'doesnt do anything' do
        result = subject.perform(user.account.id, token.id)
        expect(result).to be_nil
        expect(a_request(:post, %r{\Ahttps://api.vstream.truthsocial.com/.+/provider/subscribers/add\z})).not_to have_been_made
        expect(a_request(:post, %r{\Ahttps://vstream.truthsocial.com/.+/client/login\z})).not_to have_been_made
        expect(a_request(:post, %r{\Ahttps://vstream.truthsocial.com/.+/client/profiles/list\z})).not_to have_been_made
      end
    end

    context 'when there isnt a TV account created' do
      context 'when all api requests are successful' do
        before do
          allow(TvAccountsCreateWorker).to receive(:perform_async)
          stub_request(:post, %r{\Ahttps://api.vstream.truthsocial.com/.+/provider/subscribers/add\z}).to_return(status: 200)
          stub_request(:post, %r{\Ahttps://vstream.truthsocial.com/.+/client/login\z}).to_return(status: 200, body: { key: 123 }.to_json)
          stub_request(:post, %r{\Ahttps://vstream.truthsocial.com/.+/client/profiles/list\z}).to_return(status: 200, body: { profiles: [guid: 456] }.to_json)
          subject.perform(user.account.id, token.id)
        end

        it 'it creates a TV account record' do
          tv_account = TvAccount.first
          expect(TvAccount.count).to eq(1)
          expect(tv_account.account_id).to eq(user.account.id)
          expect(tv_account.account_uuid).not_to be_nil
          expect(tv_account.p_profile_id).to eq(456)
        end

        it 'it creates a TV device session record' do
          tv_device_session = TvDeviceSession.first
          expect(TvDeviceSession.count).to eq(1)
          expect(tv_device_session.oauth_access_token_id).to eq(token.id)
          expect(tv_device_session.tv_session_id).not_to be_nil
        end
      end

      context 'when the api request for account creation fails' do
        before do
          stub_request(:post, %r{\Ahttps://api.vstream.truthsocial.com/.+/provider/subscribers/add\z}).to_return(status: 500)
        end

        it 'it throws a SignUpError exception' do
          expect { subject.perform(user.account.id, token.id) }.to raise_error Tv::SignUpError
        end

        it 'doesnt create a TV account and TV session records' do
          expect { subject.perform(user.account.id, token.id) }.to raise_error Tv::SignUpError
          expect(TvAccount.count).to eq(0)
          expect(TvDeviceSession.count).to eq(0)
        end
      end

      context 'when the api request for login fails' do
        before do
          stub_request(:post, %r{\Ahttps://api.vstream.truthsocial.com/.+/provider/subscribers/add\z}).to_return(status: 200)
          stub_request(:post, %r{\Ahttps://vstream.truthsocial.com/.+/client/login\z}).to_return(status: 500, body: { error: 'error' }.to_json)
        end

        it 'it throws a LoginError exception' do
          expect { subject.perform(user.account.id, token.id) }.to raise_error Tv::LoginError
        end

        it 'it creates a TV account record with profile_id as null' do
          expect { subject.perform(user.account.id, token.id) }.to raise_error Tv::LoginError
          tv_account = TvAccount.first
          expect(TvAccount.count).to eq(1)
          expect(tv_account.account_id).to eq(user.account.id)
          expect(tv_account.account_uuid).not_to be_nil
          expect(tv_account.p_profile_id).to be_nil
        end

        it 'doesnt create a TV session record' do
          expect { subject.perform(user.account.id, token.id) }.to raise_error Tv::LoginError
        end
      end

      context 'when the api request for getting profiles fails' do
        before do
          stub_request(:post, %r{\Ahttps://api.vstream.truthsocial.com/.+/provider/subscribers/add\z}).to_return(status: 200)
          stub_request(:post, %r{\Ahttps://vstream.truthsocial.com/.+/client/login\z}).to_return(status: 200, body: { key: 123 }.to_json)
          stub_request(:post, %r{\Ahttps://vstream.truthsocial.com/.+/client/profiles/list\z}).to_return(status: 500, body: { error: 'error' }.to_json)
        end

        it 'it throws a GetProfilesError exception' do
          expect { subject.perform(user.account.id, token.id) }.to raise_error Tv::GetProfilesError
        end

        it 'it creates a TV account record with profile_id as null' do
          expect { subject.perform(user.account.id, token.id) }.to raise_error Tv::GetProfilesError
          tv_account = TvAccount.first
          expect(TvAccount.count).to eq(1)
          expect(tv_account.account_id).to eq(user.account.id)
          expect(tv_account.account_uuid).not_to be_nil
          expect(tv_account.p_profile_id).to be_nil
        end

        it 'creates a TV session record' do
          expect { subject.perform(user.account.id, token.id) }.to raise_error Tv::GetProfilesError
          tv_device_session = TvDeviceSession.first
          expect(TvDeviceSession.count).to eq(1)
          expect(tv_device_session.oauth_access_token_id).to eq(token.id)
          expect(tv_device_session.tv_session_id).not_to be_nil
        end
      end
    end

    context 'when there is a TV account created with profile_id as null' do
      before do
        stub_request(:post, %r{\Ahttps://vstream.truthsocial.com/.+/client/login\z}).to_return(status: 200, body: { key: 123 }.to_json)
        stub_request(:post, %r{\Ahttps://vstream.truthsocial.com/.+/client/profiles/list\z}).to_return(status: 200, body: { profiles: [guid: 789] }.to_json)

        Fabricate(:tv_account, account: user.account, p_profile_id: nil)
        subject.perform(user.account.id, token.id)
      end
      it 'doesnt try to create the account again' do
        expect(a_request(:post, %r{\Ahttps://api.vstream.truthsocial.com/.+/provider/subscribers/add\z})).not_to have_been_made
      end

      it 'tries to login and get the profile again ' do
        expect(a_request(:post, %r{\Ahttps://vstream.truthsocial.com/.+/client/login\z})).to have_been_made
        expect(a_request(:post, %r{\Ahttps://vstream.truthsocial.com/.+/client/profiles/list\z})).to have_been_made
      end

      it 'updates the p_profile_id' do
        tv_account = TvAccount.first
        expect(TvAccount.count).to eq(1)
        expect(tv_account.account_id).to eq(user.account.id)
        expect(tv_account.account_uuid).not_to be_nil
        expect(tv_account.p_profile_id).to eq(789)
      end
    end
  end
end
