# frozen_string_literal: true

module Paperclip
  # This transcoder is only to be used for the MediaAttachment model
  # to check when uploaded videos are actually gifv's
  class Transcoder < Paperclip::Processor
    def initialize(file, options = {}, attachment = nil)
      super

      @current_format      = File.extname(@file.path)
      @basename            = File.basename(@file.path, @current_format)
      @format              = options[:format]
      @time                = options[:time] || 3
      @passthrough_options = options[:passthrough_options]
      @convert_options     = options[:convert_options].dup
    end

    def make
      metadata = VideoMetadataExtractor.new(@file.path)

      raise Paperclip::Error, "Error while transcoding #{@file.path}: unsupported file" unless metadata.valid?

      # This method changes the attachment type to gifv
      # if it is a video with no sound.  Don't do that...
      # it is stupid and it breaks unit tests.
      # update_attachment_type(metadata)
      update_options_from_metadata(metadata)

      destination = Tempfile.new([@basename, @format ? ".#{@format}" : ''])
      destination.binmode

      @output_options = @convert_options[:output]&.dup || {}
      @input_options = @convert_options[:input]&.dup || {}

      case @format.to_s
      when /jpg$/, /jpeg$/, /png$/, /gif$/
        @input_options['ss'] = @time

        @output_options['f'] = 'image2'
        @output_options['vframes'] = 1
      when /mp4$/, /mov$/
        if metadata.audio_codec != 'aac'
          @output_options['acodec'] = 'aac'
        end
      end
      @output_options['strict'] = 'experimental'

      command_arguments, interpolations = prepare_command(destination)

      begin
        command = Terrapin::CommandLine.new('ffmpeg', command_arguments.join(' '), logger: Paperclip.logger)
        timer_start = Time.zone.now
        command.run(interpolations)
        timer_end = Time.zone.now
        if passthrough_encoding?
          Prometheus::ApplicationExporter.observe_duration(:video_passthrough_encoding, (timer_end - timer_start).in_milliseconds)
        end
      rescue Terrapin::ExitStatusError => e
        raise Paperclip::Error, "Error while transcoding #{@basename}: #{e}"
      rescue Terrapin::CommandNotFoundError
        raise Paperclip::Errors::CommandNotFoundError, 'Could not run the `ffmpeg` command. Please install ffmpeg.'
      end

      destination
    end

    private

    def passthrough_encoding?
      @output_options['c:v'] == 'copy'
    end

    def prepare_command(destination)
      command_arguments = ['-nostdin']
      interpolations = {}
      interpolation_keys = 0

      @input_options.each_pair do |key, value|
        interpolation_key = interpolation_keys
        command_arguments << "-#{key} :#{interpolation_key}"
        interpolations[interpolation_key] = value
        interpolation_keys += 1
      end

      command_arguments << '-i :source'
      interpolations[:source] = @file.path

      @output_options.each_pair do |key, value|
        interpolation_key = interpolation_keys
        command_arguments << "-#{key} :#{interpolation_key}"
        interpolations[interpolation_key] = value
        interpolation_keys += 1
      end

      command_arguments << '-y :destination'
      interpolations[:destination] = destination.path

      [command_arguments, interpolations]
    end

    def update_options_from_metadata(_metadata)
      # always do passthrough encoding if we have the passthrough_options
      # don't filter it by limiting it to quicktime/webm or a particular color palette
      return unless @passthrough_options # && @passthrough_options[:video_codecs].include?(metadata.video_codec) && @passthrough_options[:audio_codecs].include?(metadata.audio_codec) && @passthrough_options[:colorspaces].include?(metadata.colorspace)

      # When doing passthrough encoding, the output format should be the same as the current format
      # don't set it it anything else or we will be doing a conversion
      @format = @current_format # @passthrough_options[:options][:format] || @format
      if @format == '.qt'
        @format = 'mp4'
      end
      @time = @passthrough_options[:options][:time] || @time
      @convert_options = @passthrough_options[:options][:convert_options].dup
    end

    def update_attachment_type(metadata)
      @attachment.instance.type = MediaAttachment.types[:gifv] unless metadata.audio_codec
    end
  end
end
