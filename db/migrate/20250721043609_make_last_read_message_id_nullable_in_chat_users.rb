class MakeLastReadMessageIdNullableInChatUsers < ActiveRecord::Migration[8.0]
  def up
    # Remove the foreign key constraint first
    if foreign_key_exists?(:chat_users, :messages, column: :last_read_message_id)
      remove_foreign_key :chat_users, column: :last_read_message_id
    end

    # Make the column nullable
    change_column_null :chat_users, :last_read_message_id, true

    # Re-add the foreign key constraint with nullify on delete
    add_foreign_key :chat_users, :messages, column: :last_read_message_id, on_delete: :nullify
  end

  def down
    # Remove the foreign key constraint
    if foreign_key_exists?(:chat_users, :messages, column: :last_read_message_id)
      remove_foreign_key :chat_users, column: :last_read_message_id
    end

    # Make the column not nullable again
    change_column_null :chat_users, :last_read_message_id, false, 0

    # Re-add the foreign key constraint
    add_foreign_key :chat_users, :messages, column: :last_read_message_id, on_delete: :nullify
  end
end
