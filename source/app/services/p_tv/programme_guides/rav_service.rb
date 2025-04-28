# frozen_string_literal: true
class PTv::ProgrammeGuides::RavService
  include PTv::ProgrammeGuides::ProgrammeGuideConcern

  RAV_EPG_URL = ENV.fetch('RAV_EPG_URL', false)

  def call
    return unless RAV_EPG_URL
    progammes = parse_json
    build_xml('ravlivestream', 'Real America\'s Voice', progammes)
  end

  private

  def parse_json
    response = HTTP.timeout(5).get(epg_url).parse
    data = response['data']

    return [] unless data

    programmes = []
    data.each do |_day, day_data|
      day_data.each do |programme|
        start_datetime = ActiveSupport::TimeZone.new('Eastern Time (US & Canada)').parse(programme['startAt'])
        start_datetime_formated = start_datetime.strftime('%Y%m%d%H%M%S %z')

        duration = DateTime.parse(programme['duration'])
        duration_in_seconds = duration.hour * 3600 + duration.min * 60

        end_datetime_formated = (start_datetime + duration_in_seconds).strftime('%Y%m%d%H%M%S %z')

        programme_object = { start: start_datetime_formated,
        stop: end_datetime_formated,
        duration: duration_in_seconds,
        unit: 'sec',
        title: { text: programme['title'], lang: 'en' },
        desc: { text: programme['description'], lang: 'en' },
        release_year: { text: start_datetime.strftime('%Y'), lang: 'en' },
        category: { text: 'News', lang: 'en' },
        rating: { text: '' } }

        image_url = programme.dig('poster', 'original')
        programme_object[:image] = { text: '', src: image_url } if image_url

        programmes << programme_object
      end
    end

    programmes
  end

  def epg_url
    date_params = { start_date: (Time.now - 7.day).strftime('%Y-%m-%d'), end_date: (Time.now + 7.day).strftime('%Y-%m-%d') }
    uri = URI.parse(RAV_EPG_URL)
    params = URI.decode_www_form(uri.query || '') + date_params.to_a
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end
end
