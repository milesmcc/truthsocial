# frozen_string_literal: true
module PTv::ProgrammeGuides::ProgrammeGuideConcern
  extend ActiveSupport::Concern

  private

  def build_xml(id, display_name, programmes)
    Nokogiri::XML::Builder.new do |xml|
      xml.tv do
        xml.channel(id: id) do
          xml.send(:"display-name", display_name)
        end
        programmes.each do |programme|
          xml.programme(start: programme[:start], stop: programme[:stop], duration: programme[:duration], unit: programme[:unit], channel: id) do
            xml.title do
              xml.parent.set_attribute('lang', programme[:title][:lang])
              xml.text programme[:title][:text]
            end
            xml.send(:desc) do
              xml.parent.set_attribute('lang', programme[:desc][:lang])
              xml.text programme[:desc][:text]
            end
            xml.send(:date) do
              xml.text programme[:release_year][:text]
            end
            xml.send(:category) do
              xml.parent.set_attribute('lang', programme[:category][:lang])
              xml.text programme[:category][:text]
            end
            if programme[:genre]
              xml.send(:genre) do
                xml.parent.set_attribute('id', programme[:genre][:id])
                xml.text programme[:genre][:text]
              end
            end
            if programme[:image]
              xml.send(:image) do
                xml.parent.set_attribute('src', programme[:image][:src])
                xml.text programme[:image][:text]
              end
            end
            xml.send(:rating) do
              xml.parent.set_attribute('system', 'MPAA')
              xml.value do
                xml.text 'NC-17'
              end
            end
            if programme[:episode_num]
              xml.send(:"episode-num") do
                xml.parent.set_attribute('system', programme[:episode_num][:system])
                xml.text programme[:episode_num][:text]
              end
            end
          end
        end
      end
    end
  end
end
