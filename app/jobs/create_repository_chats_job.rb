# frozen_string_literal: true

class CreateRepositoryChatsJob < ApplicationJob
  queue_as :default
  
  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user
    
    # Get all repositories the user has access to
    user.repositories.each do |repository|
      # Skip if repository already has a chat
      next if repository.chats.exists?
      
      # Create a repository chat
      begin
        ChatService.create_chat(
          user,
          'repository',
          repository_id: repository.id,
          name: repository.full_name,
          description: "Chat for #{repository.full_name} repository"
        )
      rescue ChatService::Error => e
        Rails.logger.error "Failed to create chat for repository #{repository.id}: #{e.message}"
        next
      end
    end
    
    # Find direct chats to create
    create_direct_chats_for_user(user)
  end
  
  private
  
  def create_direct_chats_for_user(user)
    # Get all users that share repositories with this user
    shared_users = User.joins(:repositories)
                      .where(repositories: { id: user.repositories.pluck(:id) })
                      .where.not(id: user.id)
                      .distinct
    
    # Create direct chats with users who share repositories
    shared_users.each do |other_user|
      begin
        ChatService.find_or_create_direct_chat(user.id, other_user.id)
      rescue ChatService::Error => e
        Rails.logger.error "Failed to create direct chat between #{user.id} and #{other_user.id}: #{e.message}"
        next
      end
    end
  end
end
