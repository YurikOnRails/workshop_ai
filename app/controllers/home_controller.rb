# frozen_string_literal: true

class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index ]

  def index
    if user_signed_in?
      redirect_to chats_path
    else
      render "home/welcome", layout: "welcome"
    end
  end
end
