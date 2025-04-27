# frozen_string_literal: true
class PTv::ProgrammeGuides::NewsmaxService
  include PTv::ProgrammeGuides::ProgrammeGuideConcern

  NEWSMAX_EPG_URL = ENV.fetch("NEWSMAX_EPG_URL", false)

  def call
    return unless NEWSMAX_EPG_URL
    progammes = parse_xml
    build_xml('newsmaxtvlivestream', 'NewsmaxTV Live', progammes)
  end

  private

  def parse_xml
    @doc = Nokogiri::XML(URI.parse(NEWSMAX_EPG_URL).open { |f| f.read })
    programmes = []

    @doc.xpath('//programme').each do |programme|
      formated_start_time = ActiveSupport::TimeZone.new('UTC').parse(programme['start']).strftime('%Y%m%d%H%M%S %z')
      formated_stop_time = ActiveSupport::TimeZone.new('UTC').parse(programme['stop']).strftime('%Y%m%d%H%M%S %z')

      programmes << { start: formated_start_time,
                      stop: formated_stop_time,
                      duration: programme['duration'],
                      unit: programme['unit'],
                      title: { text: programme.css('title').first.content, lang: programme.css('title').first['lang'] },
                      desc: { text: programme.css('desc').first.content, lang: programme.css('desc').first['lang'] },
                      release_year: { text: programme.css('release-year').first.content, lang: programme.css('release-year').first['lang'] },
                      category: { text: programme.css('category').first.content, lang: programme.css('category').first['lang'] },
                      genre: { text: programme.css('genre').first.content, id: programme.css('genre').first['id'] },
                      image: { text: programme.css('image').first.content, src: programme.css('image').first['src'] },
                      rating: { text: programme.css('rating').first.content },
                      episode_num: { text: programme.css('episode-num').first.content, system: programme.css('episode-num').first['system'] } }
    end

    programmes
  end
end
