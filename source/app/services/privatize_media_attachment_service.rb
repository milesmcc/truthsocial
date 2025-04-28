# frozen_string_literal: true

class PrivatizeMediaAttachmentService < BaseService
  def call(account)
    @account = account
    privatize_media_attachments!
  end

  private
  def privatize_media_attachments!
    attachment_names = MediaAttachment.attachment_definitions.keys

    @account.media_attachments.find_each do |media_attachment|
      attachment_names.each do |attachment_name|
        attachment = media_attachment.public_send(attachment_name)
        styles     = [:original] | attachment.styles.keys

        next if attachment.blank?

        styles.each do |style|
          case Paperclip::Attachment.default_options[:storage]
          when :s3
            begin
              attachment.s3_object(style).acl.put(acl: 'private')
            rescue Aws::S3::Errors::NoSuchKey
              Rails.logger.warn "Tried to change acl on non-existent key #{attachment.s3_object(style).key}"
            rescue Aws::S3::Errors::AccessDenied
              Rails.logger.warn "Access Denied for key #{attachment.s3_object(style).key}"              
            end
          when :fog
            # Not supported
          when :filesystem
            begin
              FileUtils.chmod(0o600 & ~File.umask, attachment.path(style)) unless attachment.path(style).nil?
            rescue Errno::ENOENT
              Rails.logger.warn "Tried to change permission on non-existent file #{attachment.path(style)}"
            end
          end

          CacheBusterWorker.perform_async(attachment.path(style)) if Rails.configuration.x.cache_buster_enabled
        end
      end
    end
  end
end
