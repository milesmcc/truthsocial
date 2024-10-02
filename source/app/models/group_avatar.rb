# frozen_string_literal: true

module GroupAvatar
  extend ActiveSupport::Concern
  include AccountAvatar

  def avatar_original_url
    avatar.instance.avatar_file_name ? avatar.url(:original) : '/groups/avatars/original/missing.png'
  end
end
