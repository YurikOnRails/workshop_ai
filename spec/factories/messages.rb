FactoryBot.define do
  factory :message do
    chat { nil }
    user { nil }
    content { "MyText" }
  end
end
