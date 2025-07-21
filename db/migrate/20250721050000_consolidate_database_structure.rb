# frozen_string_literal: true

class ConsolidateDatabaseStructure < ActiveRecord::Migration[8.0]
  def up
    # 1. Add missing indexes for better query performance
    add_index :chats, :created_at
    add_index :messages, :created_at
    add_index :unread_messages, :unread_count
    
    # 2. Add comment to explain the purpose of the chat_type enum
    change_column_comment :chats, :chat_type, 'Type of chat: direct, group, or repository'
    
    # 3. Add comment for archived flag
    change_column_comment :chats, :archived, 'Whether the chat is archived (soft delete)'
    
    # 4. Add comments for counter caches
    change_column_comment :chats, :participants_count, 'Counter cache for chat participants'
    change_column_comment :chats, :messages_count, 'Counter cache for messages in chat'
    
    # 5. Add comments for timestamps
    change_column_comment :chat_users, :joined_at, 'When the user joined the chat'
    change_column_comment :chat_users, :left_at, 'When the user left the chat (soft delete)'
    
    # 6. Add comment for last_read_message_id
    change_column_comment :chat_users, :last_read_message_id, 
      'ID of the last message read by the user in this chat'
    
    # 7. Add comments for unread_messages
    change_column_comment :unread_messages, :last_read_message_id, 
      'ID of the last message read by the user in this chat'
    change_column_comment :unread_messages, :unread_count, 
      'Number of unread messages for the user in this chat'
    
    # 8. Add comment for message_type enum
    change_column_comment :messages, :message_type, 'Type of message: text, markdown, or code'
    
    # 9. Add comment for repository privacy
    change_column_comment :repositories, :private, 'Whether the repository is private'
    
    # 10. Add comment for user_repositories admin flag
    change_column_comment :user_repositories, :admin, 
      'Whether the user has admin rights for this repository'
    
    # 11. Add comment for chat_users admin flag
    change_column_comment :chat_users, :admin, 
      'Whether the user has admin rights in this chat'
    
    # 12. Add comment for chat_users muted flag
    change_column_comment :chat_users, :muted, 
      'Whether the user has muted notifications for this chat'
  end
  
  def down
    # Remove all added indexes
    remove_index :chats, :created_at if index_exists?(:chats, :created_at)
    remove_index :messages, :created_at if index_exists?(:messages, :created_at)
    remove_index :unread_messages, :unread_count if index_exists?(:unread_messages, :unread_count)
    
    # Remove all comments
    change_column_comment :chats, :chat_type, nil
    change_column_comment :chats, :archived, nil
    change_column_comment :chats, :participants_count, nil
    change_column_comment :chats, :messages_count, nil
    change_column_comment :chat_users, :joined_at, nil
    change_column_comment :chat_users, :left_at, nil
    change_column_comment :chat_users, :last_read_message_id, nil
    change_column_comment :chat_users, :admin, nil
    change_column_comment :chat_users, :muted, nil
    change_column_comment :unread_messages, :last_read_message_id, nil
    change_column_comment :unread_messages, :unread_count, nil
    change_column_comment :messages, :message_type, nil
    change_column_comment :repositories, :private, nil
    change_column_comment :user_repositories, :admin, nil
  end
end
