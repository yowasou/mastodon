class AddImageOriginalToMediaAttachment < ActiveRecord::Migration[5.1]
  def change
    add_column :media_attachments, :image_binary_original, :binary
  end
end
