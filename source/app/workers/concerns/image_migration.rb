# frozen_string_literal: true

module ImageMigration
  extend ActiveSupport::Concern

  included do
    include Sidekiq::Worker
    sidekiq_options queue: 'image-migrations', retry: 0, unique: :until_executed

    def self.queue_migrations(ids:)
      self.push_bulk(ids) do |id|
        [id]
      end
    end
  end

  private

  def refresh_acl(object:, names:, acl:)
    names.each do |attachment_name|
      attachment = object.public_send(attachment_name)
      styles     = [:original] | attachment.styles.keys

      next if attachment.blank?

      styles.each do |style|
        case Paperclip::Attachment.default_options[:storage]
        when :s3
          begin
            attachment.s3_object(style).acl.put(acl: acl)
          rescue Aws::S3::Errors::NoSuchKey
            Rails.logger.warn "Tried to change acl on non-existent key #{attachment.s3_object(style).key}"
          rescue Aws::S3::Errors::AccessDenied
            Rails.logger.warn "Access Denied for key #{attachment.s3_object(style).key}, trying to migrate image"
            retrive_from_old_s3(object, attachment_name)
          end
        when :fog
          # Not supported
        when :filesystem
          begin
            if acl == 'private'
              FileUtils.chmod(0o600 & ~File.umask, attachment.path(style)) unless attachment.path(style).nil?
            else
              FileUtils.chmod(0o666 & ~File.umask, attachment.path(style)) unless attachment.path(style).nil?
            end
          rescue Errno::ENOENT
            Rails.logger.warn "Tried to change permission on non-existent file #{attachment.path(style)}"
          end
        end
      end
    end
  end

  def migrate_image(object, attribute)
    return unless object.send(attribute).file?

    begin
      new_image_url = "#{object.send(attribute).s3_protocol}://#{ENV['S3_ALIAS_HOST']}/#{object.send(attribute).path}"
      URI.open(new_image_url)

    # If new image does not open, try to find old one
    rescue StandardError
      retrieve_from_old_s3(object, attribute)
    end
  end

  def retrive_from_old_s3(object, attribute)
    old_image_url = "#{object.send(attribute).s3_protocol}://#{ENV['S3_OLD_ALIAS_HOST']}/#{object.send(attribute).path}"
    begin
      old_image = URI.open(old_image_url)
      object.update!(attribute => old_image)
    rescue StandardError
      # This is best effort, if you cannot load old image the image is just missing
      true
    end
  end
end
