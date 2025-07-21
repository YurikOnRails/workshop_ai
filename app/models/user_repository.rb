class UserRepository < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :repository

  # Validations
  validates :user_id, uniqueness: { scope: :repository_id, message: 'is already associated with this repository' }
  validates :admin, inclusion: { in: [true, false] }
  validates :last_accessed_at, presence: true

  # Scopes
  scope :admins, -> { where(admin: true) }
  scope :recently_accessed, -> { order(last_accessed_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_repository, ->(repository) { where(repository: repository) }

  # Callbacks
  before_validation :set_defaults, on: :create
  before_validation :set_last_accessed, on: :create
  after_commit :update_repository_timestamps, on: [:create, :destroy]

  # Instance methods
  def update_last_accessed
    update(last_accessed_at: Time.current)
  end

  def make_admin
    update(admin: true)
  end

  def revoke_admin
    update(admin: false)
  end

  private

  def set_defaults
    self.admin = false if admin.nil?
  end
  
  def set_last_accessed
    self.last_accessed_at = Time.current if last_accessed_at.blank?
  end

  def update_repository_timestamps
    repository.touch
  end
end
