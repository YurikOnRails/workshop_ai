# frozen_string_literal: true

module OnlineStatusHelper
  # Cache key for user's online status
  def user_online_status_key(user_id)
    "user_online_status_#{user_id}"
  end

  # Check if user is online
  def user_online?(user)
    return false unless user
    
    # Check Redis cache first
    cached_status = Rails.cache.read(user_online_status_key(user.id))
    return cached_status unless cached_status.nil?
    
    # Fallback to database if not in cache
    user.online?
  end

  # Get online status as HTML class
  def online_status_class(user)
    user_online?(user) ? 'online' : 'offline'
  end
  
  # Get online status as text
  def online_status_text(user)
    user_online?(user) ? 'Online' : 'Offline'
  end
  
  # Get online status indicator as HTML
  def online_status_indicator(user, options = {})
    size = options[:size] || 3
    title = options[:title] ? "title=\"#{online_status_text(user)}\"" : ""
    
    if user_online?(user)
      "<span class=\"inline-block rounded-full bg-green-500" #{title} style=\"width: #{size}px; height: #{size}px;\"></span>".html_safe
    else
      "<span class=\"inline-block rounded-full bg-gray-400" #{title} style=\"width: #{size}px; height: #{size}px;\"></span>".html_safe
    end
  end
  
  # Get last seen time for offline users
  def last_seen_at(user)
    return unless user.last_seen_at
    
    if user.last_seen_at > 5.minutes.ago
      'Just now'
    else
      "Last seen #{time_ago_in_words(user.last_seen_at)} ago"
    end
  end
end
