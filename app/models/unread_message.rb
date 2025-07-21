class UnreadMessage < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :chat
  belongs_to :message

  # Validations
  validates :user_id, uniqueness: { scope: [ :chat_id, :message_id ], message: "already has this message marked as unread" }
  validate :message_belongs_to_chat

  # Scopes
  scope :for_user, ->(user) { where(user: user) }
  scope :for_chat, ->(chat) { where(chat: chat) }
  scope :newer_than, ->(message) { where("message_id > ?", message.id) }
  scope :older_than, ->(message) { where("message_id < ?", message.id) }
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }

  # Callbacks
  after_create :increment_unread_count
  after_destroy :decrement_unread_count

  # Class methods
  def self.mark_as_read(user, chat, message = nil)
    relation = where(user: user, chat: chat)

    if message
      # Mark all messages up to and including the specified message as read
      relation = relation.where("message_id <= ?", message.id)
    end

    # Update all matching records with the current time
    updated_count = relation.update_all(read_at: Time.current)

    # Update the chat's unread count for the user
    if updated_count > 0
      chat_user = ChatUser.find_by(chat: chat, user: user)
      chat_user&.update(last_read_at: Time.current)
    end

    updated_count
  end

  # Instance methods
  def mark_as_read
    return if read_at.present?

    update(read_at: Time.current)
    decrement_unread_count
  end

  def read?
    read_at.present?
  end

  def unread?
    !read?
  end

  private

  def message_belongs_to_chat
    return if message.blank? || chat.blank?

    unless message.chat_id == chat_id
      errors.add(:message, "must belong to the specified chat")
    end
  end

  def increment_unread_count
    chat_user = ChatUser.find_or_initialize_by(chat: chat, user: user)
    chat_user.increment!(:unread_count)
  end

  def decrement_unread_count
    chat_user = ChatUser.find_by(chat: chat, user: user)
    return unless chat_user

    chat_user.decrement!(:unread_count)
  end
end
