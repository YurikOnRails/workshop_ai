class MakeLastReadMessageIdNullableInUnreadMessages < ActiveRecord::Migration[8.0]
  def up
    # Remove the existing foreign key constraint
    remove_foreign_key :unread_messages, column: :last_read_message_id
    
    # Make the column nullable
    change_column_null :unread_messages, :last_read_message_id, true
    
    # Re-add the foreign key constraint with the new definition
    add_foreign_key :unread_messages, :messages, column: :last_read_message_id, on_delete: :nullify
  end
  
  def down
    # Remove the foreign key constraint
    remove_foreign_key :unread_messages, column: :last_read_message_id
    
    # Make the column not nullable again
    change_column_null :unread_messages, :last_read_message_id, false
    
    # Re-add the foreign key constraint with the original definition
    add_foreign_key :unread_messages, :messages, column: :last_read_message_id
  end
end
