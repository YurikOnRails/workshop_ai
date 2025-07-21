# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github,
           ENV.fetch("GITHUB_CLIENT_ID", nil),
           ENV.fetch("GITHUB_CLIENT_SECRET", nil),
           scope: "user:email,repo",
           callback_path: "/auth/github/callback"
end

# Configure OmniAuth to use Rails' CSRF protection
OmniAuth.config.allowed_request_methods = [ :post, :get ]
OmniAuth.config.silence_get_warning = true
OmniAuth.config.full_host = ENV.fetch("APP_HOST", "http://localhost:3000")

# Handle authentication failures
OmniAuth.config.on_failure = proc do |env|
  message_key = env["omniauth.error.type"]
  error_description = Rack::Utils.escape(env["omniauth.error"].message) rescue ""

  redirect_path = if env["omniauth.origin"]
                    "#{env['omniauth.origin']}?error=#{message_key}&error_description=#{error_description}"
  else
                    "/auth/failure?message=#{message_key}&error=#{error_description}"
  end

  [ 302, { "Location" => redirect_path, "Content-Type" => "text/html" }, [] ]
end
