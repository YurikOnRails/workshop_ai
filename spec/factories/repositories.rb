FactoryBot.define do
  factory :repository do
    sequence(:github_repo_id) { |n| n }
    sequence(:name) { |n| "repo#{n}" }
    private { false }
    
    trait :private do
      private { true }
    end
    
    trait :with_users do
      transient do
        users_count { 1 }
      end
      
      after(:create) do |repository, evaluator|
        users = create_list(:user, evaluator.users_count)
        repository.users = users
      end
    end
    
    trait :with_admin do
      after(:create) do |repository, _evaluator|
        admin = create(:user, :admin)
        repository.user_repositories.create(user: admin, admin: true)
      end
    end
  end
end
