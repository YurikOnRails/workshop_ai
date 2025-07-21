# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserRepository, type: :model do
  # Test associations
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:repository) }
  end

  # Test validations
  describe 'validations' do
    subject { build(:user_repository) }

    it { is_expected.to validate_presence_of(:last_accessed_at) }
    it { is_expected.to validate_inclusion_of(:admin).in_array([true, false]) }
    
    it 'validates uniqueness of user scoped to repository' do
      user_repo = create(:user_repository)
      new_user_repo = build(:user_repository, 
                           user: user_repo.user, 
                           repository: user_repo.repository)
      expect(new_user_repo).not_to be_valid
      expect(new_user_repo.errors[:user_id]).to include('is already associated with this repository')
    end
  end

  # Test scopes
  describe 'scopes' do
    let!(:admin_user_repo) { create(:user_repository, admin: true) }
    let!(:regular_user_repo) { create(:user_repository, admin: false) }
    let!(:user) { create(:user) }
    let!(:repository) { create(:repository) }
    let!(:user_specific_repo) { create(:user_repository, user: user) }
    let!(:repo_specific_user) { create(:user_repository, repository: repository) }

    describe '.admins' do
      it 'returns only admin user repositories' do
        expect(described_class.admins).to include(admin_user_repo)
        expect(described_class.admins).not_to include(regular_user_repo)
      end
    end

    describe '.for_user' do
      it 'returns user repositories for specific user' do
        expect(described_class.for_user(user)).to include(user_specific_repo)
        expect(described_class.for_user(user).count).to eq(1)
      end
    end

    describe '.for_repository' do
      it 'returns user repositories for specific repository' do
        expect(described_class.for_repository(repository)).to include(repo_specific_user)
        expect(described_class.for_repository(repository).count).to eq(1)
      end
    end
  end

  # Test instance methods
  describe 'instance methods' do
    let(:user_repo) { create(:user_repository, admin: false) }

    describe '#make_admin' do
      it 'makes the user an admin of the repository' do
        expect { user_repo.make_admin }.to change { user_repo.reload.admin }.to(true)
      end
    end

    describe '#revoke_admin' do
      let(:admin_user_repo) { create(:user_repository, admin: true) }
      
      it 'revokes admin rights from the user' do
        expect { admin_user_repo.revoke_admin }.to change { admin_user_repo.reload.admin }.to(false)
      end
    end
  end

  # Test callbacks
  describe 'callbacks' do
    describe 'before_validation :set_defaults' do
      it 'sets default values' do
        user_repo = build(:user_repository, last_accessed_at: nil, admin: nil)
        user_repo.valid?
        expect(user_repo.last_accessed_at).to be_present
        expect(user_repo.admin).to be_falsey
      end
    end

    describe 'after_commit :update_repository_timestamps' do
      let(:repository) { create(:repository) }
      
      it 'touches the repository on create' do
        expect {
          create(:user_repository, repository: repository)
        }.to change { repository.reload.updated_at }
      end

      it 'touches the repository on destroy' do
        user_repo = create(:user_repository, repository: repository)
        expect {
          user_repo.destroy
        }.to change { repository.reload.updated_at }
      end
    end
  end
end
