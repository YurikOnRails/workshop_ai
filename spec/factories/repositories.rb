FactoryBot.define do
  factory :repository do
    github_repo_id { "" }
    name { "MyString" }
    private { false }
  end
end
