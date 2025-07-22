FactoryBot.define do
  factory :message do
    association :chat
    association :user
    content { Faker::Lorem.paragraph }
    message_type { 'text' }
    created_at { Time.current }
    updated_at { Time.current }

    # Message types
    trait :text do
      message_type { 'text' }
      content { Faker::Lorem.paragraph }
    end

    trait :markdown do
      message_type { 'markdown' }
      content { "## #{Faker::Lorem.sentence}\n\n#{Faker::Markdown.emphasis}\n\n```ruby\nputs 'Hello, world!'\n```" }
    end

    trait :code do
      message_type { 'code' }
      content { "def hello_world\n  puts 'Hello, world!'\nend" }
      language { 'ruby' }
    end

    trait :system do
      message_type { 'system' }
      content { 'System notification' }
      user { nil } # System messages don't have a user
    end

    # Message states
    trait :edited do
      edited_at { Time.current }
      content_updated_at { Time.current }
    end

    trait :deleted do
      deleted_at { Time.current }
      content { '[This message was deleted]' }
    end

    trait :pinned do
      pinned_at { Time.current }
      pinned_by { create(:user) }
    end

    # Message content variations
    trait :with_mentions do
      content { "Hello @#{create(:user).username}, check this out!" }
    end

    trait :with_hashtags do
      content { 'Check out this #awesome #feature' }
    end

    trait :with_links do
      content { 'Check out this link: https://example.com' }
    end

    # Attachments
    trait :with_attachments do
      after(:build) do |message, _evaluator|
        message.attachments.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'sample.txt')),
          filename: 'sample.txt',
          content_type: 'text/plain'
        )
      end
    end

    trait :with_image_attachment do
      after(:build) do |message, _evaluator|
        message.attachments.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'sample.jpg')),
          filename: 'sample.jpg',
          content_type: 'image/jpeg'
        )
      end
    end

    # Timestamps
    trait :recent do
      created_at { 5.minutes.ago }
    end

    trait :old do
      created_at { 1.week.ago }
    end

    # Factory defaults
    factory :text_message, traits: [:text]
    factory :markdown_message, traits: [:markdown]
    factory :code_message, traits: [:code]
    factory :system_message, traits: [:system]
  end
end
