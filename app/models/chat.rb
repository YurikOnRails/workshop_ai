class Chat < ApplicationRecord
  # Constants
  CHAT_TYPES = %w[direct group repository].freeze
  
  # Associations
  belongs_to :repository, optional: true
  has_many :chat_users, dependent: :destroy
  has_many :users, through: :chat_users
  has_many :messages, dependent: :destroy
  
  # Validations
  validates :chat_type, presence: true, inclusion: { in: CHAT_TYPES }
  validates :name, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }, allow_blank: true
  validates :repository_id, presence: { message: 'is required for repository chats' }, if: :repository_chat?
  validates :repository_id, absence: { message: 'must be blank for non-repository chats' }, unless: :repository_chat?
  validate :validate_chat_type_rules
  
  # Scopes
  scope :direct, -> { where(chat_type: 'direct') }
  scope :group, -> { where(chat_type: 'group') }
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
    return if users.include?(user)
    
    chat_users.create!(user: user) do |cu|
      cu.added_by = added_by if added_by
    end
  end
  
  def remove_participant(user)
    chat_users.find_by(user: user)&.destroy
  end
  
  def update_last_message(message)
    update(last_message_at: message.created_at, last_message_id: message.id)
  end
  
  def mark_as_read_for(user)
    chat_users.find_by(user: user)&.update(last_read_at: Time.current)
  end
  
  def unread_count_for(user)
    return 0 unless last_message_id
    
    last_read = chat_users.find_by(user: user)&.last_read_at
    return 0 unless last_read
    
    messages.where('created_at > ?', last_read).count
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
