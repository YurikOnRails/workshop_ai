require 'rails_helper'

RSpec.feature 'User Profile', type: :feature do
  let(:user) { create(:user, username: 'testuser', email: 'test@example.com', 
                         private_repos_count: 5, stars_count: 10, private_stars_count: 3) }
  
  before do
    login_as(user, scope: :user)
  end

  scenario 'User views their own profile' do
    visit profile_path(user.username)
    
    expect(page).to have_content('testuser')
    expect(page).to have_content('test@example.com')
    expect(page).to have_content('5 Private Repositories')
    expect(page).to have_content('10 Total Stars')
    expect(page).to have_content('3 Private Stars')
  end

  scenario 'User views another user\'s profile' do
    other_user = create(:user, username: 'otheruser', email: 'other@example.com')
    visit profile_path(other_user.username)
    
    expect(page).to have_content('otheruser')
    expect(page).not_to have_content('other@example.com') # Email should be private
  end

  scenario 'Profile shows user\'s repositories' do
    repo1 = create(:repository, name: 'repo1', private: true)
    repo2 = create(:repository, name: 'repo2', private: false)
    create(:user_repository, user: user, repository: repo1)
    create(:user_repository, user: user, repository: repo2)
    
    visit profile_path(user.username)
    
    expect(page).to have_content('repo1')
    expect(page).to have_content('repo2')
  end
end
