class AddMessageTypeToMessages < ActiveRecord::Migration[8.0]
  def up
    # Add the column with a default value
    add_column :messages, :message_type, :string, null: false, default: 'text'

    # Add a check constraint to ensure only valid message types are used
    execute <<-SQL
      ALTER TABLE messages
      ADD CONSTRAINT check_message_type
      CHECK (message_type IN ('text', 'markdown', 'code'));
    SQL

    # Update existing records to have the default message type
    Message.update_all(message_type: 'text')
  end

  def down
    # Remove the check constraint
    execute 'ALTER TABLE messages DROP CONSTRAINT IF EXISTS check_message_type'

    # Remove the column
    remove_column :messages, :message_type
  end
end
