# frozen_string_literal: true

class ChatChannel < ApplicationCable::Channel
  def subscribed
    # Reject if no chat_id is provided
    return reject unless params[:chat_id].present?
    
    # Find the chat and check if the user has access to it
    @chat = Chat.find_by(id: params[:chat_id])
    return reject unless @chat && current_user.chats.include?(@chat)
    
    # Stream from this channel
    stream_for @chat
    
    # Mark messages as read when user subscribes
    mark_messages_as_read
  end
  
  def unsubscribed
    stop_all_streams
  end
  
  def receive(data)
    # Handle incoming messages from the client
    case data['action']
    when 'typing'
      broadcast_typing
    when 'mark_read'
      mark_messages_as_read(data['last_message_id'])
    end
  end
  
  private
  
  def broadcast_typing
    # Broadcast to other users that this user is typing
    ActionCable.server.broadcast(
      "chat_#{@chat.id}",
      action: 'user_typing',
      user_id: current_user.id,
      username: current_user.username,
      timestamp: Time.current.to_i
    )
  end
  
  def mark_messages_as_read(last_message_id = nil)
    # Mark messages as read for this user in this chat
    if last_message_id.present?
      # Mark all messages up to and including last_message_id as read
      unread_messages = current_user.unread_messages
                                   .where(chat: @chat)
                                   .where('message_id <= ?', last_message_id)
      
      unread_messages.destroy_all
    else
      # Mark all messages in the chat as read
      current_user.unread_messages.where(chat: @chat).destroy_all
    end
    
    # Update the chat user's last_read_at
    chat_user = @chat.chat_users.find_by(user: current_user)
    chat_user&.update(last_read_at: Time.current)
    
    # Broadcast the read receipt to other users
    ActionCable.server.broadcast(
      "chat_#{@chat.id}",
      action: 'messages_read',
      user_id: current_user.id,
      username: current_user.username,
      timestamp: Time.current.to_i,
      last_read_at: chat_user&.last_read_at
    )
  end
end
