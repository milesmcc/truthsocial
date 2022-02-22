require 'rails_helper'

RSpec.describe Api::V1::Admin::AccountsController, type: :controller do
  render_views

  let(:role)   { 'moderator' }
  let(:user)   { Fabricate(:user, role: role, sms: '234-555-2344', account: Fabricate(:account, username: 'alice')) }
  let(:scopes) { 'admin:read admin:write' }
  let(:token)  { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:account) { Fabricate(:user).account }

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

  describe 'GET #index' do
    context 'with no params' do
      before do
        get :index
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end
    end

    context 'with filter params' do
      before do
        get :index, params: { sms: '234-555-2344' }
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'

      it 'returns http success' do
        expect(body_as_json[0][:id].to_i).to eq(user.account.id)
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'GET #show' do
    before do
      get :show, params: { id: account.id }
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses'
    it_behaves_like 'forbidden for wrong role', 'user'

    it 'returns http success' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'POST #create' do
    let(:approved) { true }
    let(:verified) { false }

    context 'approved param included' do
      before do
        post(
          :create,
          params: {
            username: 'bob',
            sms: '234-555-2344',
            verified: verified,
            email: 'bob@example.com',
            password: '12345678',
            approved: 'true',
            role: 'moderator'
          }
        )
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'does not send Waitlisted email' do
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(I18n.t('notification_mailer.user_approved.web.subject'))
      end
    end

    context 'approved param not included' do
      before do
        post(
          :create,
          params: {
            username: 'bob',
            sms: '234-555-2344',
            verified: verified,
            email: 'bob@example.com',
            password: '12345678',
            role: 'moderator'
          }
        )
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'sends a Waitlisted email' do
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(I18n.t('user_mailer.waitlisted.title'))
      end
    end

    context 'confirmed param included' do
      before do
        post :create, params: { username: 'bob', sms: '234-555-2344', approved: approved, verified: verified, email: 'bob@example.com', password: '12345678', confirmed: 'true', role: 'moderator' }
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'creates a user' do
        account = Account.find_by(username: 'bob')
        expect(account).to_not be_nil
        expect(account.user).to_not be_nil
        expect(account.user.functional?).to be true
        expect(account.user.confirmed?).to be true
        expect(account.verified?).to be false
        expect(account.user.moderator).to be true
      end

      it 'saves the expected attributes on the new user' do
        account = Account.find_by(username: 'bob')
        expect(account.user.sms).to eq('234-555-2344')
        expect(account.user.email).to eq('bob@example.com')
      end

      it 'approves the new user' do
        account = Account.find_by(username: 'bob')
        expect(account.user).to be_approved
      end

      context 'when approved param is not set to true' do
        let(:approved) { 'false' }
        it 'does not approve the new user' do
          account = Account.find_by(username: 'bob')
          expect(account.user).to_not be_approved
        end
      end

      context 'when verified param is set to true' do
        let(:verified) { true }
        it 'verifies the new user' do
          account = Account.find_by(username: 'bob')
          expect(account.verified).to be true
        end
      end
    end

    context 'when confirmed param is missing' do
      before do
        post :create, params: { username: 'bob', sms: '234-555-2344', approved: approved, verified: verified, email: 'bob@example.com', password: '12345678', role: 'moderator' }
      end
      it 'does not confirm the new user' do
        account = Account.find_by(username: 'bob')
        expect(account.user.confirmed?).to be false
      end
    end
  end

  describe 'POST #approve' do
    before do
      account.user.update(approved: false)
      post :approve, params: { id: account.id }
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses'
    it_behaves_like 'forbidden for wrong role', 'user'

    it 'returns http success' do
      expect(response).to have_http_status(200)
    end

    it 'approves user' do
      expect(account.reload.user_approved?).to be true
    end
  end

  describe 'POST #bulk_approve' do
    before do
      allow(Admin::AccountBulkApprovalWorker).to receive(:perform_async)
    end

    context 'with params: { all: true }' do
      before do
        post :bulk_approve, params: { all: true }
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'

      it 'performs the worker and returns http success' do
        expect(Admin::AccountBulkApprovalWorker).to have_received(:perform_async).with({ all: true })
        expect(response).to have_http_status(204)
      end
    end

    context 'with params: { number: 42 }' do
      before do
        post :bulk_approve, params: { number: 42 }
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'

      it 'performs the worker and returns http success' do
        expect(Admin::AccountBulkApprovalWorker).to have_received(:perform_async).with({ number: 42 })
        expect(response).to have_http_status(204)
      end
    end

    context 'with no params' do
      before do
        post :bulk_approve
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'

      it 'returns a 400 and error message' do
        expect(response).to have_http_status(400)
        expect(body_as_json[:error]).to eq('You must include either a number or all param')
      end
    end
  end

  describe 'POST #reject' do
    before do
      account.user.update(approved: false)
      post :reject, params: { id: account.id }
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses'
    it_behaves_like 'forbidden for wrong role', 'user'

    it 'returns http success' do
      expect(response).to have_http_status(200)
    end

    it 'removes user' do
      expect(User.where(id: account.user.id).count).to eq 0
    end
  end

  describe 'POST #enable' do
    before do
      account.user.update(disabled: true)
      post :enable, params: { id: account.id }
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses'
    it_behaves_like 'forbidden for wrong role', 'user'

    it 'returns http success' do
      expect(response).to have_http_status(200)
    end

    it 'enables user' do
      expect(account.reload.user_disabled?).to be false
    end
  end

  describe 'POST #unsuspend' do
    before do
      account.suspend!
      post :unsuspend, params: { id: account.id }
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses'
    it_behaves_like 'forbidden for wrong role', 'user'

    it 'returns http success' do
      expect(response).to have_http_status(200)
    end

    it 'unsuspends account' do
      expect(account.reload.suspended?).to be false
    end
  end

  describe 'POST #unverify' do
    before do
      account.verify!
      post :unverify, params: { id: account.id }
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses'
    it_behaves_like 'forbidden for wrong role', 'user'

    it 'returns http success' do
      expect(response).to have_http_status(302)
    end

    it 'unsuspends account' do
      expect(account.reload.verified?).to be false
    end
  end

  describe 'POST #unsensitive' do
    before do
      account.touch(:sensitized_at)
      post :unsensitive, params: { id: account.id }
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses'
    it_behaves_like 'forbidden for wrong role', 'user'

    it 'returns http success' do
      expect(response).to have_http_status(200)
    end

    it 'unsensitives account' do
      expect(account.reload.sensitized?).to be false
    end
  end

  describe 'POST #unsilence' do
    before do
      account.touch(:silenced_at)
      post :unsilence, params: { id: account.id }
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses'
    it_behaves_like 'forbidden for wrong role', 'user'

    it 'returns http success' do
      expect(response).to have_http_status(200)
    end

    it 'unsilences account' do
      expect(account.reload.silenced?).to be false
    end
  end
end
