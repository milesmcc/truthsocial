require 'rails_helper'

RSpec.describe CanonicalRequestService, type: :service do
  let(:sender) { Fabricate(:account, username: 'alice') }


  subject { CanonicalRequestService.new(request) }

  describe '#call' do
    it 'should create a canonical request' do
      body = { text: 'test' }
      request = ActionController::TestRequest.create(Api::V1::StatusesController)
      request.path = '/test'
      request.request_method = 'POST'
      request.headers['Content-Type'] = 'application/json'
      request.headers['RAW_POST_DATA'] = body.to_json
      hashed_body = OpenSSL::Digest.hexdigest('SHA256', body.to_json)
      canonical_request_string = "POST\n/test\n\ncontent-type:application/json\nhost:#{Rails.configuration.x.web_domain}\n\ncontent-type;host\n#{hashed_body}"
      expected_canonical_request = OpenSSL::Digest.digest('SHA256', canonical_request_string)

      canonical_request = CanonicalRequestService.new(request).call

      expect(canonical_request).to eq(expected_canonical_request)
    end

    it "should include all 'x-tru' headers except 'x-tru-assertion 'and sorts them properly" do
      body = { text: 'test' }
      request = ActionController::TestRequest.create(Api::V1::StatusesController)
      request.path = '/test'
      request.request_method = 'POST'
      request.headers['Content-Type'] = 'application/json'
      request.headers['idempotency-key'] = 'IDEMPOTENCY_KEY'
      request.headers['x-tru-assertion'] = 'ASSERTION'
      request.headers['x-tru-a'] = 'tru-a'
      request.headers['x-tru-b'] = 'tru-b'
      request.headers['x-tru-c'] = 'tru-c'
      request.headers['x-tru-d'] = 'tru-d'
      request.headers['RAW_POST_DATA'] = body.to_json
      hashed_body = OpenSSL::Digest.hexdigest('SHA256', body.to_json)
      canonical_request_string = "POST\n/test\n\ncontent-type:application/json\nhost:#{Rails.configuration.x.web_domain}\nidempotency-key:IDEMPOTENCY_KEY\nx-tru-a:tru-a\nx-tru-b:tru-b\nx-tru-c:tru-c\nx-tru-d:tru-d\n\ncontent-type;host;idempotency-key;x-tru-a;x-tru-b;x-tru-c;x-tru-d\n#{hashed_body}"
      expected_canonical_request = OpenSSL::Digest.digest('SHA256', canonical_request_string)

      canonical_request = CanonicalRequestService.new(request).call

      expect(canonical_request).to eq(expected_canonical_request)
    end

    it 'should handle and sort query params and an empty body correctly' do
      body = ''
      request = ActionController::TestRequest.create(Api::V1::StatusesController)
      request.path = '/test'
      request.query_string = 'foo=hello&bar=world&baz=example'
      request.request_method = 'GET'
      request.headers['Content-Type'] = 'application/json'
      hashed_body = OpenSSL::Digest.hexdigest('SHA256', body)
      canonical_request_string = "GET\n/test\nbar=world&baz=example&foo=hello\ncontent-type:application/json\nhost:#{Rails.configuration.x.web_domain}\n\ncontent-type;host\n#{hashed_body}"
      expected_canonical_request = OpenSSL::Digest.digest('SHA256', canonical_request_string)

      canonical_request = CanonicalRequestService.new(request).call

      expect(canonical_request).to eq(expected_canonical_request)
    end
  end
end
