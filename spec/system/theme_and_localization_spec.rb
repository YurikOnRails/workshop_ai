require 'rails_helper'

RSpec.describe 'Theme and Localization', type: :system, js: true do
  let(:user) { create(:user) }
  
  before do
    login_as(user, scope: :user)
  end

  scenario 'User switches between light and dark theme' do
    visit root_path
    
    # Check default theme (light)
    expect(page).to have_css('body.theme-light')
    
    # Switch to dark theme
    find('.theme-toggle').click
    expect(page).to have_css('body.theme-dark')
    
    # Check persistence after page reload
    visit current_path
    expect(page).to have_css('body.theme-dark')
    
    # Switch back to light theme
    find('.theme-toggle').click
    expect(page).to have_css('body.theme-light')
  end

  scenario 'User switches between English and Russian' do
    visit root_path
    
    # Default language (English)
    expect(page).to have_content('Chats')
    
    # Switch to Russian
    find('.language-toggle').click
    find('a', text: 'Русский').click
    
    # Check Russian content
    expect(page).to have_content('Чаты')
    
    # Check persistence after page reload
    visit current_path
    expect(page).to have_content('Чаты')
    
    # Switch back to English
    find('.language-toggle').click
    find('a', text: 'English').click
    expect(page).to have_content('Chats')
  end

  scenario 'Mobile menu works correctly' do
    # Set mobile viewport
    page.driver.browser.manage.window.resize_to(375, 812)
    
    visit root_path
    
    # Menu should be hidden initially
    expect(page).not_to have_css('.mobile-menu--open')
    
    # Open menu
    find('.mobile-menu-button').click
    expect(page).to have_css('.mobile-menu--open')
    
    # Close menu
    find('.mobile-menu-close').click
    expect(page).not_to have_css('.mobile-menu--open')
  end
end
