require('rails_helper')

RSpec.describe(Api::V1::Truth::VideosController, type: :controller) do
  before do
    stub_const('Rumble::VideoService::VIDEO_STATUS_URL', 'https://video.url/?v=')
  end

  describe('GET #show') do
    let(:valid_id) { 'valid' }

    context('with a successful response') do
      before do
        body = '{"id":217800049,"id-v":"valid","duration":49,"width":1080,"height":1920,"assets":{"video":[{"quality":"480p","url":"https://sp.rmbl.ws/s8/2/N/L/D/p/NLDpn.caa.mp4?b=1&u=ummtf","width":270,"height":480},{"quality":"720p","url":"https://sp.rmbl.ws/s8/2/N/L/D/p/NLDpn.gaa.mp4?b=1&u=ummtf","width":406,"height":720},{"quality":"1080p","url":"https://sp.rmbl.ws/s8/2/N/L/D/p/NLDpn.haa.mp4?b=1&u=ummtf","width":608,"height":1080}],"thumb":[{"quality":"max","url":"https://sp.rmbl.ws/s8/1/N/L/D/p/NLDpn.aiEB-small-Video-upload-for-1112101906.jpg"}]}}'
        stub_request(
          :get,
          Rumble::VideoService.new(valid_id).send(:endpoint)
        ).to_return(
          status: 200,
          body: body,
          headers: { 'Content-Type' => 'application/json' }
        )

        get(:show, params: { id: valid_id })
      end

      it('returns 200') do
        expect(response).to have_http_status(200)
      end

      it('returns a video') do
        expect(JSON.parse(response.body)['video']['id-v']).to eq(valid_id)
      end
    end

    context('with a 404 response') do
      let(:invalid_id) { 'invalid' }

      before do
        stub_request(
          :get,
          Rumble::VideoService.new(invalid_id).send(:endpoint)
        ).to_return(
          status: 404,
          headers: { 'Content-Type' => 'application/json' }
        )

        get(:show, params: { id: invalid_id })
      end

      it('returns 404') do
        expect(response).to have_http_status(404)
      end
    end
  end
end
