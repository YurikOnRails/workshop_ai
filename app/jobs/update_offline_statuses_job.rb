# frozen_string_literal: true

class UpdateOfflineStatusesJob < ApplicationJob
  queue_as :default

  def perform
    # Find users who were last seen more than 5 minutes ago but are still marked as online
    User.where(online: true)
        .where("last_seen_at <= ?", 5.minutes.ago)
        .find_each do |user|
      user.update_columns(online: false)

      # Update cache
      Rails.cache.write(
        "user_online_status_#{user.id}",
        false,
        expires_in: 5.minutes
      )

      # Broadcast status update to all user's chats
      user.chats.each do |chat|
        ChatChannel.broadcast_to(
          chat,
          type: "presence",
          user_id: user.id,
          online: false,
          timestamp: Time.current.iso8601
        )
      end
    end
  end
end
