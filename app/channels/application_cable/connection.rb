module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # This is a simplified version. In a real app, you would verify the user's token here.
      # For testing purposes, we'll just use the first user.
      User.first || reject_unauthorized_connection
    end
  end
end
