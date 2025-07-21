module Api
  module V1
    class ChatsController < BaseController
      before_action :set_chat, only: [:show, :leave, :typing, :mark_read]
      before_action :check_participation, only: [:show, :typing, :mark_read]
      
      # GET /api/v1/chats
      def index
        @chats = current_user.chats.includes(:users, :last_message, :repository)
        render json: @chats, include: {
          participants: { only: [:id, :username, :avatar_url, :online] },
          last_message: { only: [:id, :content, :created_at], include: { user: { only: [:id, :username] } }
        }
      end
      
      # GET /api/v1/chats/:id
      def show
        @messages = @chat.messages
                        .includes(:user)
                        .order(created_at: :desc)
                        .limit(30)
                        .reverse
                        
        render json: {
          id: @chat.id,
          chat_type: @chat.chat_type,
          repository_id: @chat.repository_id,
          participants: @chat.users.as_json(only: [:id, :username, :avatar_url, :online]),
          messages: @messages.as_json(include: { user: { only: [:id, :username, :avatar_url] } })
        }
      end
      
      # POST /api/v1/chats/:id/leave
      def leave
        chat_user = @chat.chat_users.find_by!(user: current_user)
        chat_user.update!(left_at: Time.current)
        
        # Update participants count
        @chat.update_participants_count
        
        head :no_content
      end
      
      # POST /api/v1/chats/:id/typing
      def typing
        # Broadcast typing status to other participants
        broadcast_typing_status(is_typing: true)
        
        # Schedule a job to stop typing after 3 seconds
        TypingStatusWorker.perform_in(3.seconds, @chat.id, current_user.id, false)
        
        head :ok
      end
      
      # POST /api/v1/chats/:id/mark_read
      def mark_read
        last_message = @chat.messages.order(created_at: :desc).first
        return head :ok unless last_message
        
        chat_user = @chat.chat_users.find_by!(user: current_user)
        chat_user.update!(last_read_message: last_message)
        
        head :ok
      end
      
      private
      
      def set_chat
        @chat = Chat.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Chat not found' }, status: :not_found
      end
      
      def check_participation
        return if @chat.users.include?(current_user)
        render json: { error: 'Access denied' }, status: :forbidden
      end
      
      def broadcast_typing_status(is_typing:)
        ActionCable.server.broadcast(
          "chat_#{@chat.id}",
          type: 'typing',
          user_id: current_user.id,
          typing: is_typing
        )
      end
    end
  end
end
