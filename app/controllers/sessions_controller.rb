# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :authenticate_user!
  
  def create
    auth = request.env['omniauth.auth']
    
    # Find or create the user
    user = User.find_or_initialize_by(github_id: auth.uid)
    user.update!(
      username: auth.info.nickname,
      email: auth.info.email,
      name: auth.info.name,
      avatar_url: auth.info.image,
      github_token: auth.credentials.token,
      github_created_at: Time.current
    )
    
    # Sync user repositories in the background
    SyncUserRepositoriesJob.perform_later(user.id)
    
    # Sign in the user
    session[:user_id] = user.id
    
    # Redirect to the stored location or root
    redirect_to session[:return_to] || root_path, notice: 'Signed in successfully.'
  end
  
  def failure
    redirect_to root_path, alert: "Authentication failed: #{params[:message]}"
  end
  
  def destroy
    reset_session
    redirect_to root_path, notice: 'Signed out successfully.'
  end
end
