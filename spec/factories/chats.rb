FactoryBot.define do
  factory :chat do
    sequence(:name) { |n| "Chat #{n}" }
    description { 'A sample chat description' }
    chat_type { 'group' }
    archived { false }
    created_at { Time.current }
    updated_at { Time.current }

    transient do
      users_count { 2 }
      messages_count { 0 }
    end

    trait :direct do
      chat_type { 'direct' }
      name { 'Direct Chat' }
      users_count { 2 } # Direct chats must have exactly 2 users
    end

    trait :group do
      chat_type { 'group' }
      name { 'Group Chat' }
      users_count { 3 } # Group chats typically have 3+ users
    end

    trait :repository do
      chat_type { 'repository' }
      name { 'Repository Chat' }
      association :repository
      users_count { 3 } # Repository chats typically have multiple users
    end

    trait :archived do
      archived { true }
      archived_at { Time.current }
    end

    trait :with_participants do
      after(:create) do |chat, evaluator|
        users = create_list(:user, evaluator.users_count)
        chat.users << users
      end
    end

    trait :with_messages do
      transient do
        messages_count { 3 }
        message_creator { nil }
      end

      after(:create) do |chat, evaluator|
        creator = evaluator.message_creator || create(:user)
        chat.users << creator unless chat.users.include?(creator)
        create_list(:message, evaluator.messages_count, chat: chat, user: creator)
      end
    end

    trait :with_unread_messages do
      transient do
        unread_count { 3 }
        reader { create(:user) }
      end

      after(:create) do |chat, evaluator|
        # Add reader to chat if not already a participant
        chat.users << evaluator.reader unless chat.users.include?(evaluator.reader)

        # Create unread messages
        create_list(:message, evaluator.unread_count, chat: chat, user: chat.users.where.not(id: evaluator.reader.id).first)
      end
    end

    factory :direct_chat, traits: [ :direct, :with_participants ]
    factory :group_chat, traits: [ :group, :with_participants ]
    factory :repository_chat, traits: [ :repository, :with_participants ]
  end
end
