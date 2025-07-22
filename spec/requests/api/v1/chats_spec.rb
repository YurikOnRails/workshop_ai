require 'rails_helper'

RSpec.describe 'API::V1::Chats', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:repository) { create(:repository) }
  let!(:chat) { create(:chat, chat_type: 'group', repository: repository) }
  let!(:chat_user) { create(:chat_user, chat: chat, user: user) }
  let!(:other_chat_user) { create(:chat_user, chat: chat, user: other_user) }
  let!(:message) { create(:message, chat: chat, user: user, content: 'Test message') }

  let(:headers) { { 'Accept' => 'application/json' } }
  let(:auth_headers) { Devise::JWT::TestHelpers.auth_headers(headers, user) }

  describe 'GET /api/v1/chats' do
    it 'returns a list of user chats' do
      get '/api/v1/chats', headers: auth_headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)

      expect(json).to be_an(Array)
      expect(json.first.keys).to match_array(%w[
        id chat_type repository_id participants unread_count last_message
      ])

      # Check participants data
      participants = json.first['participants']
      expect(participants).to be_an(Array)
      expect(participants.first.keys).to match_array(%w[id username avatar_url online])

      # Check last message data
      last_msg = json.first['last_message']
      expect(last_msg).to include('id', 'content', 'created_at', 'user')
    end
  end

  describe 'GET /api/v1/chats/:id' do
    it 'returns chat details' do
      get "/api/v1/chats/#{chat.id}", headers: auth_headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)

      expect(json).to include(
        'id' => chat.id,
        'chat_type' => chat.chat_type,
        'repository_id' => repository.id
      )

      expect(json['participants']).to be_an(Array)
      expect(json['participants'].size).to eq(2)

      expect(json['messages']).to be_an(Array)
      expect(json['messages'].first).to include(
        'id' => message.id,
        'content' => message.content,
        'user' => { 'id' => user.id, 'username' => user.username, 'avatar_url' => user.avatar_url }
      )
    end

    it 'returns 404 for non-existent chat' do
      get '/api/v1/chats/999999', headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 403 for unauthorized access' do
      unauthorized_user = create(:user)
      unauthorized_headers = Devise::JWT::TestHelpers.auth_headers(headers, unauthorized_user)

      get "/api/v1/chats/#{chat.id}", headers: unauthorized_headers
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/v1/chats/:id/leave' do
    it 'removes user from chat participants' do
      expect {
        post "/api/v1/chats/#{chat.id}/leave", headers: auth_headers
      }.to change { chat.chat_users.active.count }.by(-1)

      expect(response).to have_http_status(:no_content)
      expect(chat.chat_users.active.where(user_id: user.id)).not_to exist
    end

    it 'returns 404 for non-existent chat' do
      post '/api/v1/chats/999999/leave', headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /api/v1/chats/:chat_id/messages' do
    before do
      # Create more messages for pagination
      5.times { create(:message, chat: chat, user: user) }
    end

    it 'returns paginated messages' do
      get "/api/v1/chats/#{chat.id}/messages?limit=3", headers: auth_headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)

      expect(json).to be_an(Array)
      expect(json.size).to eq(3)

      # Test pagination with before parameter
      last_id = json.last['id']
      get "/api/v1/chats/#{chat.id}/messages?before=#{last_id}&limit=3", headers: auth_headers

      json = JSON.parse(response.body)
      expect(json.size).to be > 0
      expect(json.first['id']).to be < last_id
    end
  end

  describe 'POST /api/v1/chats/:chat_id/messages' do
    let(:message_params) { { content: 'New test message' } }

    it 'creates a new message' do
      expect {
        post "/api/v1/chats/#{chat.id}/messages",
          params: { message: message_params },
          headers: auth_headers
      }.to change { chat.messages.count }.by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json).to include(
        'content' => message_params[:content],
        'user' => { 'id' => user.id, 'username' => user.username }
      )
    end

    it 'returns 422 for invalid message' do
      post "/api/v1/chats/#{chat.id}/messages",
        params: { message: { content: '' } },
        headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST /api/v1/chats/:chat_id/messages/read' do
    it 'marks messages as read' do
      # Create some unread messages
      unread_messages = 3.times.map { create(:message, chat: chat, user: other_user) }

      post "/api/v1/chats/#{chat.id}/messages/read",
        headers: auth_headers,
        params: { last_read_message_id: unread_messages.last.id }

      expect(response).to have_http_status(:ok)

      # Verify unread messages were marked as read
      chat_user.reload
      expect(chat_user.last_read_message_id).to eq(unread_messages.last.id)
    end
  end
end
