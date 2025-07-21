FactoryBot.define do
  factory :message do
    association :chat
    association :user
    content { Faker::Lorem.paragraph }
    message_type { 'text' }  # Set a default message type
    
    trait :text do
      message_type { 'text' }
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
    
    trait :with_attachments do
      after(:build) do |message, _evaluator|
        message.attachments.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'sample.txt')),
          filename: 'sample.txt',
          content_type: 'text/plain'
        )
      end
    end
  end
end
