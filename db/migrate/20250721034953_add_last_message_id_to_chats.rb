class AddLastMessageIdToChats < ActiveRecord::Migration[8.0]
  def change
    add_column :chats, :last_message_id, :bigint
    add_foreign_key :chats, :messages, column: :last_message_id, on_delete: :nullify
    add_index :chats, :last_message_id
  end
end
