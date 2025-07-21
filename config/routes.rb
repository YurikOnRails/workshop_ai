Rails.application.routes.draw do
  # Health check route
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication routes
  get "/auth/:provider/callback", to: "sessions#create"
  get "/auth/failure", to: "sessions#failure"
  delete "/signout", to: "sessions#destroy", as: :signout
  get "/login", to: redirect("/auth/github"), as: :login

  # Resource routes
  resources :chats, only: [ :index, :show, :new, :create ] do
    resources :messages, only: [ :create ]
    member do
      post :add_participant
      post :remove_participant
      post :leave
      post :promote_admin
      post :demote_admin
    end
  end

  resources :profiles, only: [ :show ]

  # API namespace for AJAX requests
  namespace :api do
    namespace :v1 do
      resources :chats, only: [] do
        member do
          post :typing
          post :mark_read
        end
      end
      resources :messages, only: [] do
        member do
          post :react
        end
      end
    end
  end

  # ActionCable for WebSockets
  mount ActionCable.server => "/cable"

  # Root route - redirects to chats#index if authenticated, otherwise to login
  root to: "home#index"

  # Catch-all route for client-side routing (for SPA-like behavior)
  get "*path", to: "home#index", constraints: ->(request) do
    !request.xhr? && request.format.html?
  end
end
