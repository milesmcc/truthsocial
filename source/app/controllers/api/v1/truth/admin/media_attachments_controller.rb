# frozen_string_literal: true

class Api::V1::Truth::Admin::MediaAttachmentsController < Api::BaseController
  include Authorization

  before_action -> { doorkeeper_authorize! :'admin:write' }
  before_action :require_staff!
  before_action -> { set_media_attachment }, except: :index

  def destroy
    attachment_names = MediaAttachment.attachment_definitions.keys

    attachment_names.each do |attachment_name|
      attachment = @media_attachment.public_send(attachment_name)
      styles = [:original] | attachment.styles.keys

      styles.each do |style|
        if Paperclip::Attachment.default_options[:storage] == :s3
          attachment.s3_object(style).delete
        end
      end
    end

    @media_attachment.destroy
    render json: {status: :success}
  end

  private

  def set_media_attachment
    @media_attachment = MediaAttachment.find(params[:id])
  end
end
