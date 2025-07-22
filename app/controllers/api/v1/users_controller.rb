module Api
  module V1
    class UsersController < BaseController
      before_action :set_user, only: [ :show ]

      # GET /api/v1/users
      def index
        @users = User.all
        render json: @users, only: [ :id, :username, :avatar_url, :online ]
      end

      # GET /api/v1/users/:id
      def show
        render json: @user, only: [
          :id, :username, :email, :avatar_url,
          :private_repos_count, :stars_count, :private_stars_count
        ]
      end

      # GET /api/v1/me
      def me
        render json: current_user, only: [
          :id, :username, :email, :avatar_url,
          :private_repos_count, :stars_count, :private_stars_count
        ]
      end

      # POST /api/v1/me/online
      def online
        current_user.update!(online: true)
        broadcast_user_status
        head :ok
      end

      # POST /api/v1/me/offline
      def offline
        current_user.update!(
          online: false,
          last_seen_at: Time.current
        )
        broadcast_user_status
        head :ok
      end

      private

      def set_user
        @user = User.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "User not found" }, status: :not_found
      end

      def broadcast_user_status
        ActionCable.server.broadcast(
          "user_status_#{current_user.id}",
          user_id: current_user.id,
          online: current_user.online?,
          last_seen_at: current_user.last_seen_at
        )
      end
    end
  end
end
