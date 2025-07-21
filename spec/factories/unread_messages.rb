FactoryBot.define do
  factory :unread_message do
    user { nil }
    chat { nil }
    last_read_message { nil }
  end
end
