class Message < ApplicationRecord
  # Constants
  MAX_CONTENT_LENGTH = 10_000
  
  # Associations
  belongs_to :chat, counter_cache: true
  belongs_to :user
  has_many :unread_messages, dependent: :destroy
  
  # Validations
  validates :content, presence: true, length: { maximum: MAX_CONTENT_LENGTH }
  validates :message_type, presence: true, inclusion: { in: %w[text markdown code] }
  validates :chat_id, :user_id, presence: true
  validate :user_is_chat_participant
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :before, ->(message) { where('created_at < ?', message.created_at).recent }
  scope :after, ->(message) { where('created_at > ?', message.created_at).recent(:asc) }
  scope :in_chat, ->(chat_id) { where(chat_id: chat_id) }
  scope :from_user, ->(user_id) { where(user_id: user_id) }
  scope :unread_by, ->(user) { 
    joins('LEFT JOIN unread_messages ON unread_messages.message_id = messages.id')
      .where('unread_messages.user_id = ?', user.id)
  }
  
  # Callbacks
  after_create :update_chat_last_message
  after_create :create_unread_messages
  after_update :broadcast_update
  after_destroy :broadcast_destroy
  
  # Instance methods
  def mark_as_read_by(user)
    unread_messages.find_by(user: user)&.destroy
  end
  
  def read_by?(user)
    !unread_messages.exists?(user: user)
  end
  
  def edited?
    updated_at > created_at + 1.second
  end
  
  def can_be_edited_by?(user)
    user_id == user.id && created_at > 15.minutes.ago
  end
  
  def can_be_deleted_by?(user)
    user_id == user.id || chat.admins.include?(user)
  end
  
  def broadcast
    ActionCable.server.broadcast(
      "chat_#{chat_id}",
      action: 'new_message',
      message: as_json(include: { user: { only: [:id, :username, :avatar_url] } })
    )
  end
  
  private
  
  def user_is_chat_participant
    return if chat.nil? || user.nil?
    
    unless chat.users.include?(user)
      errors.add(:user, 'must be a participant in the chat')
    end
  end
  
  def update_chat_last_message
    chat.update_last_message(self)
  end
  
  def create_unread_messages
    # Create unread message entries for all chat participants except the sender
    chat.users.where.not(id: user_id).find_each do |participant|
      unread_messages.create!(user: participant, chat: chat)
    end
  end
  
  def broadcast_update
    ActionCable.server.broadcast(
      "chat_#{chat_id}",
      action: 'update_message',
      message: as_json(include: { user: { only: [:id, :username, :avatar_url] } })
    )
  end
  
  def broadcast_destroy
    ActionCable.server.broadcast(
      "chat_#{chat_id}",
      action: 'delete_message',
      message_id: id
    )
  end
end
