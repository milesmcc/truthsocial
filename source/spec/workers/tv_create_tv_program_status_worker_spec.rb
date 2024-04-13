# frozen_string_literal: true

require 'rails_helper'

describe TvCreateTvProgramStatusWorker do
  subject { described_class.new }

  let(:us) { Country.find_by!(name: 'United States') }
  let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'user'), country: us) }
  let(:scopes) { 'read:accounts' }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }

  let(:start_time) { Time.now.to_i * 1000 }
  let(:end_time) { (Time.now.to_i + 3600) * 1000 }
  let(:program_name) { 'Test program' }
  let(:image_name) { 'test.jpg' }
  let(:tv_channel) { Fabricate(:tv_channel) }

  describe 'perform' do
    before do
      tv_channel.update(enabled: true)
      Fabricate(:tv_channel_account, account: user.account, tv_channel: tv_channel)
      image = fixture_file_upload('attachment.jpg', 'image/jpeg').tempfile.to_io
      stub_request(:get, 'https://vstream.truthsocial.com/test.jpg').to_return(status: 200, body: image, headers: {})

      TvProgram.create(channel_id: tv_channel.id, name: program_name, image_url: image_name, start_time:  Time.zone.at(start_time.to_i / 1000).to_datetime, end_time:  Time.zone.at(end_time.to_i / 1000).to_datetime)
      subject.perform(tv_channel.id, program_name, start_time, end_time, image_name)
    end

    it 'creates a status' do
      status = Status.first
      expect(status.text).to eq("Watch #{program_name}!")
    end

    it 'creates a TV Status record' do
      status = Status.first
      expect(TvStatus.count).to eq 1
    end

    it 'creates a media attachment with the program attributes' do
      status = Status.first
      expect(status.media_attachments.count).to eq 1
      attachment = status.media_attachments[0]
      expect(attachment.type).to eq('tv')
      expect(attachment.file_content_type).to eq('image/jpeg')
    end

    it 'creates a TvProgramStatus record' do
      status = Status.first
      tv_program_status = status.tv_program_status
      expect(tv_program_status.channel_id).to eq(tv_channel.channel_id)
      expect(tv_program_status.tv_program.name).to eq(program_name)
      expect(tv_program_status.start_time).to eq(Time.zone.at(start_time.to_i / 1000).to_datetime)
      expect(tv_program_status.tv_program.end_time).to eq(Time.zone.at(end_time.to_i / 1000).to_datetime)
      expect(tv_program_status.status.id).to eq(status.id)
    end
  end
end
