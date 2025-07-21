class CreateUnreadMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :unread_messages do |t|
      t.references :user, null: false, foreign_key: true
      t.references :chat, null: false, foreign_key: true
      t.references :last_read_message, null: false, foreign_key: { to_table: :messages }
      t.integer :unread_count, default: 0, null: false
      t.datetime :last_notified_at

      t.timestamps
    end

    add_index :unread_messages, [:user_id, :chat_id], unique: true, name: 'index_unread_messages_on_user_and_chat'
    # chat_id is already indexed by the foreign key constraint
    add_index :unread_messages, :last_notified_at
    
    # Add a check to ensure a user can't have multiple unread entries for the same chat
    execute <<-SQL
      ALTER TABLE unread_messages
      ADD CONSTRAINT unique_user_chat
      UNIQUE (user_id, chat_id);
      
      -- Ensure unread_count is not negative
      ALTER TABLE unread_messages
      ADD CONSTRAINT check_unread_count
      CHECK (unread_count >= 0);
    SQL
  end
end
