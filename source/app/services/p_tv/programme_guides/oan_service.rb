# frozen_string_literal: true
class PTv::ProgrammeGuides::OanService
  include PTv::ProgrammeGuides::ProgrammeGuideConcern

  OAN_EPG_URL = ENV.fetch('OAN_EPG_URL', false)

  def call
    return unless OAN_EPG_URL
    progammes = parse_csv
    build_xml('oanlivestream', 'OAN', progammes)
  end

  private

  def parse_csv
    programmes = []
    csv_file = URI.parse(OAN_EPG_URL).open { |f| f.read }
    parsed_csv = CSV.parse(csv_file, headers: true)

    parsed_csv.each_with_index do |programme, index|
      break if index == parsed_csv.size - 1

      start_datetime = Time.strptime("#{programme['Actual Air Date']} #{programme['Actual Air Time']}  EST", '%m/%d/%Y %H:%M:%S %Z')
      formated_start_datetime = start_datetime.strftime('%Y%m%d%H%M%S %z')

      end_datetime = Time.strptime("#{parsed_csv[index + 1]['Actual Air Date']} #{parsed_csv[index + 1]['Actual Air Time']}  EST", '%m/%d/%Y %H:%M:%S %Z')
      formated_end_datetime = end_datetime.strftime('%Y%m%d%H%M%S %z')

      duration = (end_datetime - start_datetime).to_i

      programmes << { start: formated_start_datetime,
                      stop: formated_end_datetime,
                      duration: duration,
                      unit: 'sec',
                      title: { text: programme['Take 2::Series'], lang: 'en' },
                      desc: { text: programme['Take 2::Program Description'], lang: 'en' },
                      release_year: { text: start_datetime.strftime('%Y'), lang: 'en' },
                      category: { text: 'News', lang: 'en' },
                      rating: { text: '' } }
    end

    programmes
  end
end
