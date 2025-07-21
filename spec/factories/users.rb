FactoryBot.define do
  factory :user do
    sequence(:github_id) { |n| n }
    sequence(:username) { |n| "user#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    avatar_url { "https://example.com/avatar.png" }
    public_repos { 5 }
    total_private_repos { 3 }
    owned_private_repos { 2 }
    stars_count { 1 }
    private_stars_count { 1 }
    online { false }
    github_created_at { 1.year.ago }
    
    trait :admin do
      admin { true }
    end
    
    trait :with_repositories do
      transient do
        repositories_count { 3 }
      end
      
      after(:create) do |user, evaluator|
        create_list(:repository, evaluator.repositories_count, users: [user])
      end
    end
  end
end
