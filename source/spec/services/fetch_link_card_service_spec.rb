require 'rails_helper'

RSpec.describe FetchLinkCardService, type: :service do
  subject { FetchLinkCardService.new }

  before do
    stub_request(:get, 'http://example.xn--fiqs8s/').to_return(request_fixture('idn.txt'))
    stub_request(:get, 'http://example.com/sjis').to_return(request_fixture('sjis.txt'))
    stub_request(:get, 'http://example.com/sjis_with_wrong_charset').to_return(request_fixture('sjis_with_wrong_charset.txt'))
    stub_request(:get, 'http://example.com/koi8-r').to_return(request_fixture('koi8-r.txt'))
    stub_request(:get, 'http://example.com/日本語').to_return(request_fixture('sjis.txt'))
    stub_request(:get, 'https://github.com/qbi/WannaCry').to_return(status: 404)
    stub_request(:get, 'http://example.com/test-').to_return(request_fixture('idn.txt'))
    stub_request(:get, 'http://example.com/windows-1251').to_return(request_fixture('windows-1251.txt'))
    stub_request(:get, "https://www.youtube.com/watch?t=5&v=dQw4w9WgXcQ").to_return(status: 200)
    stub_request(:get, "https://#{ENV.fetch('LOCAL_DOMAIN')}/groups/test-group").to_return(status: 200)

  end

  context 'in a local status' do

    before do
      allow(::Resolv).to receive(:getaddress).and_return('111.111.111.111')
      subject.call(status)
    end

    context do
      let(:status) { Fabricate(:status, text: 'Check out http://example.中国', visibility: :public) }

      it 'works with IDN URLs' do
        expect(a_request(:get, 'http://example.xn--fiqs8s/')).to have_been_made.at_least_once
      end
    end

    context do
      let(:status) { Fabricate(:status, text: 'Check out http://example.com/sjis', visibility: :public) }

      it 'works with SJIS' do
        expect(a_request(:get, 'http://example.com/sjis')).to have_been_made.at_least_once
        expect(status.preview_cards.first.title).to eq("SJISのページ")
      end
    end

    context do
      let(:status) { Fabricate(:status, text: 'Check out http://example.com/sjis_with_wrong_charset', visibility: :public) }

      it 'works with SJIS even with wrong charset header' do
        expect(a_request(:get, 'http://example.com/sjis_with_wrong_charset')).to have_been_made.at_least_once
        expect(status.preview_cards.first.title).to eq("SJISのページ")
      end
    end

    context do
      let(:status) { Fabricate(:status, text: 'Check out http://example.com/koi8-r', visibility: :public) }

      it 'works with koi8-r' do
        expect(a_request(:get, 'http://example.com/koi8-r')).to have_been_made.at_least_once
        expect(status.preview_cards.first.title).to eq("Московя начинаетъ только въ XVI ст. привлекать внимане иностранцевъ.")
      end
    end

    context do
      let(:status) { Fabricate(:status, text: 'Check out http://example.com/windows-1251', visibility: :public) }

      it 'works with windows-1251' do
        expect(a_request(:get, 'http://example.com/windows-1251')).to have_been_made.at_least_once
        expect(status.preview_cards.first.title).to eq('сэмпл текст')
      end
    end

    context do
      let(:status) { Fabricate(:status, text: 'テストhttp://example.com/日本語', visibility: :public) }

      it 'works with Japanese path string' do
        expect(a_request(:get, 'http://example.com/日本語')).to have_been_made.at_least_once
        expect(status.preview_cards.first.title).to eq("SJISのページ")
      end
    end

    context do
      let(:status) { Fabricate(:status, text: 'test http://example.com/test-', visibility: :public) }

      it 'works with a URL ending with a hyphen' do
        expect(a_request(:get, 'http://example.com/test-')).to have_been_made.at_least_once
      end
    end

    context do
      let(:status) { Fabricate(:status, text: 'testhttp://example.com/sjis', visibility: :public) }

      it 'does not fetch URLs with not isolated from their surroundings' do
        expect(a_request(:get, 'http://example.com/sjis')).to_not have_been_made
      end
    end

    context do
      let(:status) { Fabricate(:status, text: 'Check out https://youtu.be/dQw4w9WgXcQ?t=5', visibility: :public) }

      it 'converts youtube short links to proper URL' do
        expect(a_request(:get, 'https://www.youtube.com/watch?t=5&v=dQw4w9WgXcQ')).to have_been_made.at_least_once
      end
    end

  end

  context 'in a remote status' do
    let(:status) { Fabricate(:status, account: Fabricate(:account, domain: 'example.com'), text: 'Habt ihr ein paar gute Links zu <a>foo</a> #<span class="tag"><a href="https://quitter.se/tag/wannacry" target="_blank" rel="tag noopener noreferrer" title="https://quitter.se/tag/wannacry">Wannacry</a></span> herumfliegen?   Ich will mal unter <br> <a href="https://github.com/qbi/WannaCry" target="_blank" rel="noopener noreferrer" title="https://github.com/qbi/WannaCry">https://github.com/qbi/WannaCry</a> was sammeln. !<a href="http://sn.jonkman.ca/group/416/id" target="_blank" rel="noopener noreferrer" title="http://sn.jonkman.ca/group/416/id">security</a>&nbsp;', visibility: :public) }

    before do
      subject.call(status)
    end

    it 'parses out URLs' do
      expect(a_request(:get, 'https://github.com/qbi/WannaCry')).to have_been_made.at_least_once
    end

    it 'ignores URLs to hashtags' do
      expect(a_request(:get, 'https://quitter.se/tag/wannacry')).to_not have_been_made
    end
  end

  context 'secondary datacenters' do
    let(:status) { Fabricate(:status, text: 'Check out http://example.com/sjis', visibility: :public) }

    before do
      allow(ENV).to receive(:fetch).with('SECONDARY_DCS', false).and_return('foo,bar')
    end

    it 'creates jobs for secondary datacenters' do
      Sidekiq::Testing.fake! do

        expect(Sidekiq::Queues['foo'].size).to eq(0)
        expect(Sidekiq::Queues['bar'].size).to eq(0)
        subject.call(status)

        expect(Sidekiq::Queues['foo'].first['class']).to eq(InvalidateStatusCacheWorker.name)

        expect(Sidekiq::Queues['foo'].size).to eq(1)
        expect(Sidekiq::Queues['bar'].size).to eq(1)
      end
    end
  end

  context 'with a group' do
    before do
      Group.create!(display_name: 'Test Group', note: 'Note', statuses_visibility: :everyone, owner_account: Fabricate(:account))
      subject.call(status, nil, ENV.fetch('LOCAL_DOMAIN'))
    end

    context do
      let(:status) { Fabricate(:status, text: "Check out https://#{ENV.fetch('LOCAL_DOMAIN')}/group/test-group", visibility: :public) }

      it 'creates a preview card from a group' do
        expect(status.preview_cards.first.title).to eq('Test Group')
      end
    end
  end

end
