# frozen_string_literal: true

class ChatService
  class Error < StandardError; end
  class AuthorizationError < Error; end
  class ValidationError < Error; end
  
  # Creates a new chat with the given parameters
  # @param creator [User] The user creating the chat
  # @param chat_type [String] Type of chat ('direct', 'group', 'repository')
  # @param participant_ids [Array<Integer>] Array of user IDs to add to the chat
  # @param repository_id [Integer, nil] ID of the repository for repository chats
  # @param name [String] Name of the chat (required for group and repository chats)
  # @param description [String, nil] Optional description for the chat
  # @return [Chat] The created chat
  def self.create_chat(creator, chat_type, participant_ids: [], repository_id: nil, name: nil, description: nil)
    raise ValidationError, 'Creator is required' unless creator.is_a?(User)
    raise ValidationError, 'Invalid chat type' unless %w[direct group repository].include?(chat_type.to_s)
    
    # For direct chats, ensure exactly 2 participants (creator + 1 other)
    if chat_type == 'direct'
      raise ValidationError, 'Direct chat requires exactly one other participant' unless participant_ids.size == 1
      
      # Check if a direct chat already exists between these users
      existing_chat = find_direct_chat(creator.id, participant_ids.first)
      return existing_chat if existing_chat
      
      name ||= "#{creator.username} and #{User.find(participant_ids.first)&.username}"
    end
    
    # For repository chats, require repository_id
    if chat_type == 'repository'
      raise ValidationError, 'Repository ID is required for repository chats' unless repository_id.present?
      
      repository = Repository.find_by(id: repository_id)
      raise ValidationError, 'Repository not found' unless repository
      
      # Ensure creator has access to the repository
      unless creator.repositories.include?(repository)
        raise AuthorizationError, 'You do not have access to this repository'
      end
      
      name ||= repository.full_name
      
      # For repository chats, include all users with access to the repository
      participant_ids = repository.users.pluck(:id) - [creator.id]
    end
    
    # Ensure name is provided for group and repository chats
    if %w[group repository].include?(chat_type) && name.blank?
      raise ValidationError, 'Name is required for group and repository chats'
    end
    
    # Ensure participants exist
    participants = User.where(id: participant_ids).to_a
    missing_ids = participant_ids - participants.map(&:id)
    if missing_ids.any?
      raise ValidationError, "Users not found: #{missing_ids.join(', ')}"
    end
    
    # Create the chat in a transaction
    chat = nil
    
    Chat.transaction do
      # Create the chat
      chat = Chat.create!(
        chat_type: chat_type,
        name: name,
        description: description,
        repository_id: repository_id,
        created_by: creator.id
      )
      
      # Add creator as the first participant
      chat.chat_users.create!(
        user: creator,
        admin: true,
        added_by: creator
      )
      
      # Add other participants
      participants.each do |user|
        next if user.id == creator.id # Skip creator
        
        chat.chat_users.create!(
          user: user,
          admin: false,
          added_by: creator
        )
      end
      
      # Create welcome message for group/repository chats
      if %w[group repository].include?(chat_type)
        welcome_message = "Chat created by #{creator.username}."
        welcome_message += " This is a repository chat for #{repository.full_name}." if repository
        
        chat.messages.create!(
          user: creator,
          content: welcome_message,
          message_type: 'text'
        )
      end
    end
    
    chat
  rescue ActiveRecord::RecordInvalid => e
    raise ValidationError, e.record.errors.full_messages.join(', ')
  end
  
  # Adds participants to an existing chat
  # @param chat [Chat] The chat to add participants to
  # @param current_user [User] The user performing the action
  # @param user_ids [Array<Integer>] Array of user IDs to add to the chat
  # @return [Array<User>] Array of users that were added
  def self.add_participants(chat, current_user, user_ids)
    raise ValidationError, 'Chat is required' unless chat.is_a?(Chat)
    raise ValidationError, 'Current user is required' unless current_user.is_a?(User)
    
    # Check if current user is an admin in the chat
    unless chat.chat_users.find_by(user: current_user)&.admin?
      raise AuthorizationError, 'You do not have permission to add participants to this chat'
    end
    
    # Ensure user_ids is an array of integers
    user_ids = Array.wrap(user_ids).map(&:to_i).uniq
    
    # Find users that aren't already in the chat
    existing_user_ids = chat.users.pluck(:id)
    new_user_ids = user_ids - existing_user_ids
    
    # Ensure we have valid users to add
    users_to_add = User.where(id: new_user_ids).to_a
    missing_ids = new_user_ids - users_to_add.map(&:id)
    
    if missing_ids.any?
      raise ValidationError, "Users not found: #{missing_ids.join(', ')}"
    end
    
    # Add users to the chat
    added_users = []
    
    Chat.transaction do
      users_to_add.each do |user|
        chat_user = chat.chat_users.create!(
          user: user,
          added_by: current_user,
          admin: false
        )
        
        added_users << user
        
        # Notify chat about new participant
        chat.messages.create!(
          user: current_user,
          content: "#{current_user.username} added #{user.username} to the chat.",
          message_type: 'system'
        )
      end
    end
    
    added_users
  end
  
  # Removes a participant from a chat
  # @param chat [Chat] The chat to remove the participant from
  # @param current_user [User] The user performing the action
  # @param user_id [Integer] ID of the user to remove
  # @param reason [String, nil] Optional reason for removal
  # @return [Boolean] true if successful
  def self.remove_participant(chat, current_user, user_id, reason = nil)
    raise ValidationError, 'Chat is required' unless chat.is_a?(Chat)
    raise ValidationError, 'Current user is required' unless current_user.is_a?(User)
    
    # Find the chat user record
    chat_user = chat.chat_users.find_by(user_id: user_id)
    raise ValidationError, 'User is not a participant in this chat' unless chat_user
    
    # Check permissions
    unless current_user.id == user_id || chat.chat_users.find_by(user: current_user)&.admin?
      raise AuthorizationError, 'You do not have permission to remove this participant'
    end
    
    # Prevent removing the last admin
    if chat_user.admin? && chat.chat_users.where(admin: true).count == 1
      raise ValidationError, 'Cannot remove the last admin from the chat'
    end
    
    # Remove the participant
    Chat.transaction do
      # Create a system message
      message = if current_user.id == user_id
                  "#{current_user.username} left the chat."
                else
                  "#{current_user.username} removed #{chat_user.user.username} from the chat."
                end
      
      message += " Reason: #{reason}" if reason.present?
      
      chat.messages.create!(
        user: current_user,
        content: message,
        message_type: 'system'
      )
      
      # Mark as left instead of destroying to preserve message history
      chat_user.update!(left_at: Time.current)
    end
    
    true
  end
  
  # Promotes a participant to admin
  # @param chat [Chat] The chat
  # @param current_user [User] The user performing the action
  # @param user_id [Integer] ID of the user to promote
  # @return [ChatUser] The updated chat user record
  def self.promote_to_admin(chat, current_user, user_id)
    update_admin_status(chat, current_user, user_id, true)
  end
  
  # Demotes an admin to regular participant
  # @param chat [Chat] The chat
  # @param current_user [User] The user performing the action
  # @param user_id [Integer] ID of the user to demote
  # @return [ChatUser] The updated chat user record
  def self.demote_admin(chat, current_user, user_id)
    update_admin_status(chat, current_user, user_id, false)
  end
  
  # Finds or creates a direct chat between two users
  # @param user1_id [Integer] ID of the first user
  # @param user2_id [Integer] ID of the second user
  # @return [Chat, nil] The existing or newly created direct chat
  def self.find_or_create_direct_chat(user1_id, user2_id)
    # Find existing direct chat between these users
    chat = find_direct_chat(user1_id, user2_id)
    return chat if chat
    
    # Create a new direct chat
    user1 = User.find(user1_id)
    user2 = User.find(user2_id)
    
    create_chat(
      user1,
      'direct',
      participant_ids: [user2_id],
      name: "#{user1.username} and #{user2.username}"
    )
  end
  
  # Finds an existing direct chat between two users
  # @param user1_id [Integer] ID of the first user
  # @param user2_id [Integer] ID of the second user
  # @return [Chat, nil] The direct chat if found, nil otherwise
  def self.find_direct_chat(user1_id, user2_id)
    # Find chats where both users are participants and it's a direct chat
    Chat.direct
        .joins(:chat_users)
        .where(chat_users: { user_id: [user1_id, user2_id] })
        .group('chats.id')
        .having('COUNT(DISTINCT chat_users.user_id) = 2')
        .first
  end
  
  private
  
  # Updates the admin status of a chat participant
  def self.update_admin_status(chat, current_user, user_id, admin_status)
    raise ValidationError, 'Chat is required' unless chat.is_a?(Chat)
    raise ValidationError, 'Current user is required' unless current_user.is_a?(User)
    
    # Check if current user is an admin
    unless chat.chat_users.find_by(user: current_user)&.admin?
      raise AuthorizationError, 'You do not have permission to modify admin status'
    end
    
    # Find the chat user record
    chat_user = chat.chat_users.find_by(user_id: user_id)
    raise ValidationError, 'User is not a participant in this chat' unless chat_user
    
    # Prevent modifying your own admin status if you're the last admin
    if current_user.id == user_id && admin_status == false && chat.chat_users.where(admin: true).count == 1
      raise ValidationError, 'You cannot remove yourself as the last admin'
    end
    
    # Update admin status
    chat_user.update!(admin: admin_status)
    
    # Create a system message
    action = admin_status ? 'promoted to admin' : 'demoted from admin'
    chat.messages.create!(
      user: current_user,
      content: "#{current_user.username} #{chat_user.user.username} #{action}.",
      message_type: 'system'
    )
    
    chat_user
  end
end
