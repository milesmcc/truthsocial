class AddExternalVideoIdToMediaAttachments < ActiveRecord::Migration[6.1]
  def change
    add_column :media_attachments, :external_video_id, :string
  end
end
