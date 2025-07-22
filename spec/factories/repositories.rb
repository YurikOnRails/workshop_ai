FactoryBot.define do
  factory :repository do
    sequence(:github_repo_id) { |n| n }
    sequence(:name) { |n| "repo#{n}" }
    full_name { |r| "#{r.owner&.username || 'org'}/#{r.name}" }
    description { Faker::Lorem.sentence }
    private { false }
    fork { false }
    archived { false }
    disabled { false }
    default_branch { 'main' }
    language { 'Ruby' }
    stargazers_count { 0 }
    forks_count { 0 }
    open_issues_count { 0 }
    size { 1024 }
    created_at { 1.year.ago }
    updated_at { 1.month.ago }
    pushed_at { 2.weeks.ago }
    
    association :owner, factory: :user

    # Repository visibility
    trait :public do
      private { false }
    end

    trait :private do
      private { true }
    end

    # Repository states
    trait :forked do
      fork { true }
      association :parent, factory: :repository
    end

    trait :archived do
      archived { true }
    end

    trait :disabled do
      disabled { true }
    end

    # Repository with users
    trait :with_users do
      transient do
        users_count { 1 }
        admin_count { 0 }
        write_access_count { 0 }
        read_access_count { 0 }
      end

      after(:create) do |repository, evaluator|
        # Create admin users if specified
        admins = create_list(:user, evaluator.admin_count)
        admins.each do |admin|
          repository.user_repositories.create(user: admin, admin: true)
        end
        
        # Create users with write access
        writers = create_list(:user, evaluator.write_access_count)
        writers.each do |writer|
          repository.user_repositories.create(user: writer, admin: false, write_access: true)
        end
        
        # Create users with read-only access
        readers = create_list(:user, evaluator.read_access_count)
        readers.each do |reader|
          repository.user_repositories.create(user: reader, admin: false, write_access: false)
        end
        
        # Create regular users if no specific access levels were specified
        if evaluator.admin_count.zero? && evaluator.write_access_count.zero? && evaluator.read_access_count.zero?
          users = create_list(:user, evaluator.users_count)
          repository.users << users
        end
      end
    end

    trait :with_admin do
      after(:create) do |repository, _evaluator|
        admin = create(:user, :admin)
        repository.user_repositories.create(user: admin, admin: true)
      end
    end

    # Repository with chat
    trait :with_chat do
      after(:create) do |repository, _evaluator|
        create(:chat, :repository, repository: repository)
      end
    end

    # Popular repositories
    trait :popular do
      stargazers_count { 1000 }
      forks_count { 100 }
    end

    # Recently updated
    trait :recently_updated do
      updated_at { 1.day.ago }
      pushed_at { 1.day.ago }
    end

    # Language specific
    trait :ruby do
      language { 'Ruby' }
    end

    trait :javascript do
      language { 'JavaScript' }
    end

    trait :python do
      language { 'Python' }
    end
  end
end
