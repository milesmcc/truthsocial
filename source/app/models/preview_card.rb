# frozen_string_literal: true
# == Schema Information
#
# Table name: preview_cards
#
#  id                           :bigint(8)        not null, primary key
#  url                          :string           default(""), not null
#  title                        :string           default(""), not null
#  description                  :string           default(""), not null
#  image_file_name              :string
#  image_content_type           :string
#  image_file_size              :integer
#  image_updated_at             :datetime
#  type                         :integer          default("link"), not null
#  html                         :text             default(""), not null
#  author_name                  :string           default(""), not null
#  author_url                   :string           default(""), not null
#  provider_name                :string           default(""), not null
#  provider_url                 :string           default(""), not null
#  width                        :integer          default(0), not null
#  height                       :integer          default(0), not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  embed_url                    :string           default(""), not null
#  image_storage_schema_version :integer
#  blurhash                     :string
#  file_s3_host                 :string(64)
#

class PreviewCard < ApplicationRecord
  IMAGE_MIME_TYPES = ['image/jpeg', 'image/png', 'image/gif'].freeze
  LIMIT = 2_500.kilobytes

  BLURHASH_OPTIONS = {
    x_comp: 4,
    y_comp: 4,
  }.freeze

  self.inheritance_column = false

  enum type: [:link, :photo, :video, :rich]

  has_and_belongs_to_many :statuses

  has_attached_file :image, processors: [:thumbnail, :blurhash_transcoder], styles: ->(f) { image_styles(f) }, convert_options: { all: '-quality 80 -strip' }

  include Attachmentable

  validates :url, presence: true, uniqueness: true
  validates_attachment_content_type :image, content_type: IMAGE_MIME_TYPES
  validates_attachment_size :image, less_than: LIMIT
  remotable_attachment :image, LIMIT

  attribute :ad, :boolean, default: false

  scope :cached, -> { where.not(image_file_name: [nil, '']) }

  before_save :extract_dimensions, if: :link?
  before_save :set_file_s3_host, if: -> { will_save_change_to_image_file_name? }

  def local?
    false
  end

  def missing_image?
    width.present? && height.present? && image_file_name.blank?
  end

  def save_with_optional_image!
    save!
  rescue ActiveRecord::RecordInvalid
    self.image = nil
    save!
  end

  class << self
    private

    # rubocop:disable Naming/MethodParameterName
    def image_styles(f)
      return {} if f.instance.ad && f.instance.image_content_type == 'image/gif'
      styles = {
        original: {
          geometry: '800x800>',
          file_geometry_parser: FastGeometryParser,
          convert_options: '-coalesce -strip',
          blurhash: BLURHASH_OPTIONS,
        },
      }

      styles[:original][:format] = 'jpg' if f.instance.image_content_type == 'image/gif'
      styles
    end
    # rubocop:enable Naming/MethodParameterName
  end

  private

  def extract_dimensions
    file = image.queued_for_write[:original]

    return if file.nil?

    width, height = FastImage.size(file.path)

    return nil if width.nil?

    self.width  = width
    self.height = height
  end


  def set_file_s3_host
    self.file_s3_host = Paperclip::Attachment.default_options[:s3_host_name]
  end
end
