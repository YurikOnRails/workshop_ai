FactoryBot.define do
  factory :user do
    github_id { "" }
    username { "MyString" }
    email { "MyString" }
    avatar_url { "MyString" }
    private_repos_count { 1 }
    stars_count { 1 }
    private_stars_count { 1 }
    online { false }
  end
end
