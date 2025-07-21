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

    # Update user's online status and last seen timestamp
    update_user_presence(true)

    # Mark messages as read when user subscribes
    mark_messages_as_read

    # Broadcast user's online status to other chat participants
    broadcast_user_presence(true)
  end

  def unsubscribed
    # Update user's online status when they disconnect
    update_user_presence(false)

    # Broadcast user's offline status to other chat participants
    broadcast_user_presence(false)

    stop_all_streams
  end

  def receive(data)
    # Handle incoming messages from the client
    case data["action"]
    when "typing"
      broadcast_typing
    when "mark_read"
      mark_messages_as_read(data["last_message_id"])
    when "presence_ping"
      # Update user's last seen timestamp
      update_user_presence(true)
      # Broadcast current presence status
      broadcast_user_presence(current_user.online?)
    end
  end

  private

  def broadcast_typing
    # Broadcast to other users that this user is typing
    ActionCable.server.broadcast(
      "chat_#{@chat.id}",
      action: "user_typing",
      user_id: current_user.id,
      username: current_user.username,
      timestamp: Time.current.to_i
    )
  end

  private

  # Update user's presence status
  def update_user_presence(online)
    # Skip if no user or no change in status
    return unless current_user

    # Update the user's online status and last seen timestamp
    current_user.update_columns(
      online: online,
      last_seen_at: Time.current,
      updated_at: Time.current
    )

    # Update cache
    Rails.cache.write(
      "user_online_status_#{current_user.id}",
      online,
      expires_in: 10.minutes
    )
  end

  # Broadcast user's presence status to all chat participants
  def broadcast_user_presence(online)
    return unless @chat && current_user

    # Get the count of online users in this chat
    online_count = @chat.users.online.count

    # Broadcast the presence update
    ChatChannel.broadcast_to(
      @chat,
      {
        type: "presence",
        user_id: current_user.id,
        username: current_user.username,
        online: online,
        online_count: online_count,
        timestamp: Time.current.iso8601
      }
    )
  end

  def mark_messages_as_read(last_message_id = nil)
    # Mark messages as read for this user in this chat
    if last_message_id.present?
      # Mark all messages up to and including last_message_id as read
      unread_messages = current_user.unread_messages
                                   .where(chat: @chat)
                                   .where("message_id <= ?", last_message_id)

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
      action: "messages_read",
      user_id: current_user.id,
      username: current_user.username,
      timestamp: Time.current.to_i,
      last_read_at: chat_user&.last_read_at
    )
  end
end
