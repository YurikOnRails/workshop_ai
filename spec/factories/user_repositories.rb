# frozen_string_literal: true

FactoryBot.define do
  factory :user_repository do
    association :user
    association :repository
    admin { false }
    last_accessed_at { Time.current }

    trait :admin do
      admin { true }
    end

    trait :with_recent_access do
      last_accessed_at { 1.day.ago }
    end

    trait :with_old_access do
      last_accessed_at { 1.month.ago }
    end
  end
end
