# frozen_string_literal: true

FactoryBot.define do
  factory :user_repository do
    association :user
    association :repository
    admin { false }
    write_access { true } # Default to write access
    last_accessed_at { Time.current }
    created_at { 1.month.ago }
    updated_at { 1.month.ago }

    # Access levels
    trait :admin do
      admin { true }
      write_access { true }
    end

    trait :write_access do
      admin { false }
      write_access { true }
    end

    trait :read_only do
      admin { false }
      write_access { false }
    end

    # Access timestamps
    trait :recently_accessed do
      last_accessed_at { 1.day.ago }
    end

    trait :not_accessed_recently do
      last_accessed_at { 2.months.ago }
    end

    trait :never_accessed do
      last_accessed_at { nil }
    end

    # Creation timestamps
    trait :recently_added do
      created_at { 1.week.ago }
      updated_at { 1.week.ago }
    end

    trait :added_long_ago do
      created_at { 1.year.ago }
      updated_at { 1.year.ago }
    end

    # Combinations
    trait :admin_with_recent_access do
      admin
      recently_accessed
    end

    trait :write_access_with_old_access do
      write_access
      not_accessed_recently
    end

    trait :read_only_never_accessed do
      read_only
      never_accessed
    end

    # Factory defaults
    factory :admin_user_repository, traits: [ :admin ]
    factory :write_user_repository, traits: [ :write_access ]
    factory :read_only_user_repository, traits: [ :read_only ]
  end
end
