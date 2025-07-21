# frozen_string_literal: true

module UserActivityTracking
  extend ActiveSupport::Concern

  included do
    before_action :track_user_activity
  end

  private

  def track_user_activity
    return unless current_user

    # Update last seen at timestamp
    current_user.update_columns(
      last_seen_at: Time.current,
      online: true
    )

    # Update cache
    Rails.cache.write(
      "user_online_status_#{current_user.id}",
      true,
      expires_in: 5.minutes
    )

    # Broadcast status update to all user's chats
    current_user.chats.each do |chat|
      ChatChannel.broadcast_to(
        chat,
        type: "presence",
        user_id: current_user.id,
        online: true,
        timestamp: Time.current.iso8601
      )
    end
  end
end
