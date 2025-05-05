# frozen_string_literal: true

module Paperclip
  module MediaTypeSpoofDetectorExtensions
    def mapping_override_mismatch?
      !Array(mapped_content_type).include?(calculated_content_type) && !Array(mapped_content_type).include?(type_from_mime_magic)
    end

    def calculated_media_type_from_mime_magic
      @calculated_media_type_from_mime_magic ||= type_from_mime_magic.split('/').first
    end

    def calculated_type_mismatch?
      !media_types_from_name.include?(calculated_media_type) && !media_types_from_name.include?(calculated_media_type_from_mime_magic)
    end

    def type_from_mime_magic
      @type_from_mime_magic ||= begin
        File.open(@file.path) do |file|
          MimeMagic.by_magic(file)&.type || ''
        end
      rescue Errno::ENOENT
        ''
      end
    end

    def type_from_file_command
      @type_from_file_command ||= FileCommandContentTypeDetector.new(@file.path).detect
    end

    def calculated_content_type
      return @calculated_content_type if defined?(@calculated_content_type)

      @calculated_content_type = type_from_file_command.chomp

      # The `file` command fails to recognize some MP3 files as such
      @calculated_content_type = type_from_marcel if @calculated_content_type == 'application/octet-stream' && type_from_marcel == 'audio/mpeg'
      @calculated_content_type
    end

    def type_from_marcel
      @type_from_marcel ||= Marcel::MimeType.for Pathname.new(@file.path),
                                                 name: @file.path
    end
  end
end

Paperclip::MediaTypeSpoofDetector.prepend(Paperclip::MediaTypeSpoofDetectorExtensions)
