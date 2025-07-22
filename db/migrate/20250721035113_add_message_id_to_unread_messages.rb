class AddMessageIdToUnreadMessages < ActiveRecord::Migration[8.0]
  def change
    add_reference :unread_messages, :message, null: false, foreign_key: true, index: true
  end
end
