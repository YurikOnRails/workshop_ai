class AddLastReadMessageIdToChatUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :chat_users, :last_read_message_id, :integer, default: 0, null: false
    add_foreign_key :chat_users, :messages, column: :last_read_message_id, on_delete: :nullify
  end
end
