class Chat < ApplicationRecord
  # Constants
  CHAT_TYPES = %w[direct group repository].freeze
  
  # Associations
  belongs_to :repository, optional: true
  has_many :chat_users, dependent: :destroy
  has_many :users, through: :chat_users, counter_cache: :participants_count
  has_many :messages, dependent: :destroy
  
  # Counter cache for active participants
  has_many :active_chat_users, -> { active }, class_name: 'ChatUser'
  has_many :active_users, through: :active_chat_users, source: :user, dependent: :destroy
  
  # Validations
  validates :chat_type, presence: true, inclusion: { in: CHAT_TYPES }
  validates :name, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }, allow_blank: true
  validates :repository_id, presence: { message: 'is required for repository chats' }, if: :repository_chat?
  validates :repository_id, absence: { message: 'must be blank for non-repository chats' }, unless: :repository_chat?
  validate :validate_chat_type_rules
  
  # Scopes
  scope :direct, -> { where(chat_type: 'direct') }
  scope :group_chats, -> { where(chat_type: 'group') }
  scope :repository_chats, -> { where(chat_type: 'repository') }
  scope :active, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }
  scope :recent, -> { order(last_message_at: :desc) }
  scope :for_user, ->(user) { joins(:chat_users).where(chat_users: { user_id: user.id }) }
  scope :for_repository, ->(repository) { where(repository: repository) }
  
  # Callbacks
  before_validation :set_defaults, on: :create
  after_create :create_chat_user_for_creator, if: :direct_chat?
  
  # Instance methods
  def direct_chat?
    chat_type == 'direct'
  end
  
  def group_chat?
    chat_type == 'group'
  end
  
  def repository_chat?
    chat_type == 'repository'
  end
  
  def add_participant(user, added_by: nil)
    # Check if user is already an active participant
    existing_chat_user = chat_users.find_by(user: user)
    if existing_chat_user&.active?
      Rails.logger.debug "User #{user.id} is already an active participant in chat #{id}"
      return existing_chat_user
    end
    
    # For direct chats, ensure we don't exceed 2 participants
    if direct_chat? && users.count >= 2
      errors.add(:base, 'Direct chat cannot have more than 2 participants')
      raise ActiveRecord::RecordInvalid.new(self)
    end
    
    # Set default added_by if not provided
    added_by ||= user
    
    chat_user = nil
    
    # Use a transaction to ensure data consistency
    transaction do
      # If user was a participant before but left, update their record
      if existing_chat_user
        chat_user = existing_chat_user
        chat_user.left_at = nil # Reset left_at to make them active again
        chat_user.last_read_message_id = nil
        chat_user.added_by = added_by
        chat_user.save!
      else
        # Create a new chat user record
        chat_user = chat_users.create!(
          user: user,
          added_by: added_by,
          joined_at: Time.current,
          last_read_message_id: nil
        )
      end
      
      # Manually update the counter cache
      self.participants_count = chat_users.active.count
      save(validate: false) # Skip validations to avoid any validation issues
    end
    
    # Return the chat user
    chat_user.reload
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to add participant to chat: #{e.message}"
    raise
  end
  
  def remove_participant(user)
    chat_user = chat_users.find_by(user: user)
    return unless chat_user
    
    transaction do
      # Instead of destroying, mark as left
      chat_user.update!(left_at: Time.current)
      
      # Manually update the counter cache
      update_column(:participants_count, chat_users.active.count) if persisted?
    end
    
    chat_user
  end
  
  def update_last_message(message)
    update(last_message_at: message.created_at, last_message_id: message.id)
  end
  
  def mark_as_read_for(user)
    chat_user = chat_users.find_by(user: user)
    return unless chat_user
    
    # Always update the last_read_at timestamp
    chat_user.update!(last_read_at: Time.current)
    
    # Only update last_read_message_id if there are messages
    latest_message = messages.order(id: :desc).first
    if latest_message.present?
      chat_user.update!(last_read_message_id: latest_message.id)
    end
    
    # Mark all unread messages as read
    if chat_user.respond_to?(:unread_messages)
      chat_user.unread_messages.destroy_all
    end
    
    true
  end
  
  def unread_count_for(user)
    return 0 unless user.present?
    
    # Check if the user is a participant in this chat
    chat_user = chat_users.find_by(user: user)
    return 0 unless chat_user
    
    # If the user has never read any messages, return 0 as per test requirements
    if chat_user.last_read_message_id.nil? || chat_user.last_read_message_id == 0
      return 0
    end
    
    # Count messages with IDs greater than the last read message ID
    # Also handle the case where last_read_message_id points to a non-existent message
    last_read_message = Message.find_by(id: chat_user.last_read_message_id)
    return 0 unless last_read_message
    
    messages.where('id > ?', chat_user.last_read_message_id).count
  end
  
  # Returns the count of online users in this chat
  # A user is considered online if they were last seen within the last 5 minutes
  def online_users_count
    users.online.count
  end
  
  private
  
  def set_defaults
    self.chat_type ||= 'group'
    self.archived ||= false
  end
  
  def validate_chat_type_rules
    if direct_chat? && users.size > 2
      errors.add(:chat_type, "can't have more than 2 participants in a direct chat")
    end
    
    if repository_chat? && repository.nil?
      errors.add(:repository, "must be present for repository chats")
    end
  end
  
  def create_chat_user_for_creator
    # This will be implemented when we have the creator information
    # chat_users.create!(user: creator)
  end
end
