require 'rails_helper'

RSpec.describe SkAdNetworkService, type: :service do
  let(:custom_p256_public_key) { 'MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEDDvmWMQqpjdixab6ZLJisrMIesHj+cQIQHYZj5dMiKsooRLGLjx3bX/4zBMjOPrfZX5QjRatIpFmVDNfD2d0aA==' }
  let(:custom_p192_public_key) { 'MEkwEwYHKoZIzj0CAQYIKoZIzj0DAQEDMgAEiPVPseRK/AhNd+a8hm2/Qb9cbAVBrBBya/mr8PtLTlidyCo3EUlC7Zhcu4TV35GV' }
  let(:apple_p256_public_key) { 'MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEWdp8GPcGqmhgzEFj9Z2nSpQVddayaPe4FMzqM9wib1+aHaaIzoHoLN9zW4K8y4SPykE3YVK3sVqW6Af0lfx3gg==' }
  let(:apple_p192_public_key) { 'MEkwEwYHKoZIzj0CAQYIKoZIzj0DAQEDMgAEMyHD625uvsmGq4C43cQ9BnfN2xslVT5V1nOmAMP6qaRRUll3PB1JYmgSm+62sosG' }

  describe 'with our public keys' do
    before do
      stub_const('ENV', ENV.to_hash.merge('SK_AD_NETWORK_P256_PUBLIC_KEY' => custom_p256_public_key))
      stub_const('ENV', ENV.to_hash.merge('SK_AD_NETWORK_P192_PUBLIC_KEY' => custom_p192_public_key))
    end

    it 'should succeed with verified signature for version "4.0" with source-app-id' do
      json = <<-JSON
        {
        "version": "4.0",
        "ad-network-id": "com.example",
        "attribution-signature": "MEUCIBUoX8oxOjT2idX+MVIf/SWS3z4GhJoi9r9OdiN/XXSrAiEAwQhfgpTkXfuGi/gdipi0fvbokHGjz2TyYmotGS968/o=",
        "app-id": 525463029,
        "source-identifier": "5239",
        "source-app-id": 0,
        "conversion-value": 63,
        "did-win": true,
        "fidelity-type": 1,
        "postback-sequence-index": 0,
        "redownload": false,
        "transaction-id": "6aafb7a5-0170-41b5-bbe4-fe71dedf1e30"
      }
      JSON
      attribution = subject.call(JSON.parse(json), json)
      expect(attribution.persisted?).to eq(true)
      expect(attribution.valid_signature).to eq(true)
      expect(attribution.payload).to eq(json)
    end

    it 'should succeed with verified signature for version "4.0" without source-app-id' do
      json = <<-JSON
      {
        "version": "4.0",
        "ad-network-id": "com.example",
        "attribution-signature": "MEQCIDPwjNaOfM7hi8fuEfgORae80s8SWR4Jes0lKLdXFcP2AiARjCW6j7LeVGXw9amUsu+AyPCOYduMu8W3riY7+TrKcg==",
        "app-id": 525463029,
        "source-identifier": "5239",
        "coarse-conversion-value": "low",
        "did-win": true,
        "fidelity-type": 1,
        "postback-sequence-index": 0,
        "redownload": false,
        "transaction-id": "6aafb7a5-0170-41b5-bbe4-fe71dedf1e30"
      }
      JSON
      attribution = subject.call(JSON.parse(json), json)
      expect(attribution.persisted?).to eq(true)
      expect(attribution.valid_signature).to eq(true)
      expect(attribution.payload).to eq(json)
    end

    it 'should succeed with verified signature for version "4.0" with source-domain' do
      json = <<-JSON
      {
        "version": "4.0",
        "ad-network-id": "com.example",
        "attribution-signature": "MEUCICb9Rv7sJ8JBKwn8ZO6o4Z3ocVSaDl2LYdoxtTc60d0FAiEA6DI1zDweLj2PpOVESm1VvPdXnSv3mxTw0exGFgwefiI=",
        "app-id": 525463029,
        "source-identifier": "5239",
        "source-domain": "example.com",
        "conversion-value": 63,
        "did-win": true,
        "fidelity-type": 1,
        "postback-sequence-index": 0,
        "redownload": false,
        "transaction-id": "6aafb7a5-0170-41b5-bbe4-fe71dedf1e30"
      }
      JSON
      attribution = subject.call(JSON.parse(json), json)
      expect(attribution.persisted?).to eq(true)
      expect(attribution.valid_signature).to eq(true)
      expect(attribution.payload).to eq(json)
    end

    it 'should succeed with verified signature for version "4.0" without source-domain' do
      json = <<-JSON
      {
        "version": "4.0",
        "ad-network-id": "com.example",
        "attribution-signature": "MEYCIQD7IwQHXsRPlq+q70iKdtqiaM6i4aoV2UDIeBvuK516EAIhAOYYjRFeeMFoXuTXFktJu4khjrw/QVxbGcJXGmd7xfi3",
        "app-id": 525463029,
        "source-identifier": "5239",
        "coarse-conversion-value": "low",
        "did-win": true,
        "fidelity-type": 1,
        "postback-sequence-index": 0,
        "redownload": false,
        "transaction-id": "6aafb7a5-0170-41b5-bbe4-fe71dedf1e30"
      }
      JSON
      attribution = subject.call(JSON.parse(json), json)
      expect(attribution.persisted?).to eq(true)
      expect(attribution.valid_signature).to eq(true)
      expect(attribution.payload).to eq(json)
    end

    it 'should succeed with verified signature for version "4.0" with postback-sequence-index 0' do
      json1 = <<-JSON
      {
        "version": "4.0",
        "ad-network-id": "com.example",
        "attribution-signature": "MEUCIDsS1GCjz+anogeWvZoe9TAukEgPS0jbuRhzNJLhyxQ4AiEAwxwpETb1tdNu7movERNZd1+I5mivdnHXgKAQgUb0EsA=",
        "app-id": 525463029,
        "source-identifier": "5239",
        "source-app-id": 0,
        "conversion-value": 63,
        "did-win": true,
        "fidelity-type": 1,
        "postback-sequence-index": 0,
        "redownload": false,
        "transaction-id": "6aafb7a5-0170-41b5-bbe4-fe71dedf1e30"
      }
      JSON
      attribution1 = subject.call(JSON.parse(json1), json1)
      expect(attribution1.persisted?).to eq(true)
      expect(attribution1.valid_signature).to eq(true)
      expect(attribution1.payload).to eq(json1)

      json2 = <<-JSON
      {
        "version": "4.0",
        "ad-network-id": "com.example",
        "attribution-signature": "MEUCIC08OVqNH284LQ0wib/4OXeqdOow+Ek517iQ0zBXw9XUAiEA2DG24DuwBNcdcilyQGPcsuhbFAgM81b8NPp92ON09Ck=",
        "app-id": 525463029,
        "source-identifier": "5239",
        "source-app-id": 0,
        "conversion-value": 63,
        "did-win": true,
        "fidelity-type": 1,
        "postback-sequence-index": 1,
        "redownload": false,
        "transaction-id": "6aafb7a5-0170-41b5-bbe4-fe71dedf1e30"
      }
      JSON
      attribution2 = subject.call(JSON.parse(json2), json2)
      expect(attribution2.persisted?).to eq(true)
      expect(attribution2.valid_signature).to eq(true)
      expect(attribution2.payload).to eq(json2)

      json3 = <<-JSON
      {
        "version": "4.0",
        "ad-network-id": "com.example",
        "attribution-signature": "MEUCIH2ambFTqvx/Q5OOIx58IhNE+q7DCtPZw0lGEwtvVa1UAiEAkLCxrP6qrW7lo+s3T8QtOPGUzG6xAI7GIYGDz0xKOCg=",
        "app-id": 525463029,
        "source-identifier": "5239",
        "source-app-id": 0,
        "conversion-value": 63,
        "did-win": true,
        "fidelity-type": 1,
        "postback-sequence-index": 2,
        "redownload": false,
        "transaction-id": "6aafb7a5-0170-41b5-bbe4-fe71dedf1e30"
      }
      JSON
      attribution3 = subject.call(JSON.parse(json3), json3)
      expect(attribution3.persisted?).to eq(true)
      expect(attribution3.valid_signature).to eq(true)
      expect(attribution3.payload).to eq(json3)
    end

    it 'should succeed with verified signature for version "3.0" with source-app-id' do
      json = <<-JSON
      {
        "version": "3.0",
        "ad-network-id": "com.example",
        "attribution-signature": "MEQCID4MHXsN2UOm4MvHotJ9RKnLz60X0WgEqxaNXoGPGgxFAiAsuVnf8nrn5yn39VacxYGJ/Nk9bcst3BJPoHomhyX5Pw==",
        "app-id": 525463029,
        "campaign-id": 90,
        "source-app-id": 0,
        "conversion-value": 63,
        "did-win": true,
        "fidelity-type": 1,
        "redownload": false,
        "transaction-id": "6aafb7a5-0170-41b5-bbe4-fe71dedf1e31"
      }
      JSON
      attribution = subject.call(JSON.parse(json), json)
      expect(attribution.persisted?).to eq(true)
      expect(attribution.valid_signature).to eq(true)
      expect(attribution.payload).to eq(json)
    end

    it 'should succeed with verified signature for version "3.0" without source-app-id' do
      json = <<-JSON
      {
        "version": "3.0",
        "ad-network-id": "com.example",
        "attribution-signature": "MEUCIF/6gKDSagTf353U9xbV7F3bAhIvUVxAUSJMkIW5EBEMAiEAoyTBtVii3qaNm9UMhrwpQ95p0qcBnNCrvlk6lhm/5ks=",
        "app-id": 525463029,
        "campaign-id": 90,
        "conversion-value": 63,
        "did-win": true,
        "fidelity-type": 1,
        "redownload": false,
        "transaction-id": "6aafb7a5-0170-41b5-bbe4-fe71dedf1e31"
      }
      JSON
      attribution = subject.call(JSON.parse(json), json)
      expect(attribution.persisted?).to eq(true)
      expect(attribution.valid_signature).to eq(true)
      expect(attribution.payload).to eq(json)
    end

    it 'should succeed with verified signature for version "2.2" with source-app-id' do
      json = <<-JSON
      {
        "version": "2.2",
        "ad-network-id": "com.example",
        "attribution-signature": "MEUCIA0kXi61dFdKo0X3tPcoaJAO7ikVLfFgOuv1j6nHVSgnAiEAhe7ROa/vxUxgMq3oJgqMwwTHTxr/5mtZLpVgzgXHLgU=",
        "app-id": 525463029,
        "campaign-id": 90,
        "source-app-id": 0,
        "conversion-value": 63,
        "fidelity-type": 1,
        "redownload": false,
        "transaction-id": "6aafb7a5-0170-41b5-bbe4-fe71dedf1e31"
      }
      JSON
      attribution = subject.call(JSON.parse(json), json)
      expect(attribution.persisted?).to eq(true)
      expect(attribution.valid_signature).to eq(true)
      expect(attribution.payload).to eq(json)
    end

    it 'should succeed with verified signature for version "2.2" without source-app-id' do
      json = <<-JSON
      {
        "version": "2.2",
        "ad-network-id": "com.example",
        "attribution-signature": "MEUCIQDJkuoUY5bZseDKT3+6w2/XyKy/UIGEoq/dW8rV0slmswIgMo67PFFzbPgxbAqRvKNei2AyZIgkO7NByfGg3EwjNV4=",
        "app-id": 525463029,
        "campaign-id": 90,
        "conversion-value": 63,
        "fidelity-type": 1,
        "redownload": false,
        "transaction-id": "6aafb7a5-0170-41b5-bbe4-fe71dedf1e31"
      }
      JSON
      attribution = subject.call(JSON.parse(json), json)
      expect(attribution.persisted?).to eq(true)
      expect(attribution.valid_signature).to eq(true)
      expect(attribution.payload).to eq(json)
    end

    it 'should succeed with verified signature for version "2.1" with source-app-id' do
      json = <<-JSON
      {
        "version": "2.1",
        "ad-network-id": "com.example",
        "attribution-signature": "MEQCIHCfGjZzzcjT356cQwTXqLfy8sMonkYhEkfqxHQSxt48AiB9M+3Px2aNfeS2ucT5RPCBVM7U5517/ubjnfDCtttW6A==",
        "app-id": 525463029,
        "campaign-id": 90,
        "source-app-id": 0,
        "conversion-value": 63,
        "redownload": false,
        "transaction-id": "6aafb7a5-0170-41b5-bbe4-fe71dedf1e31"
      }
      JSON
      attribution = subject.call(JSON.parse(json), json)
      expect(attribution.persisted?).to eq(true)
      expect(attribution.valid_signature).to eq(true)
      expect(attribution.payload).to eq(json)
    end

    it 'should succeed with verified signature for version "2.1" without source-app-id' do
      json = <<-JSON
      {
        "version": "2.1",
        "ad-network-id": "com.example",
        "attribution-signature": "MEYCIQDRSUp6bFgzAPF6XrVITv9qnwxRVL3RhXSATnqUuAX0FgIhAKgx/3wBnVX4oLOlDpXoWyWHsORmvQQtLDH/MgqcHFKi",
        "app-id": 525463029,
        "campaign-id": 90,
        "conversion-value": 63,
        "redownload": false,
        "transaction-id": "6aafb7a5-0170-41b5-bbe4-fe71dedf1e31"
      }
      JSON
      attribution = subject.call(JSON.parse(json), json)
      expect(attribution.persisted?).to eq(true)
      expect(attribution.valid_signature).to eq(true)
      expect(attribution.payload).to eq(json)
    end

    it 'should succeed with verified signature for version "2.0" with source-app-id' do
      json = <<-JSON
      {
        "version": "2.0",
        "ad-network-id": "com.example",
        "attribution-signature": "MDYCGQCQ8XED9sPmBDkn1Gm3ua09ZLqM/N/JKT8CGQCdHz01gpgdcnClCGF95vVRExoiZ05WGGw=",
        "app-id": 525463029,
        "campaign-id": 90,
        "source-app-id": 0,
        "conversion-value": 63,
        "redownload": false,
        "transaction-id": "6aafb7a5-0170-41b5-bbe4-fe71dedf1e31"
      }
      JSON
      attribution = subject.call(JSON.parse(json), json)
      expect(attribution.persisted?).to eq(true)
      expect(attribution.valid_signature).to eq(true)
      expect(attribution.payload).to eq(json)
    end

    it 'should succeed with verified signature for version "2.0" without source-app-id' do
      json = <<-JSON
      {
        "version": "2.0",
        "ad-network-id": "com.example",
        "attribution-signature": "MDYCGQDSVOEP9yQT1EnUfQWVwAatJLCYL6g8kWgCGQCvHHjigF/p0jFDcAX0IIIIbxQh8ZZDsTk=",
        "app-id": 525463029,
        "campaign-id": 90,
        "conversion-value": 63,
        "redownload": false,
        "transaction-id": "6aafb7a5-0170-41b5-bbe4-fe71dedf1e31"
      }
      JSON
      attribution = subject.call(JSON.parse(json), json)
      expect(attribution.persisted?).to eq(true)
      expect(attribution.valid_signature).to eq(true)
      expect(attribution.payload).to eq(json)
    end

    it 'should succeed with unverified signature for a non-existent version' do
      json = <<-JSON
      {
        "version": "2.3",
        "ad-network-id": "com.example",
        "attribution-signature": "MEQCIAHyUP253P0t4CxxF/pE1ecki6pwAR6iNXx6B5CttG2QAiBtNBTu8j+YNdY1AmbQP6Cu0WY3GkGuZcP9OfclN/B9Pg==",
        "app-id": 525463029,
        "source-identifier": "5239",
        "source-app-id": 0,
        "conversion-value": 63,
        "did-win": true,
        "fidelity-type": 1,
        "postback-sequence-index": 0,
        "redownload": false,
        "transaction-id": "6aafb7a5-0170-41b5-bbe4-fe71dedf1e30"
      }
      JSON
      attribution = subject.call(JSON.parse(json), json)
      expect(attribution.persisted?).to eq(true)
      expect(attribution.valid_signature).to eq(false)
      expect(attribution.payload).to eq(json)
    end
  end

  describe "with Apple's public keys" do
    before do
      stub_const('ENV', ENV.to_hash.merge('SK_AD_NETWORK_P256_PUBLIC_KEY' => apple_p256_public_key))
      stub_const('ENV', ENV.to_hash.merge('SK_AD_NETWORK_P192_PUBLIC_KEY' => apple_p192_public_key))
    end

    it 'should succeed with verified signature for version 4.0 with high postback data tier' do
      json = <<-JSON
      {
        "version": "4.0",
        "ad-network-id": "com.example",
        "source-identifier": "5239",
        "app-id": 525463029,
        "transaction-id": "6aafb7a5-0170-41b5-bbe4-fe71dedf1e30",
        "redownload": false,
        "source-domain": "example.com",
        "fidelity-type": 1,
        "did-win": true,
        "conversion-value": 63,
        "postback-sequence-index": 0,
        "attribution-signature": "MEUCIGRmSMrqedNu6uaHyhVcifs118R5z/AB6cvRaKrRRHWRAiEAv96ne3dKQ5kJpbsfk4eYiePmrZUU6sQmo+7zfP/1Bxo="
      }
      JSON
      attribution = subject.call(JSON.parse(json), json)
      expect(attribution.persisted?).to eq(true)
      expect(attribution.valid_signature).to eq(true)
      expect(attribution.payload).to eq(json)
    end

    it 'should succeed with verified signature for version 4.0 with low postback data tier' do
      json = <<-JSON
      {
        "version": "4.0",
        "ad-network-id": "com.example",
        "source-identifier": "39",
        "app-id": 525463029,
        "transaction-id": "6aafb7a5-0170-41b5-bbe4-fe71dedf1e31",
        "redownload": false,
        "source-domain": "example.com",
        "fidelity-type": 1,
        "did-win": true,
        "coarse-conversion-value": "high",
        "postback-sequence-index": 0,
        "attribution-signature": "MEUCIQD4rX6eh38qEhuUKHdap345UbmlzA7KEZ1bhWZuYM8MJwIgMnyiiZe6heabDkGwOaKBYrUXQhKtF3P/ERHqkR/XpuA="
      }
      JSON
      attribution = subject.call(JSON.parse(json), json)
      expect(attribution.persisted?).to eq(true)
      expect(attribution.valid_signature).to eq(true)
      expect(attribution.payload).to eq(json)
    end

    it 'should succeed with verified signature for version 3.0 winning postback with attribution' do
      json = <<-JSON
      {
        "version": "3.0",
        "ad-network-id": "example123.skadnetwork",
        "campaign-id": 42,
        "transaction-id": "6aafb7a5-0170-41b5-bbe4-fe71dedf1e28",
        "app-id": 525463029,
        "attribution-signature": "MEYCIQD5eq3AUlamORiGovqFiHWI4RZT/PrM3VEiXUrsC+M51wIhAPMANZA9c07raZJ64gVaXhB9+9yZj/X6DcNxONdccQij",
        "redownload": true,
        "source-app-id": 1234567891,
        "fidelity-type": 1,
        "conversion-value": 20,
        "did-win": true
      }
      JSON
      attribution = subject.call(JSON.parse(json), json)
      expect(attribution.persisted?).to eq(true)
      expect(attribution.valid_signature).to eq(true)
      expect(attribution.payload).to eq(json)
    end

    it 'should succeed with verified signature for version 3.0 nonwinning postback, without attribution' do
      json = <<-JSON
      {
        "version": "3.0",
        "ad-network-id": "example123.skadnetwork",
        "campaign-id": 42,
        "transaction-id": "f9ac267a-a889-44ce-b5f7-0166d11461f0",
        "app-id": 525463029,
        "attribution-signature": "MEUCIQDDetUtkyc/MiQvVJ5I6HIO1E7l598572Wljot2Onzd4wIgVJLzVcyAV+TXksGNoa0DTMXEPgNPeHCmD4fw1ABXX0g=",
        "redownload": true,
        "fidelity-type": 1,
        "did-win": false
      }
      JSON
      attribution = subject.call(JSON.parse(json), json)
      expect(attribution.persisted?).to eq(true)
      expect(attribution.valid_signature).to eq(true)
      expect(attribution.payload).to eq(json)
    end

    it 'should succeed with verified signature for version 2.2' do
      json = <<-JSON
      {
        "version" : "2.2",
        "ad-network-id" : "com.example",
        "campaign-id" : 42,
        "transaction-id" : "6aafb7a5-0170-41b5-bbe4-fe71dedf1e28",
        "app-id" : 525463029,
        "attribution-signature" : "MEYCIQDTuQ1Z4Tpy9D3aEKbxLl5J5iKiTumcqZikuY/AOD2U7QIhAJAaiAv89AoquHXJffcieEQXdWHpcV8ZgbKN0EwV9/sY",
        "redownload": true,
        "source-app-id": 1234567891,
        "fidelity-type": 1,
        "conversion-value": 20
      }
      JSON
      attribution = subject.call(JSON.parse(json), json)
      expect(attribution.persisted?).to eq(true)
      expect(attribution.valid_signature).to eq(true)
      expect(attribution.payload).to eq(json)
    end
  end

  describe 'with invalid data' do
    it 'should raise exception "ActiveRecord::RecordInvalid" with invalid json' do
      expect { subject.call({}, 'invalid json') }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
