class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.references :chat, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.datetime :edited_at
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :messages, [:chat_id, :created_at]
    # user_id is already indexed by the foreign key constraint
    add_index :messages, :deleted_at
    
    # Add a check constraint for content length
    execute <<-SQL
      ALTER TABLE messages
      ADD CONSTRAINT check_content_length
      CHECK (length(trim(content)) > 0 AND length(trim(content)) <= 10000);
    SQL
  end
end
