module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_user!
      before_action :set_default_format
      
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActionController::ParameterMissing, with: :bad_request
      
      private
      
      def authenticate_user!
        return if current_user
        
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
      
      def current_user
        @current_user ||= begin
          header = request.headers['Authorization']
          token = header&.split(' ')&.last
          
          if token
            decoded = JWT.decode(token, Rails.application.credentials.secret_key_base).first
            User.find(decoded['sub'])
          end
        rescue JWT::DecodeError, ActiveRecord::RecordNotFound
          nil
        end
      end
      
      def set_default_format
        request.format = :json
      end
      
      def not_found
        render json: { error: 'Not Found' }, status: :not_found
      end
      
      def bad_request(exception)
        render json: { error: exception.message }, status: :bad_request
      end
    end
  end
end
