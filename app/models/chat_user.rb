class ChatUser < ApplicationRecord
  # Explicitly define the attribute to ensure it's recognized
  attribute :last_read_message_id, :integer, default: 0

  # Associations
  belongs_to :chat, touch: true
  belongs_to :user
  belongs_to :added_by, class_name: "User", optional: true

  # Validations
  validates :chat_id, uniqueness: { scope: :user_id, message: "user is already a participant in this chat" }
  validates :joined_at, presence: true
  validate :validate_direct_chat_participants

  # Scopes
  scope :active, -> { where(left_at: nil) }
  scope :inactive, -> { where.not(left_at: nil) }
  scope :muted, -> { where(muted: true) }
  scope :admins, -> { where(admin: true) }
  scope :recently_joined, -> { order(joined_at: :desc) }

  # Callbacks
  before_validation :set_joined_at, on: :create
  after_commit :notify_participants, on: :create

  # Instance methods
  def leave
    update(left_at: Time.current)
    chat.update_last_message(nil) if chat.chat_users.active.empty?
  end

  def mute
    update(muted: true)
  end

  def unmute
    update(muted: false)
  end

  def make_admin
    update(admin: true)
  end

  def revoke_admin
    update(admin: false)
  end

  def active?
    left_at.nil?
  end

  def mark_as_read(message = nil)
    if message
      update(last_read_at: Time.current, last_read_message_id: message.id)
    else
      update(last_read_at: Time.current)
    end
  end

  def unread_messages_count
    return 0 unless chat.last_message_id
    return 0 if last_read_at.nil? || chat.last_message_at.nil?

    chat.messages
        .where("created_at > ?", last_read_at)
        .where.not(user_id: user_id)
        .count
  end

  private

  def set_joined_at
    self.joined_at ||= Time.current
  end

  def validate_direct_chat_participants
    return unless chat&.direct_chat?

    if chat.chat_users.active.where.not(id: id).count >= 2
      errors.add(:base, "Direct chat cannot have more than 2 participants")
    end
  end

  def notify_participants
    # This will be implemented when we have the notification system
    # Notify other participants that a new user has joined the chat
  end
end
