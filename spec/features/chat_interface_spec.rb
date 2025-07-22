require 'rails_helper'

RSpec.feature 'Chat Interface', type: :feature, js: true do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:chat) { create(:chat, chat_type: 'group') }

  before do
    create(:chat_user, chat: chat, user: user)
    create(:chat_user, chat: chat, user: other_user)
    login_as(user, scope: :user)
  end

  scenario 'User sends and views messages' do
    visit chat_path(chat)

    # Check if chat is loaded
    expect(page).to have_content('Chat ##{chat.id}')

    # Send a message
    fill_in 'message_content', with: 'Hello, this is a test message'
    click_button 'Send'

    # Check if message appears
    expect(page).to have_content('Hello, this is a test message')
    expect(page).to have_content(user.username)

    # Check message timestamp
    expect(page).to have_css('.message-time', text: Time.current.strftime('%H:%M'))
  end

  scenario 'User sees online status' do
    other_user.update(online: true)
    visit chat_path(chat)

    within('.participants-list') do
      expect(page).to have_content('Online')
    end
  end

  scenario 'User leaves a group chat' do
    visit chat_path(chat)

    # Click leave button and confirm in the modal
    accept_confirm do
      click_link 'Leave Chat'
    end

    # Should be redirected to chats list
    expect(page).to have_current_path(chats_path)
    expect(page).to have_content('You have left the chat')
  end

  scenario 'User sees unread message count' do
    # Create unread message
    create(:message, chat: chat, user: other_user, content: 'Unread message')

    visit chats_path

    # Should show unread count
    expect(page).to have_css('.unread-count', text: '1')
  end
end
