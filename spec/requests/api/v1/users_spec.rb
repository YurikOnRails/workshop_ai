require 'rails_helper'

RSpec.describe 'API::V1::Users', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:headers) { { 'Accept' => 'application/json' } }
  let(:auth_headers) { Devise::JWT::TestHelpers.auth_headers(headers, user) }

  before do
    # Create some test data
    create_list(:user, 3)
  end

  describe 'GET /api/v1/users' do
    it 'returns a list of users with basic info' do
      get '/api/v1/users', headers: auth_headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)

      # Check the response structure
      expect(json).to be_an(Array)
      expect(json.first.keys).to match_array(%w[id username avatar_url online])

      # Check if all users are included
      expect(json.size).to eq(User.count)
    end
  end

  describe 'GET /api/v1/users/:id' do
    it 'returns user profile details' do
      get "/api/v1/users/#{other_user.id}", headers: auth_headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)

      expect(json).to include(
        'id' => other_user.id,
        'username' => other_user.username,
        'email' => other_user.email,
        'avatar_url' => other_user.avatar_url,
        'private_repos_count' => other_user.private_repos_count,
        'stars_count' => other_user.stars_count,
        'private_stars_count' => other_user.private_stars_count
      )
    end

    it 'returns 404 for non-existent user' do
      get '/api/v1/users/999999', headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /api/v1/me' do
    it 'returns current user details' do
      get '/api/v1/me', headers: auth_headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)

      expect(json).to include(
        'id' => user.id,
        'username' => user.username,
        'email' => user.email,
        'avatar_url' => user.avatar_url,
        'private_repos_count' => user.private_repos_count,
        'stars_count' => user.stars_count,
        'private_stars_count' => user.private_stars_count
      )
    end

    it 'returns 401 for unauthenticated user' do
      get '/api/v1/me', headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
