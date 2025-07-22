# frozen_string_literal: true

FactoryBot.define do
  factory :unread_message do
    association :user
    association :chat
    message_id { 0 } # Default to 0 for unread
    unread_count { 1 }
    last_read_at { nil }
    created_at { Time.current }
    updated_at { Time.current }

    # Message reading states
    trait :read do
      message_id { 100 } # Some message ID that exists
      unread_count { 0 }
      last_read_at { 1.hour.ago }
    end

    trait :unread do
      message_id { 0 }
      unread_count { 1 }
      last_read_at { nil }
    end

    trait :with_multiple_unread do
      transient do
        count { 5 }
      end

      unread_count { count }
      message_id { 0 }
      last_read_at { nil }
    end

    trait :recently_read do
      message_id { 100 }
      unread_count { 0 }
      last_read_at { 5.minutes.ago }
    end

    trait :read_long_ago do
      message_id { 100 }
      unread_count { 0 }
      last_read_at { 1.week.ago }
    end

    # Timestamp variations
    trait :recently_updated do
      updated_at { 1.hour.ago }
    end

    trait :not_updated_recently do
      updated_at { 1.month.ago }
    end

    # Factory defaults
    factory :read_message, traits: [ :read ]
    factory :unread_message_with_count, traits: [ :with_multiple_unread ]
  end
end
