class AddArchivedToChats < ActiveRecord::Migration[8.0]
  def change
    add_column :chats, :archived, :boolean, default: false, null: false
    add_index :chats, :archived
  end
end
