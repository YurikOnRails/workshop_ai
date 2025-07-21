class ApplicationController < ActionController::Base
  include UserActivityTracking
  
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  helper_method :current_user, :user_signed_in?
  
  private
  
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id].present?
  end
  
  def user_signed_in?
    current_user.present?
  end
  
  def authenticate_user!
    return if user_signed_in?
    
    session[:return_to] = request.original_url if request.get?
    redirect_to root_path, alert: 'Please sign in to continue.'
  end
end
