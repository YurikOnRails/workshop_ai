# frozen_string_literal: true

class SyncUserRepositoriesJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    begin
      # Update the sync status
      user.update!(repositories_synced_at: Time.current, sync_in_progress: true)

      # Initialize the service and sync repositories
      service = GithubOauthService.new(nil, user.github_token)
      service.sync_user_repositories(user)

      # Update the sync status
      user.update!(
        repositories_synced_at: Time.current,
        sync_in_progress: false,
        last_sync_error: nil
      )
    rescue StandardError => e
      # Log the error and update the user's sync status
      Rails.logger.error "Failed to sync repositories for user #{user_id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      user.update!(
        sync_in_progress: false,
        last_sync_error: e.message
      )

      # Re-raise the error for Airbrake/error tracking
      raise
    end
  end
end
