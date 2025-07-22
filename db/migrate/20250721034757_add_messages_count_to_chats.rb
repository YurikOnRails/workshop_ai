class AddMessagesCountToChats < ActiveRecord::Migration[8.0]
  def change
    add_column :chats, :messages_count, :integer, default: 0, null: false
    add_index :chats, :messages_count
  end
end
