class CreateChats < ActiveRecord::Migration[8.0]
  def change
    create_table :chats do |t|
      t.string :chat_type, null: false
      t.references :repository, null: true, foreign_key: true
      t.string :name
      t.text :description
      t.datetime :last_message_at

      t.timestamps
    end

    add_index :chats, :chat_type
    add_index :chats, :last_message_at
    
    # Composite index for private chats (repository chats)
    add_index :chats, [:repository_id, :chat_type], unique: true, where: "repository_id IS NOT NULL"
  end
end
