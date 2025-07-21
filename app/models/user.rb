class User < ApplicationRecord
  include OnlineStatus
  
  # Associations
  has_many :user_repositories, dependent: :destroy
  has_many :repositories, through: :user_repositories
  has_many :chat_users, dependent: :destroy
  has_many :chats, through: :chat_users
  has_many :messages, dependent: :destroy
  has_many :unread_messages, dependent: :destroy
  
  # Track online status
  attribute :online, :boolean, default: false

  # Validations
  validates :github_id, presence: true, uniqueness: true, numericality: { only_integer: true, greater_than: 0 }
  validates :username, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_-]+\z/i, message: 'can only contain letters, numbers, underscores and hyphens' }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :avatar_url, format: { with: /\Ahttps?:\/\//, message: 'must be a valid URL' }, allow_blank: true
  validates :public_repos, :total_private_repos, :owned_private_repos, 
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }, 
            allow_nil: true
  validates :github_created_at, presence: true

  # Scopes
  scope :online, -> { where(online: true) }
  scope :by_username, ->(username) { where('username ILIKE ?', "%#{username}%") }

  # Callbacks
  before_validation :set_defaults, on: :create

  # Instance methods
  def update_online_status(online_status)
    update(online: online_status, last_seen_at: Time.current)
  end

  def display_name
    name.presence || username
  end

  def admin_for?(repository)
    user_repositories.find_by(repository: repository)&.admin?
  end

  def can_access_repository?(repository)
    repositories.include?(repository)
  end

  private

  def set_defaults
    self.public_repos ||= 0
    self.total_private_repos ||= 0
    self.owned_private_repos ||= 0
    self.stars_count ||= 0
    self.online ||= false
    self.github_created_at ||= Time.current
  end
end
