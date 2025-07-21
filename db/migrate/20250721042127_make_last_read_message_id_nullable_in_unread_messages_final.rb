class MakeLastReadMessageIdNullableInUnreadMessagesFinal < ActiveRecord::Migration[8.0]
  def up
    # First, remove the foreign key constraint if it exists
    if foreign_key_exists?(:unread_messages, :messages, column: :last_read_message_id)
      remove_foreign_key :unread_messages, column: :last_read_message_id
    end

    # Make the column nullable
    change_column :unread_messages, :last_read_message_id, :bigint, null: true

    # Re-add the foreign key constraint with the new definition
    add_foreign_key :unread_messages, :messages, column: :last_read_message_id, on_delete: :nullify
  end

  def down
    # Remove the foreign key constraint
    if foreign_key_exists?(:unread_messages, :messages, column: :last_read_message_id)
      remove_foreign_key :unread_messages, column: :last_read_message_id
    end

    # Make the column not nullable again
    change_column :unread_messages, :last_read_message_id, :bigint, null: false

    # Re-add the foreign key constraint with the original definition
    add_foreign_key :unread_messages, :messages, column: :last_read_message_id
  end
end
