# frozen_string_literal: true

module OnlineStatus
  extend ActiveSupport::Concern
  
  included do
    # Set user as online when they perform any action
    before_save :update_online_status, if: :will_save_change_to_last_seen_at?
    
    # Cache user online status for 5 minutes
    def online?
      Rails.cache.fetch(online_status_key, expires_in: 5.minutes) do
        last_seen_at.present? && last_seen_at > 5.minutes.ago
      end
    end
    
    # Update last seen timestamp
    def seen!
      update_column(:last_seen_at, Time.current)
      update_online_status
    end
    
    # Update online status in cache
    def update_online_status
      was_online = last_seen_at_before_last_save.present? && 
                  (last_seen_at_before_last_save > 5.minutes.ago)
      
      is_online = last_seen_at.present? && (last_seen_at > 5.minutes.ago)
      
      # Only broadcast if status changed
      if was_online != is_online
        broadcast_online_status_change(is_online)
      end
      
      # Update cache
      Rails.cache.write(online_status_key, is_online, expires_in: 5.minutes)
    end
    
    private
    
    def online_status_key
      "user_online_status_#{id}"
    end
    
    def broadcast_online_status_change(online)
      # Broadcast to all user's chats
      chats.each do |chat|
        ChatChannel.broadcast_to(
          chat,
          type: 'presence',
          user_id: id,
          online: online,
          timestamp: Time.current.iso8601
        )
      end
    end
  end
  
  module ClassMethods
    # Mark all users who haven't been seen in more than 5 minutes as offline
    def update_offline_statuses
      where('last_seen_at > ?', 5.minutes.ago)
        .where(online: false)
        .update_all(online: true)
        
      where('last_seen_at <= ?', 5.minutes.ago)
        .where(online: true)
        .update_all(online: false)
    end
  end
end
