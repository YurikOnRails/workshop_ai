FactoryBot.define do
  factory :chat do
    sequence(:name) { |n| "Chat #{n}" }
    description { 'A sample chat description' }

    # Let the model set the default chat_type
    # This will use the default 'group' from set_defaults

    trait :direct do
      chat_type { 'direct' }
      name { 'Direct Chat' }
    end

    trait :group do
      chat_type { 'group' }
      name { 'Group Chat' }
    end

    trait :repository do
      chat_type { 'repository' }
      name { 'Repository Chat' }
      association :repository
    end

    trait :archived do
      archived { true }
    end

    # Explicitly set chat_type to nil to test default value
    trait :with_defaults do
      chat_type { nil }
      archived { nil }
    end

    factory :direct_chat, traits: [ :direct ]
    factory :group_chat, traits: [ :group ]
    factory :repository_chat, traits: [ :repository ]
  end
end
