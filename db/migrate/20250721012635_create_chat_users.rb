class CreateChatUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_users do |t|
      t.references :chat, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :joined_at, null: false
      t.datetime :left_at
      t.boolean :muted, default: false, null: false
      t.boolean :admin, default: false, null: false
      t.datetime :last_read_at

      t.timestamps
    end

    add_index :chat_users, [ :chat_id, :user_id ], unique: true, name: 'index_chat_users_on_chat_and_user'
    # user_id is already indexed by the foreign key constraint
    add_index :chat_users, :left_at
    add_index :chat_users, :last_read_at

    # Add a check to ensure a user can't be added to the same chat twice
    execute <<-SQL
      ALTER TABLE chat_users
      ADD CONSTRAINT unique_chat_user
      UNIQUE (chat_id, user_id);

      -- Ensure left_at is after joined_at if both are present
      ALTER TABLE chat_users
      ADD CONSTRAINT check_timeline
      CHECK (left_at IS NULL OR left_at >= joined_at);
    SQL
  end
end
