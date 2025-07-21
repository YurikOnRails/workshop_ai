FactoryBot.define do
  factory :chat_user do
    association :chat
    association :user
    association :added_by, factory: :user
    joined_at { Time.current }
    left_at { nil }
    muted { false }
    admin { false }
    last_read_at { nil }
    last_read_message_id { nil }
    
    trait :active do
      left_at { nil }
    end
    
    trait :inactive do
      left_at { 1.day.ago }
    end
    
    trait :muted do
      muted { true }
    end
    
    trait :admin do
      admin { true }
    end
    
    trait :with_last_read do
      last_read_at { 1.hour.ago }
    end
    
    trait :added_by_user do
      association :added_by, factory: :user
    end
    
    # Default to active
    after(:build) do |chat_user|
      chat_user.left_at ||= nil
    end
  end
end
