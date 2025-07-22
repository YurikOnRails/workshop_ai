module Api
  module V1
    class MessagesController < BaseController
      before_action :set_chat
      before_action :check_participation

      # GET /api/v1/chats/:chat_id/messages
      def index
        messages = @chat.messages
                      .includes(:user)
                      .order(created_at: :desc)

        # Pagination with before parameter
        messages = messages.where("id < ?", params[:before]) if params[:before].present?

        # Limit number of messages per page (default: 30)
        limit = [ params[:limit]&.to_i || 30, 100 ].min
        messages = messages.limit(limit)

        render json: messages, include: { user: { only: [ :id, :username, :avatar_url ] } }
      end

      # POST /api/v1/chats/:chat_id/messages
      def create
        @message = @chat.messages.build(message_params)
        @message.user = current_user

        if @message.save
          # Update chat's last message timestamp
          @chat.update_last_message(@message)

          # Create unread messages for all participants except sender
          @chat.create_unread_messages_for_all_except(current_user, @message)

          # Broadcast new message to chat channel
          broadcast_message(@message)

          render json: @message,
                 status: :created,
                 include: { user: { only: [ :id, :username, :avatar_url ] } }
        else
          render json: { errors: @message.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      # POST /api/v1/chats/:chat_id/messages/read
      def read
        chat_user = @chat.chat_users.find_by!(user: current_user)

        if params[:last_read_message_id].present?
          last_message = @chat.messages.find(params[:last_read_message_id])
          chat_user.update!(last_read_message: last_message)
        end

        # Clear unread messages count
        @chat.unread_messages.where(user: current_user).delete_all

        head :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Message not found" }, status: :not_found
      end

      private

      def set_chat
        @chat = Chat.find(params[:chat_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Chat not found" }, status: :not_found
      end

      def check_participation
        return if @chat.users.include?(current_user)
        render json: { error: "Access denied" }, status: :forbidden
      end

      def message_params
        params.require(:message).permit(:content)
      end

      def broadcast_message(message)
        ActionCable.server.broadcast(
          "chat_#{@chat.id}",
          type: "new_message",
          message: message.as_json(include: { user: { only: [ :id, :username, :avatar_url ] } })
        )
      end
    end
  end
end
