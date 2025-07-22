# frozen_string_literal: true

class GithubOauthService
  class Error < StandardError; end
  class AuthenticationError < Error; end
  class InvalidTokenError < Error; end

  def initialize(auth_hash = nil, access_token = nil)
    @auth_hash = auth_hash
    @access_token = access_token || auth_hash&.dig("credentials", "token")
    @client = Octokit::Client.new(access_token: @access_token) if @access_token
  end

  def authenticate_user
    raise AuthenticationError, "Authentication hash is missing" unless @auth_hash

    user_info = @auth_hash["info"]
    uid = @auth_hash["uid"]

    # Find or create user
    user = User.find_or_initialize_by(github_uid: uid)

    # Update user attributes
    user.assign_attributes(
      email: user_info["email"],
      username: user_info["nickname"],
      name: user_info["name"],
      avatar_url: user_info["image"],
      github_token: @access_token,
      github_token_expires_at: token_expires_at,
      last_login_at: Time.current
    )

    # Save user and update repositories in background
    if user.save
      # Update repositories in background
      SyncUserRepositoriesJob.perform_later(user.id)
      user
    else
      raise AuthenticationError, user.errors.full_messages.join(", ")
    end
  end

  def sync_user_repositories(user)
    raise InvalidTokenError, "Access token is missing" unless @client

    # Get user's repositories with pagination
    repos = []
    page = 1

    loop do
      batch = @client.repos(nil, page: page, per_page: 100, type: "owner", sort: "updated")
      break if batch.empty?

      repos += batch
      page += 1
    end

    # Process repositories in batches
    repos.each_slice(100) do |batch|
      process_repositories_batch(user, batch)
    end

    # Remove repositories that are no longer accessible
    existing_repo_ids = repos.map(&:id).map(&:to_s)
    user.repositories.where.not(github_repo_id: existing_repo_ids).destroy_all

    true
  rescue Octokit::Unauthorized, Octokit::Forbidden => e
    Rails.logger.error "GitHub API Error: #{e.message}"
    raise InvalidTokenError, "Invalid or expired GitHub token"
  rescue Octokit::TooManyRequests => e
    Rails.logger.error "GitHub Rate Limit Exceeded: #{e.message}"
    raise Error, "GitHub API rate limit exceeded. Please try again later."
  rescue Octokit::Error => e
    Rails.logger.error "GitHub API Error: #{e.message}"
    raise Error, "Failed to sync repositories from GitHub. Please try again later."
  end

  private

  def token_expires_at
    return unless @auth_hash.dig("credentials", "expires_at")
    Time.at(@auth_hash["credentials"]["expires_at"])
  end

  def process_repositories_batch(user, repos_batch)
    repos_batch.each do |repo_data|
      # Skip if repository is not private
      next unless repo_data.private

      # Find or create repository
      repository = Repository.find_or_initialize_by(github_repo_id: repo_data.id.to_s)

      repository.assign_attributes(
        name: repo_data.name,
        full_name: repo_data.full_name,
        private: repo_data.private,
        html_url: repo_data.html_url,
        description: repo_data.description,
        language: repo_data.language,
        stargazers_count: repo_data.stargazers_count,
        forks_count: repo_data.forks_count,
        open_issues_count: repo_data.open_issues_count,
        default_branch: repo_data.default_branch,
        github_created_at: repo_data.created_at,
        github_updated_at: repo_data.updated_at,
        github_pushed_at: repo_data.pushed_at
      )

      repository.save! if repository.changed?

      # Add user to repository with appropriate permissions
      user_repo = user.user_repositories.find_or_initialize_by(repository: repository)
      user_repo.admin = repo_data.permissions&.admin || false
      user_repo.push = repo_data.permissions&.push || false
      user_repo.pull = repo_data.permissions&.pull || false
      user_repo.last_synced_at = Time.current
      user_repo.save! if user_repo.changed?
    end
  end
end
