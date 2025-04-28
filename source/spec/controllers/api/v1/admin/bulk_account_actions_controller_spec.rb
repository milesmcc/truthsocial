require 'rails_helper'

RSpec.describe Api::V1::Admin::BulkAccountActionsController, type: :controller do

  render_views

  let(:role)   { 'moderator' }
  let(:user)   { Fabricate(:user, role: role, account: Fabricate(:account, username: 'alice')) }
  let(:scopes) { 'admin:read admin:write' }
  let(:token)  { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }

  let(:user_1)   { Fabricate(:user, account: Fabricate(:account)) }
  let(:user_2)   { Fabricate(:user, account: Fabricate(:account)) }
  let(:user_3)   { Fabricate(:user, account: Fabricate(:account)) }
  let(:user_4)   { Fabricate(:user, account: Fabricate(:account)) }
  let(:user_5)   { Fabricate(:user, account: Fabricate(:account)) }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  shared_examples 'forbidden for wrong scope' do |wrong_scope|
    let(:scopes) { wrong_scope }

    it 'returns http forbidden' do
      expect(response).to have_http_status(403)
    end
  end

  shared_examples 'forbidden for wrong role' do |wrong_role|
    let(:role) { wrong_role }

    it 'returns http forbidden' do
      expect(response).to have_http_status(403)
    end
  end

  describe 'POST #create' do
    describe 'when a type that is not implemented is passed' do
      before do
        post :create, params: { type: 'action_that_doesnt_exist' }
      end
      it 'returns http not found' do
        expect(response).to have_http_status(404)
      end
    end

    context 'type is enable_sms_reverification' do
      context 'when multiple accounts are passed'
      before do
        post :create, params: { account_ids: [user_1.account.id, user_2.account.id, user_3.account.id], type: 'enable_sms_reverification' }
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'

      it 'returns http success with the number of affected items' do
        expect(response).to have_http_status(200)
        expect(body_as_json[:items_affected]).to eq 3
      end

      it 'performs action against all passed accounts' do
        expect(UserSmsReverificationRequired.exists?(user_1.id)).to be true
        expect(UserSmsReverificationRequired.exists?(user_2.id)).to be true
        expect(UserSmsReverificationRequired.exists?(user_3.id)).to be true
        expect(UserSmsReverificationRequired.exists?(user_4.id)).to be false
        expect(UserSmsReverificationRequired.exists?(user_5.id)).to be false
      end


      it 'logs action' do
        log_item = Admin::ActionLog.last
        expect(log_item).to_not be_nil
        expect(log_item.action).to eq :enable_sms_reverification
        expect(log_item.account_id).to eq user.account_id
        expect([user_1.id, user_2.id, user_3.id]).to include(log_item.target_id)

        expect(Admin::ActionLog.count).to eq(3)
      end

      it 'ingores alredy inserted accounts and inserts only the missing ones' do 
        expect(Admin::ActionLog.count).to eq(3)

        post :create, params: { account_ids: [user_1.account.id, user_2.account.id, user_4.account.id ], type: 'enable_sms_reverification' }
        expect(response).to have_http_status(200)
        expect(body_as_json[:items_affected]).to eq 1

        expect(UserSmsReverificationRequired.exists?(user_1.id)).to be true
        expect(UserSmsReverificationRequired.exists?(user_2.id)).to be true
        expect(UserSmsReverificationRequired.exists?(user_3.id)).to be true
        expect(UserSmsReverificationRequired.exists?(user_4.id)).to be true
        expect(UserSmsReverificationRequired.exists?(user_5.id)).to be false
        expect(Admin::ActionLog.count).to eq(4)
      end
    end
  end
end
