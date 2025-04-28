require 'rails_helper'

RSpec.describe Api::V1::Pleroma::Chats::MessagesController, type: :controller do
  render_views

  let(:account) { Fabricate(:account, username: 'mine') }
  let(:second_account) { Fabricate(:account, username: 'dalv') }

  let(:recipient) { Fabricate(:account, username: 'theirs') }
  let(:user) { Fabricate(:user, account: account) }
  let(:recipient_user) { Fabricate(:user, account: recipient) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read write') }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET #index' do
    it 'returns an error if you are not in the requested chat' do
      chat = Chat.create(owner_account_id: recipient.id)
      get :index, params: { chat_id: chat.chat_id, limit: 2 }
      expect(response).to have_http_status(404)
    end

    it 'returns chat messages with pagination headers' do
      chat = Chat.create(owner_account_id: account.id, members: [recipient.id])

      10.times do
        ChatMessage.create_by_function!({
          account_id: account.id,
          token: nil,
          idempotency_key: nil,
          chat_id: chat.chat_id,
          content: Faker::Lorem.characters(number: 15),
          media_attachment_ids: nil
        })
      end

      get :index, params: { chat_id: chat.chat_id, limit: 2 }
      expect(response).to have_http_status(200)
      expect(body_as_json.length).to eq 2
      expect(response.headers['Link'].find_link(%w(rel next)).href).to include "http://test.host/api/v1/pleroma/chats/#{chat.id}/messages?limit=2&max_id="
    end

    it 'returns chat messages ordered by min ID' do
      chat = Chat.create(owner_account_id: account.id, members: [recipient.id])

      10.times do
        ChatMessage.create_by_function!({
          account_id: account.id,
          token: nil,
          idempotency_key: nil,
          chat_id: chat.chat_id,
          content: Faker::Lorem.characters(number: 15),
          media_attachment_ids: nil
        })
      end

      messages = ChatMessage.load_messages(account.id, chat.chat_id, nil, nil, nil, 3)
      parsed_messages = JSON.parse(messages)

      get :index, params: { chat_id: chat.chat_id, limit: 2, min_id: parsed_messages.first[:id] }
      expect(response.headers['Link'].find_link(['rel', 'next']).href).to include "http://test.host/api/v1/pleroma/chats/#{chat.id}/messages?limit=2&min_id=#{parsed_messages.third[:id]}"
    end
  end

  describe 'GET #show' do
    it 'returns a single chat message' do
      chat = Chat.create(owner_account_id: account.id, members: [recipient.id])
      content = Faker::Lorem.characters(number: 15)

      message = ChatMessage.create_by_function!({
        account_id: account.id,
        token: nil,
        idempotency_key: nil,
        chat_id: chat.chat_id,
        content: content,
        media_attachment_ids: nil
      })

      parsed_message = JSON.parse(message)

      get :show, params: { chat_id: chat.chat_id, id: parsed_message['id'] }
      expect(response).to have_http_status(200)
      expect(body_as_json[:account_id]).to eq account.id.to_s
      expect(body_as_json[:chat_id]).to eq chat.id.to_s
      expect(body_as_json[:content]).to eq Formatter.instance.format_chat_message(content)
      expect(body_as_json[:created_at]).to be_present
      expect(body_as_json[:id]).to eq parsed_message['id'].to_s
      expect(body_as_json[:unread]).to eq false
      expect(body_as_json[:expiration]).to eq parsed_message['expiration']
    end
  end

  describe 'POST #create' do
    let(:other_account) { Fabricate(:account, username: 'other') }

    it 'returns an error if you are not in the requested chat' do
      chat = Chat.create(owner_account_id: other_account.id, members: [recipient.id])
      post :create, params: { account_id: 1, chat_id: chat.chat_id, content: Faker::Lorem.characters(number: 15) }
      expect(response).to have_http_status(404)
    end

    it 'returns an error if you are blocked' do
      chat = Chat.create(owner_account_id: account.id, members: [recipient.id])
      recipient.block!(account)

      post :create, params: { account_id: 1, chat_id: chat.chat_id, content: Faker::Lorem.characters(number: 15) }
      expect(response).to have_http_status(422)
      expect(body_as_json[:error]).to eq('Cannot perform request due to blocked constraints')
    end

    it 'returns a 422 if content exceeds the maximum character limit' do
      chat = Chat.create(owner_account_id: account.id, members: [recipient.id])
      recipient.user = recipient_user
      message = Faker::Lorem.characters(number: 501)

      post :create, params: { account_id: account.id, chat_id: chat.chat_id, content: message }

      expect(response).to have_http_status(422)
      expect(body_as_json[:error]).to eq('Content is too long (maximum is 500 characters)')
    end

    it 'creates a new message' do
      chat = Chat.create(owner_account_id: account.id, members: [recipient.id])
      recipient.user = recipient_user
      message = Faker::Lorem.characters(number: 15)

      post :create, params: { account_id: account.id, chat_id: chat.chat_id, content: message }

      expect(body_as_json[:account_id].to_i).to eq account.id
      expect(body_as_json[:content]).to eq Formatter.instance.format_chat_message(message)
      expect(body_as_json[:unread]).to eq false
      expect(body_as_json[:chat_id]).to eq chat.chat_id.to_s
      expect(body_as_json[:created_at]).to be_an_instance_of String
      expect(body_as_json[:expiration]).to be_an_instance_of Integer
      expect(body_as_json[:message_type]).to be_an_instance_of String
      expect(body_as_json).to have_key(:emoji_reactions)
      expect(body_as_json).to have_key(:idempotency_key)
      expect(body_as_json).to have_key(:media_attachments)
      expect(Notification.count).to eq 1
    end

    it 'creates a new message with media attachments' do
      chat = Chat.create(owner_account_id: account.id, members: [recipient.id])
      recipient.user = recipient_user
      message = Faker::Lorem.characters(number: 15)
      media_attachment1 = MediaAttachment.create(account: account, file: attachment_fixture('attachment.jpg'))
      media_attachment2 = MediaAttachment.create(account: account, file: attachment_fixture('avatar.gif'))

      post :create, params: { account_id: account.id, chat_id: chat.chat_id, content: message, media_ids: [media_attachment1.id, media_attachment2.id] }

      expect(body_as_json[:account_id].to_i).to eq account.id
      expect(body_as_json[:content]).to eq Formatter.instance.format_chat_message(message)
      expect(body_as_json[:unread]).to eq false
      expect(body_as_json[:chat_id]).to eq chat.chat_id.to_s
      expect(body_as_json[:created_at]).to be_an_instance_of String
      expect(body_as_json[:expiration]).to be_an_instance_of Integer
      expect(body_as_json[:message_type]).to be_an_instance_of String
      expect(body_as_json).to have_key(:emoji_reactions)
      expect(body_as_json).to have_key(:idempotency_key)
      expect(body_as_json[:media_attachments].size).to eq 2
      first_media_attachment = body_as_json[:media_attachments].first
      expect(first_media_attachment[:id]).to eq media_attachment1.id.to_s
      expect(first_media_attachment[:url]).to be_an_instance_of String
      expect(first_media_attachment[:meta]).to be_an_instance_of Hash
      expect(first_media_attachment[:type]).to be_an_instance_of String
      expect(first_media_attachment[:blurhash]).to be_an_instance_of String
      expect(first_media_attachment[:text_url]).to be_an_instance_of String
      expect(first_media_attachment[:remote_url]).to be_an_instance_of String
      expect(first_media_attachment[:preview_url]).to be_an_instance_of String
      expect(first_media_attachment).to have_key(:description)
      expect(first_media_attachment).to have_key(:external_video_id)
      expect(first_media_attachment).to have_key(:preview_remote_url)
      expect(Notification.count).to eq 1
    end

    it 'creates a new message with media attachments with no content' do
      chat = Chat.create(owner_account_id: account.id, members: [recipient.id])
      recipient.user = recipient_user
      media_attachment1 = MediaAttachment.create(account: account, file: attachment_fixture('attachment.jpg'))

      post :create, params: { account_id: account.id, chat_id: chat.chat_id, media_ids: [media_attachment1.id] }

      expect(body_as_json[:id]).to be_an_instance_of String
      expect(body_as_json[:content]).to eq nil
      media_attachment = body_as_json[:media_attachments].first
      expect(media_attachment[:id]).to eq media_attachment1.id.to_s
      expect(Notification.count).to eq 1
    end

    it 'does not attach media from another account to the created message' do
      chat = Chat.create(owner_account_id: account.id, members: [recipient.id])
      media = Fabricate(:media_attachment, account: second_account)

      post :create, params: { account_id: account.id, chat_id: chat.chat_id, media_ids: [media.id] }

      expect(body_as_json[:media_attachments]).to eq nil
    end

    it 'does not allow attaching more than 4 files' do
      chat = Chat.create(owner_account_id: account.id, members: [recipient.id])
      media_1 = Fabricate(:media_attachment, account: account)
      media_2 = Fabricate(:media_attachment, account: account)
      media_3 = Fabricate(:media_attachment, account: account)
      media_4 = Fabricate(:media_attachment, account: account)
      media_5 = Fabricate(:media_attachment, account: account)

      post :create, params: { account_id: account.id, chat_id: chat.chat_id, media_ids: [media_1.id, media_2.id, media_3.id, media_4.id, media_5.id] }

      expect(response).to have_http_status(422)
      expect(body_as_json[:error]).to eq I18n.t('media_attachments.validations.too_many')
    end

    it 'calls UploadVideoChatWorker for video attachments' do
      allow(UploadVideoChatWorker).to receive(:perform_async)

      chat = Chat.create(owner_account_id: account.id, members: [recipient.id])
      media_1 = Fabricate(:media_attachment, type: :video, account: account)
      media_2 = Fabricate(:media_attachment, type: :image, account: account)
      media_3 = Fabricate(:media_attachment, type: :video, account: account)
      media_4 = Fabricate(:media_attachment, type: :image, account: account)

      post :create, params: { account_id: account.id, chat_id: chat.chat_id, media_ids: [media_1.id, media_2.id, media_3.id, media_4.id] }

      expect(UploadVideoChatWorker).to have_received(:perform_async).with(media_1.id)
      expect(UploadVideoChatWorker).to have_received(:perform_async).with(media_3.id)
    end

    it 'does not create a notification if recipient has them silenced' do
      chat = Chat.create(owner_account_id: account.id, members: [recipient.id])
      member = ChatMember.find([chat.id, recipient.id])
      member.update(silenced: true)
      member.save
      recipient.user = recipient_user
      message = Faker::Lorem.characters(number: 15)

      post :create, params: { account_id: account.id, chat_id: chat.id, content: message }
      expect(Notification.count).to eq 0
    end

    it 'marks recipient as active if they are currently inactive' do
      recipient.follow!(account)
      chat = Chat.create(owner_account_id: account.id, members: [recipient.id])
      member = ChatMember.find([chat.id, recipient.id])
      member.update!(active: false)

      post :create, params: { chat_id: chat.chat_id, content: Faker::Lorem.characters(number: 15) }
      member.reload
      expect(member.active).to be true
    end

    context 'link shortener' do
      it 'processes links' do
        chat = Chat.create(owner_account_id: account.id, members: [recipient.id])
        recipient.user = recipient_user
        message = 'Hello http://example.com/'
        stub_request(:get, 'http://example.com/').to_return(status: 200)

        post :create, params: { account_id: account.id, chat_id: chat.chat_id, content: message }

        expect(Link.count).to eq 1
      end

      it 'replaces urls pointing to the link shortener with their original url' do
        chat = Chat.create(owner_account_id: account.id, members: [recipient.id])
        recipient.user = recipient_user
        message = 'Hello http://example.com/'
        stub_request(:get, 'http://example.com/').to_return(status: 200)
        post :create, params: { account_id: account.id, chat_id: chat.chat_id, content: message }
        expect(Link.count).to eq 1

        message_1 = "Hello again https://links.#{Rails.configuration.x.web_domain}/link/#{Link.first.id}"
        post :create, params: { account_id: account.id, chat_id: chat.chat_id, content: message_1 }
        expect(body_as_json[:content]).to match(/http:\/\/example.com\//)
      end

      it 'does not replace urls to the link shortener with nonexistent id' do
        chat = Chat.create(owner_account_id: account.id, members: [recipient.id])
        recipient.user = recipient_user
        link = "https://links.#{Rails.configuration.x.web_domain}/link/22222"
        message = "Hello again #{link}"
        stub_request(:get, 'http://example.com/').to_return(status: 200)
        post :create, params: { account_id: account.id, chat_id: chat.chat_id, content: message }
        expect(body_as_json[:content]).to match(/#{link}/)
      end
    end

    context 'App Integrity' do
      let(:date) { (Time.now.utc.to_f * 1000).to_i }
      let(:alg_and_enc) { {alg: "A256KW", enc: "A256GCM"}.to_json }
      let(:hashed_token) { OpenSSL::Digest.digest('SHA256', "INTEGRITY_TOKEN") }
      let(:integrity_token) { Base64.encode64(alg_and_enc + hashed_token) }
      let(:decoded_assertion) do
        {
          v: 0,
          p: 2,
          date: date,
          integrity_token: integrity_token,
        }
      end
      let(:x_tru_assertion) { Base64.strict_encode64(decoded_assertion.to_json) }
      let(:nonce) { OpenSSL::Digest.digest('SHA256', "NONCE") }
      let(:client_data) { { date: date, request: Base64.urlsafe_encode64(nonce) }.to_json }
      let(:verdict_nonce) { Base64.urlsafe_encode64(OpenSSL::Digest.digest('SHA256', client_data)) }
      let(:verdict) do
        [
          {
            "requestDetails"=> {
              "requestPackageName"=> "PACKAGE_NAME",
              "timestampMillis"=> "TIMESTAMP",
              "nonce"=> verdict_nonce
            },
            "appIntegrity"=> {
              "appRecognitionVerdict"=> "UNRECOGNIZED_VERSION",
              "packageName"=> "PACKAGE_NAME",
              "certificateSha256Digest"=> ["DIGEST"],
              "versionCode"=> "VERSION CODE"
            },
            "deviceIntegrity"=> {
              "deviceRecognitionVerdict"=> %w[MEETS_BASIC_INTEGRITY MEETS_DEVICE_INTEGRITY MEETS_STRONG_INTEGRITY]
            },
            "accountDetails"=> {
              "appLicensingVerdict"=> "LICENSED"
            }
          },
          {
            "alg"=> "ES256"
          }
        ]
      end

      before do
        request.headers['x-tru-assertion'] = x_tru_assertion
        request.headers['x-tru-date'] = date
        request.user_agent = "TruthSocialAndroid/okhttp/5.0.0-alpha.7"

        allow_any_instance_of(AndroidDeviceCheck::IntegrityService).to receive(:decrypt_token).and_return(verdict)
      end

      it 'should validate and store a device verification record' do
        canonical_instance = instance_double(CanonicalRequestService, canonical_string: 'NONCE', canonical_headers: {})
        allow(CanonicalRequestService).to receive(:new).and_return(canonical_instance)
        allow(canonical_instance).to receive(:call).and_return(nonce)

        chat = Chat.create(owner_account_id: account.id, members: [recipient.id])
        recipient.user = recipient_user
        message = Faker::Lorem.characters(number: 15)

        post :create, params: { account_id: account.id, chat_id: chat.chat_id, content: message }

        expect(response).to have_http_status(200)
        device_verification = DeviceVerification.find_by("details ->> 'integrity_token' = '#{integrity_token}'")
        device_verification_user = DeviceVerificationUser.find_by(verification: device_verification)
        expect(device_verification.details['integrity_errors']).to be_empty
        expect(device_verification_user.user_id).to eq(user.id)
        dvcm = DeviceVerificationChatMessage.find_by(verification_id: device_verification.id)
        expect(dvcm.message_id.to_s).to eq body_as_json[:id]
      end
    end

    context 'App Attest' do
      let(:assertion) { { 'signature' => "SIGNATURE", 'authenticatorData' => 'AUTHENTICATOR_DATA' } }
      let(:credential) {
        user.webauthn_credentials.create(
          nickname: 'SecurityKeyNickname',
          external_id: 'EXTERNAL_ID',
          public_key: "PUBLIC_KEY",
          sign_count: 0
        )
      }
      let(:date) { (Time.now.utc.to_f * 1000).to_i }
      let(:decoded_assertion) do
        {
          id: credential.external_id,
          v: 0,
          p: 1,
          date: date,
          assertion: Base64.strict_encode64(assertion.to_cbor),
        }
      end


      let(:assertion_response) { OpenStruct.new(authenticator_data: { sign_count: 1 }) }
      let(:x_tru_assertion) { Base64.strict_encode64(decoded_assertion.to_json) }

      before do
        allow(WebAuthn::AuthenticatorAssertionResponse).to receive(:new).and_return(assertion_response)
        allow_any_instance_of(IosDeviceCheck::AssertionService).to receive(:valid_assertion?).and_return(true)

        request.headers['x-tru-assertion'] = x_tru_assertion
        request.headers['x-tru-date'] = date
        request.user_agent = "TruthSocial/83 CFNetwork/1121.2.2 Darwin/19.3.0"
      end

      it 'should validate assertion and store a device verification record' do
        chat = Chat.create(owner_account_id: account.id, members: [recipient.id])
        recipient.user = recipient_user
        message = Faker::Lorem.characters(number: 15)

        post :create, params: { account_id: account.id, chat_id: chat.chat_id, content: message }

        expect(response).to have_http_status(200)
        device_verification = DeviceVerification.find_by("details ->> 'external_id' = '#{credential.external_id}'")
        device_verification_user = DeviceVerificationUser.find_by(verification: device_verification)
        expect(device_verification_user.user_id).to eq(user.id)
        dvcm = DeviceVerificationChatMessage.find_by(verification_id: device_verification.id)
        expect(dvcm.message_id.to_s).to eq body_as_json[:id]
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'deleting message created by current user' do
      before do
        @chat = Chat.create(owner_account_id: account.id, members: [recipient.id])
        recipient.user = recipient_user

        @message = JSON.parse(ChatMessageService.new(
          chat_id: @chat.chat_id,
          chat_expiration: @chat.message_expiration,
          content: Faker::Lorem.characters(number: 15),
          created_by_account_id: account.id,
          recipient: recipient,
          silenced: false,
          idempotency: nil,
          unfollowed_and_left: false,
          token: token
        ).call)

        delete :destroy, params: { id: @message['id'], chat_id: @chat.chat_id }
      end

      it 'deletes the message' do
        found = ChatMessage.find_message(account.id, @chat.chat_id, @message['id'])
      rescue ActiveRecord::StatementInvalid
        nil

        expect(found).to be nil
      end

      it 'deletes the associated notification record' do
        expect(Notification.count).to eq 0
      end
    end
  end

  describe 'GET #sync' do
    it 'returns IDs of deleted messages since a given time' do
      chat = Chat.create(owner_account_id: account.id, members: [recipient.id])

      message1 = JSON.parse(ChatMessage.create_by_function!({
        account_id: account.id,
        token: nil,
        idempotency_key: nil,
        chat_id: chat.chat_id,
        content: Faker::Lorem.characters(number: 15),
        media_attachment_ids: nil
      }))

      message2 = JSON.parse(ChatMessage.create_by_function!({
        account_id: account.id,
        token: nil,
        idempotency_key: nil,
        chat_id: chat.chat_id,
        content: Faker::Lorem.characters(number: 15),
        media_attachment_ids: nil
      }))

      ChatMessage.destroy_message!(account.id, message1['id'])
      ChatMessage.destroy_message!(account.id, message2['id'])

      get :sync, params: { chat_id: chat.chat_id, since: 1666103507 }
      expect(response).to have_http_status(200)
      expect(body_as_json).to eq [message1['id'].to_i, message2['id'].to_i]
    end
  end
end
