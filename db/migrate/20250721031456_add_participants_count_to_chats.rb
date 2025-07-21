class AddParticipantsCountToChats < ActiveRecord::Migration[8.0]
  def change
    add_column :chats, :participants_count, :integer, default: 0, null: false
    add_index :chats, :participants_count
  end
end
