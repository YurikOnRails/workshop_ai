# frozen_string_literal: true

FactoryBot.define do
  factory :chat_user do
    association :chat
    association :user
    association :added_by, factory: :user
    
    # Default attributes
    joined_at { Time.current }
    left_at { nil }
    muted { false }
    admin { false }
    last_read_at { nil }
    last_read_message_id { 0 } # Default to 0 for unread messages
    unread_count { 0 }
    
    # Timestamps
    created_at { 1.week.ago }
    updated_at { 1.week.ago }

    # Status traits
    trait :active do
      left_at { nil }
    end

    trait :inactive do
      left_at { 1.day.ago }
    end

    trait :recently_joined do
      joined_at { 1.hour.ago }
    end

    # Role traits
    trait :admin do
      admin { true }
    end

    trait :regular_user do
      admin { false }
    end

    # Notification preferences
    trait :muted do
      muted { true }
    end

    trait :unmuted do
      muted { false }
    end

    # Message reading status
    trait :with_unread_messages do
      transient do
        unread_count_value { 5 }
      end
      
      unread_count { unread_count_value }
      last_read_at { 1.hour.ago }
    end

    trait :fully_read do
      unread_count { 0 }
      last_read_at { Time.current }
    end

    trait :never_read do
      unread_count { 0 }
      last_read_at { nil }
    end

    # Added by relationships
    trait :self_added do
      added_by { user }
    end

    trait :added_by_admin do
      association :added_by, :admin
    end

    # Timestamp variations
    trait :recently_updated do
      updated_at { 1.hour.ago }
    end

    trait :not_updated_recently do
      updated_at { 1.month.ago }
    end

    # Combinations
    trait :admin_with_unread_messages do
      admin
      with_unread_messages
    end

    trait :muted_regular_user do
      regular_user
      muted
    end

    # Factory defaults
    factory :admin_chat_user, traits: [:admin]
    factory :muted_chat_user, traits: [:muted]
    factory :inactive_chat_user, traits: [:inactive]
    
    # Ensure left_at is nil for active users
    after(:build) do |chat_user|
      chat_user.left_at = nil if chat_user.left_at.blank? && !chat_user.inactive?
    end
  end
end
