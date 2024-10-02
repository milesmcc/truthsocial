# frozen_string_literal: true

module GroupHeader
  extend ActiveSupport::Concern
  include AccountHeader

  def header_original_url
    header.instance.header_file_name ? header.url(:original) : '/groups/headers/original/missing.png'
  end
end
