# frozen_string_literal: true
class PTv::ProgrammeGuides::WnService
  include PTv::ProgrammeGuides::ProgrammeGuideConcern
  DAYS_BACK = 7
  DAYS_FORWARD = 7
  PROGRAMME_DURATION_IN_HOURS = 1
  TITLE = 'Top Weather News, Regional Forecasts, Live Severe Coverage, and local weather.'
  DESCRIPTION = 'Live weather updates every hour, regional forecasts, and your local New York weather on the 7\'s.'

  def call
    progammes = generate_feed_data
    build_xml('wnlivestream', 'WeatherNation TV', progammes)
  end

  private

  def generate_feed_data
    total_records = (DAYS_BACK + DAYS_FORWARD) * 24 / PROGRAMME_DURATION_IN_HOURS

    programmes = []
    start_datetime = (Date.today - DAYS_BACK).beginning_of_day

    total_records.times do |_i|
      start_datetime_formated = start_datetime.strftime('%Y%m%d%H%M%S %z')

      duration_in_seconds = PROGRAMME_DURATION_IN_HOURS * 60 * 60

      end_datetime_formated = (start_datetime + duration_in_seconds).strftime('%Y%m%d%H%M%S %z')

      programme_object = { start: start_datetime_formated,
      stop: end_datetime_formated,
      duration: duration_in_seconds,
      unit: 'sec',
      title: { text: TITLE, lang: 'en' },
      desc: { text: DESCRIPTION, lang: 'en' },
      release_year: { text: start_datetime.strftime('%Y'), lang: 'en' },
      category: { text: 'Weather', lang: 'en' },
      rating: { text: '' } }

      programmes << programme_object
      start_datetime += duration_in_seconds
    end
    programmes
  end
end
