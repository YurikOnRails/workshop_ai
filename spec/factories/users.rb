FactoryBot.define do
  factory :user do
    sequence(:github_id) { |n| n }
    sequence(:username) { |n| "user#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    password_confirmation { 'password123' }
    confirmed_at { Time.current }
    avatar_url { "https://example.com/avatar.png" }
    private_repos_count { 3 }
    stars_count { 1 }
    private_stars_count { 1 }
    online { false }
    last_seen_at { 1.hour.ago }

    trait :admin do
      admin { true }
    end

    trait :online do
      online { true }
      last_seen_at { 1.minute.ago }
    end

    trait :offline do
      online { false }
      last_seen_at { 1.day.ago }
    end

    trait :with_repositories do
      transient do
        repositories_count { 3 }
      end

      after(:create) do |user, evaluator|
        create_list(:repository, evaluator.repositories_count, user: user)
      end
    end

    trait :with_chats do
      transient do
        chats_count { 2 }
      end

      after(:create) do |user, evaluator|
        create_list(:chat, evaluator.chats_count, users: [user])
      end
    end

    trait :with_messages do
      transient do
        messages_count { 3 }
      end

      after(:create) do |user, evaluator|
        chat = create(:chat, users: [user])
        create_list(:message, evaluator.messages_count, user: user, chat: chat)
      end
    end
  end
end
