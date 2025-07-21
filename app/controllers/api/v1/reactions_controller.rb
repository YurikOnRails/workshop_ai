module Api
  module V1
    class ReactionsController < BaseController
      before_action :set_message
      before_action :check_message_access
      
      # POST /api/v1/messages/:message_id/react
      def react
        emoji = params.require(:emoji)
        reaction = @message.reactions.find_by(user: current_user, emoji: emoji)
        
        if reaction
          reaction.destroy
          render json: { removed: true }
        else
          reaction = @message.reactions.create!(user: current_user, emoji: emoji)
          render json: reaction, status: :created
        end
      end
      
      # GET /api/v1/messages/:message_id/reactions
      def index
        # Get all reactions for the message with counts
        reactions = @message.reactions
                          .group(:emoji)
                          .select('emoji, COUNT(*) as count')
                          .map do |r|
                            {
                              emoji: r.emoji,
                              count: r.count,
                              reacted: @message.reactions.where(user: current_user, emoji: r.emoji).exists?
                            }
                          end
        
        render json: reactions
      end
      
      private
      
      def set_message
        @message = Message.find(params[:message_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Message not found' }, status: :not_found
      end
      
      def check_message_access
        return if @message.chat.users.include?(current_user)
        render json: { error: 'Access denied' }, status: :forbidden
      end
    end
  end
end
