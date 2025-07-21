class AddAddedByToChatUsers < ActiveRecord::Migration[8.0]
  def change
    # Add the reference as nullable
    add_reference :chat_users, :added_by, null: true, foreign_key: { to_table: :users }
    
    # Set default added_by to the user themselves for existing records
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE chat_users
          SET added_by_id = user_id
          WHERE added_by_id IS NULL
        SQL
      end
    end
    
    # Change the column to not null after setting default values
    change_column_null :chat_users, :added_by_id, false
  end
end
