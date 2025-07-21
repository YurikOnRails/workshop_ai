# frozen_string_literal: true

class AuthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:github, :callback, :failure, :sign_out]
  
  def github
    # Store the return_to URL in the session if provided
    session[:return_to] = params[:return_to] if params[:return_to].present?
    
    # Redirect to GitHub for authentication
    redirect_to '/auth/github', allow_other_host: true
  end
  
  def callback
    # Authenticate the user with GitHub
    service = GithubOauthService.new(request.env['omniauth.auth'])
    user = service.authenticate_user
    
    # Sign in the user
    sign_in(user)
    
    # Redirect to the stored URL or root path
    redirect_to after_sign_in_path_for(user), notice: 'Successfully signed in with GitHub!'
  rescue GithubOauthService::AuthenticationError => e
    redirect_to root_path, alert: "Authentication failed: #{e.message}"
  end
  
  def failure
    error_message = params[:message] || 'unknown_error'
    error_description = params[:error_description] || 'An unknown error occurred during authentication.'
    
    Rails.logger.error "OAuth Error: #{error_message} - #{error_description}"
    
    case error_message
    when 'invalid_credentials'
      alert_message = 'Invalid GitHub credentials. Please try again.'
    when 'service_unavailable'
      alert_message = 'GitHub service is currently unavailable. Please try again later.'
    else
      alert_message = "Authentication failed: #{error_description}"
    end
    
    redirect_to root_path, alert: alert_message
  end
  
  def sign_out
    # Clear the session and sign out the user
    reset_session
    redirect_to root_path, notice: 'Successfully signed out.'
  end
  
  private
  
  def after_sign_in_path_for(resource)
    # Redirect to the stored URL or the repositories path
    stored_location = session.delete(:return_to)
    stored_location || repositories_path
  end
end
