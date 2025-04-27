# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::ReportsController, type: :controller do
  render_views

  let(:account)  { Fabricate(:account, username: 'alice') }
  let(:user)  { Fabricate(:user, account: account) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:group) { Fabricate(:group, display_name: 'test group', note: 'groupy group', owner_account: account) }
  let!(:group_membership) { Fabricate(:group_membership, group: group, account: account, role: 'owner') }
  let(:group_status) { Fabricate(:status, group: group, visibility: 'group', account: account) }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'POST #create' do
    let(:scopes)  { 'write:reports' }
    let!(:status) { Fabricate(:status) }
    let!(:admin)  { Fabricate(:user, admin: true) }

    context 'normal account' do
      before do
        allow(AdminMailer).to receive(:new_report).and_return(double('email', deliver_later: nil))
        post :create, params: { status_ids: [status.id], account_id: status.account.id, comment: 'reasons' }
      end

      it 'creates a report' do
        expect(status.reload.account.targeted_reports).not_to be_empty
        expect(response).to have_http_status(200)
      end

      it 'respects rate limit' do
        399.times do
          post :create, params: { status_ids: [status.id], account_id: status.account.id, comment: 'reasons' }
        end
        post :create, params: { status_ids: [status.id], account_id: status.account.id, comment: 'reasons' }
        expect(response).to have_http_status(422)
      end

      it 'doesn`t create a duplicate report' do
        post :create, params: { status_ids: [status.id], account_id: status.account.id, comment: 'reasons' }
        expect(response).to have_http_status(422)
      end
    end

    context 'hostile account' do
      it 'subject to HostileRateLimiter' do
        user.account.update!(trust_level: Account::TRUST_LEVELS[:hostile])
        expect(user.account.trust_level).to eq(Account::TRUST_LEVELS[:hostile])
        expect(Report.where(account_id: user.account.id).count).to eq(0)

        post :create, params: { status_ids: [status.id], account_id: status.account.id, comment: 'reasons' }
        expect(response).to have_http_status(200)
        expect(Report.where(account_id: user.account_id).count).to eq(0)
      end
    end

    context 'chat messages' do
      let(:recipient) { Fabricate(:account, username: 'theirs') }
      let(:recipient_user) { Fabricate(:user, account: recipient) }

      it 'creates a report with chat messages' do
        chat = Chat.create(owner_account_id: account.id, members: [recipient.id])
        message = JSON.parse(ChatMessage.create_by_function!({
          account_id: recipient.id,
          token: nil,
          idempotency_key: nil,
          chat_id: chat.chat_id,
          content: Faker::Lorem.characters(number: 15),
          media_attachment_ids: nil
        }))

        post :create, params: { message_ids: [message['id']], account_id: account.id, comment: 'reasons' }

        reports = Report.where(account_id: account.id)
        expect(response).to have_http_status(200)
        expect(reports.count).to eq(1)

        expect(reports.last.message_ids).to eq([message['id'].to_i])
      end
    end

    context 'group statuses' do
      let(:non_member)  { Fabricate(:user, account: Fabricate(:account, username: 'non_member')) }
      let(:token) { Fabricate(:accessible_access_token, resource_owner_id: non_member.id, scopes: scopes) }

      it 'creates a report for statuses in a group' do
        post :create, params: { status_ids: [group_status.id], account_id: group_status.account.id, comment: 'reasons' }

        expect(group_status.account.targeted_reports).not_to be_empty
        expect(group_status.account.targeted_reports.first.group_id).to eq group.id
        expect(response).to have_http_status(200)
        expect(body_as_json[:id]).to be_an_instance_of String
        expect(body_as_json[:action_taken]).to be_boolean
      end

      it "should return http forbidden if it's a private group status and the user is not a member" do
        group.members_only!

        post :create, params: { status_ids: [group_status.id], account_id: group_status.account.id, comment: 'reasons' }

        expect(response).to have_http_status(403)
      end
    end

    context 'groups' do
      before do
        post :create, params: { group_id: group.id, comment: 'reasons' }
      end

      it 'reports a group' do
        expect(account.targeted_reports.first.group_id).to eq group.id
        expect(response).to have_http_status(200)
      end
    end

    context 'external ads' do
      let(:ts_advertising_account) { Fabricate(:account, username: 'ts_advertising') }

      before do
        stub_const('ENV', ENV.to_hash.merge('TS_ADVERTISTING_ACCOUNT_ID' => ts_advertising_account.id))
        post :create, params: { external_ad_url: 'https://example.com', external_ad_media_url: 'https://example.com', external_ad_description: 'Example ad' }
      end

      it 'reports an external ad' do
        expect(ts_advertising_account.targeted_reports.first.external_ad_id).to_not be_nil
        expect(response).to have_http_status(200)
      end

      it 'creates an external ad record' do
        expect(ExternalAd.last.ad_url).to eq 'https://example.com'
        expect(ExternalAd.last.media_url).to eq 'https://example.com'
        expect(ExternalAd.last.description).to eq 'Example ad'
      end
    end
  end
end
