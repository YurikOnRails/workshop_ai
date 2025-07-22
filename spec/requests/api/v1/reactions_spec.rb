require 'rails_helper'

RSpec.describe 'API::V1::Reactions', type: :request do
  let(:user) { create(:user) }
  let(:chat) { create(:chat, chat_type: 'group') }
  let!(:chat_user) { create(:chat_user, chat: chat, user: user) }
  let!(:message) { create(:message, chat: chat, user: user) }
  let(:headers) { { 'Accept' => 'application/json' } }
  let(:auth_headers) { Devise::JWT::TestHelpers.auth_headers(headers, user) }

  describe 'POST /api/v1/messages/:id/react' do
    it 'adds a reaction to a message' do
      expect {
        post "/api/v1/messages/#{message.id}/react",
             params: { emoji: '👍' },
             headers: auth_headers
      }.to change { message.reactions.count }.by(1)

      expect(response).to have_http_status(:ok)
      expect(json_response).to include(
        'emoji' => '👍',
        'user_id' => user.id,
        'message_id' => message.id
      )
    end

    it 'removes reaction when same emoji is sent again' do
      create(:reaction, message: message, user: user, emoji: '👍')

      expect {
        post "/api/v1/messages/#{message.id}/react",
             params: { emoji: '👍' },
             headers: auth_headers
      }.to change { message.reactions.count }.by(-1)

      expect(response).to have_http_status(:ok)
      expect(json_response).to include('removed' => true)
    end

    it 'returns 404 for non-existent message' do
      post "/api/v1/messages/999999/react",
           params: { emoji: '👍' },
           headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /api/v1/messages/:id/reactions' do
    before do
      create_list(:reaction, 3, message: message, emoji: '👍')
      create_list(:reaction, 2, message: message, emoji: '❤️')
    end

    it 'returns reactions summary for a message' do
      get "/api/v1/messages/#{message.id}/reactions",
          headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json_response).to contain_exactly(
        { 'emoji' => '👍', 'count' => 3, 'reacted' => false },
        { 'emoji' => '❤️', 'count' => 2, 'reacted' => false }
      )
    end

    it 'marks reactions made by current user' do
      create(:reaction, message: message, user: user, emoji: '👍')

      get "/api/v1/messages/#{message.id}/reactions",
          headers: auth_headers

      expect(json_response).to include(
        { 'emoji' => '👍', 'count' => 4, 'reacted' => true }
      )
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
