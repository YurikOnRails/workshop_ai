class Repository < ApplicationRecord
  # Associations
  has_many :user_repositories, dependent: :destroy
  has_many :users, through: :user_repositories
  has_many :chats, dependent: :destroy
  has_many :messages, through: :chats

  # Validations
  validates :github_repo_id, presence: true, uniqueness: true, numericality: { only_integer: true, greater_than: 0 }
  validates :name, presence: true, length: { maximum: 255 }
  validates :full_name, presence: true, length: { maximum: 255 }, uniqueness: true
  validates :private, inclusion: { in: [true, false] }
  validates :html_url, presence: true, format: { with: /\Ahttps?:\/\/github\.com\/.+\/.+\z/, message: 'must be a valid GitHub repository URL' }
  validates :description, length: { maximum: 1000 }, allow_blank: true
  validates :language, length: { maximum: 100 }, allow_blank: true
  validates :default_branch, presence: true, length: { maximum: 100 }
  
  # Scopes
  scope :private_repos, -> { where(private: true) }
  scope :public_repos, -> { where(private: false) }
  scope :by_name, ->(query) { where('name ILIKE ?', "%#{query}%") }
  scope :by_language, ->(language) { where('language ILIKE ?', "%#{language}%") }
  scope :recently_updated, -> { order(updated_at: :desc) }
  scope :with_users, -> { includes(:users) }

  # Callbacks
  before_validation :set_defaults, on: :create

  # Instance methods
  def add_user(user, admin: false)
    user_repositories.find_or_create_by(user: user) do |ur|
      ur.admin = admin
    end
  end

  def remove_user(user)
    user_repositories.find_by(user: user)&.destroy
  end

  def user_count
    users.count
  end

  def update_last_synced
    update(last_synced_at: Time.current)
  end

  def sync_needed?(threshold = 1.hour)
    last_synced_at.nil? || last_synced_at < threshold.ago
  end

  private

  def set_defaults
    self.last_synced_at ||= Time.current
    self.private = true if private.nil?
  end
end
