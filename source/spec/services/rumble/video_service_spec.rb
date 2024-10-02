require('rails_helper')

describe(Rumble::VideoService) do
  before do
    stub_const('Rumble::VideoService::VIDEO_STATUS_URL', 'https://video.url/?v=')
  end

  describe('perform') do
    context('with a 200 response') do
      let(:valid_id) { 'valid' }

      before do
        body = '{"id":217800049,"id-v":"valid","duration":49,"width":1080,"height":1920,"assets":{"video":[{"quality":"480p","url":"https://sp.rmbl.ws/s8/2/N/L/D/p/NLDpn.caa.mp4?b=1&u=ummtf","width":270,"height":480},{"quality":"720p","url":"https://sp.rmbl.ws/s8/2/N/L/D/p/NLDpn.gaa.mp4?b=1&u=ummtf","width":406,"height":720},{"quality":"1080p","url":"https://sp.rmbl.ws/s8/2/N/L/D/p/NLDpn.haa.mp4?b=1&u=ummtf","width":608,"height":1080}],"thumb":[{"quality":"max","url":"https://sp.rmbl.ws/s8/1/N/L/D/p/NLDpn.aiEB-small-Video-upload-for-1112101906.jpg"}]}}'
        stub_request(
          :get,
          described_class.new(valid_id).send(:endpoint)
        ).to_return(
          status: 200,
          body: body,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it('returns a 200 status') do
        service = described_class.new(valid_id)
        service.perform

        expect(service.status).to eq(200)
      end

      it('returns a valid video') do
        service = described_class.new(valid_id)
        service.perform

        expect(service.video['id-v']).to eq(valid_id)
      end
    end

    context('with a 404 response') do
      let(:invalid_id) { 'invalid' }

      before do
        stub_request(
          :get,
          described_class.new(invalid_id).send(:endpoint)
        ).to_return(
          status: 404,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it('returns a 404 status') do
        service = described_class.new(invalid_id)
        service.perform

        expect(service.status).to eq(404)
      end

      it('returns a nil video') do
        service = described_class.new(invalid_id)
        service.perform

        expect(service.video).to be_nil
      end
    end
  end
end
