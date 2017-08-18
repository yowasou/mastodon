class AddImageOriginalToAccount < ActiveRecord::Migration[5.1]
  def change
    add_column :accounts, :image_binary_original, :binary
  end
end
