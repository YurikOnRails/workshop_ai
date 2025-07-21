require 'rails_helper'

RSpec.describe Chat, type: :model do
  # Test associations
  describe 'associations' do
    it { is_expected.to belong_to(:repository).optional }
    it { is_expected.to have_many(:chat_users).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:chat_users) }
    it { is_expected.to have_many(:messages).dependent(:destroy) }
    it { is_expected.to have_many(:active_chat_users).class_name('ChatUser') }
    it { is_expected.to have_many(:active_users).through(:active_chat_users).source(:user) }
  end

  # Test validations
  describe 'validations' do
    subject { build(:chat) }

    # Test that chat_type is set to a default value
    it 'has a default chat_type' do
      chat = create(:chat, :with_defaults)
      expect(chat.chat_type).to eq('group')
    end

    it { is_expected.to validate_inclusion_of(:chat_type).in_array(Chat::CHAT_TYPES) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }
    it { is_expected.to validate_length_of(:description).is_at_most(500) }
    
    context 'when chat type is repository' do
      let(:repository) { create(:repository) }
      subject { build(:repository_chat, repository: repository) }
      
      it 'is valid with a repository' do
        expect(subject).to be_valid
      end
      
      it 'is invalid without a repository' do
        subject.repository = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:repository]).to include('must be present for repository chats')
      end
    end
    
    context 'when chat type is group' do
      subject { build(:group_chat, repository: nil) }
      
      it 'is valid without a repository' do
        expect(subject).to be_valid
      end
      
      it 'is invalid with a repository' do
        subject.repository = create(:repository)
        expect(subject).not_to be_valid
        expect(subject.errors[:repository_id]).to include('must be blank for non-repository chats')
      end
    end
    
    context 'when chat type is direct' do
      let(:user1) { create(:user) }
      let(:user2) { create(:user) }
      let(:user3) { create(:user) }
      let(:chat) { create(:direct_chat) }
      
      before do
        chat.add_participant(user1, added_by: user1)
        chat.add_participant(user2, added_by: user1)
        chat.reload # Reload to get the updated users count
      end
      
      it 'allows up to 2 participants' do
        expect(chat.users.count).to eq(2)
        expect(chat).to be_valid
      end
      
      it 'does not allow more than 2 participants' do
        expect {
          chat.add_participant(user3, added_by: user1)
        }.to raise_error(ActiveRecord::RecordInvalid, /Direct chat cannot have more than 2 participants/)
      end
    end
  end
  
  # Test scopes
  describe 'scopes' do
    let!(:direct_chat) { create(:direct_chat) }
    let!(:group_chat) { create(:group_chat) }
    let!(:repository_chat) { create(:repository_chat) }
    let!(:active_chat) { create(:group_chat, archived: false) }
    let!(:archived_chat) { create(:group_chat, :archived) }
    let!(:user) { create(:user) }
    let!(:user_chat) { create(:group_chat) }
    let!(:other_user_chat) { create(:group_chat) }
    
    before do
      # Set up chat users for testing the for_user scope
      create(:chat_user, chat: user_chat, user: user)
      create(:chat_user, chat: other_user_chat, user: create(:user))
    end
    
    describe '.direct' do
      it 'returns only direct chats' do
        expect(Chat.direct).to contain_exactly(direct_chat)
      end
    end
    
    describe '.group_chats' do
      it 'returns only group chats' do
        expect(Chat.group_chats).to contain_exactly(group_chat, active_chat, archived_chat, user_chat, other_user_chat)
      end
    end
    
    describe '.repository_chats' do
      it 'returns only repository chats' do
        expect(Chat.repository_chats).to contain_exactly(repository_chat)
      end
    end
    
    describe '.active' do
      it 'returns only active (non-archived) chats' do
        expect(Chat.active).to contain_exactly(direct_chat, group_chat, repository_chat, active_chat, user_chat, other_user_chat)
      end
    end
    
    describe '.archived' do
      it 'returns only archived chats' do
        expect(Chat.archived).to contain_exactly(archived_chat)
      end
    end
    
    describe '.for_user' do
      it 'returns chats for a specific user' do
        expect(Chat.for_user(user)).to contain_exactly(user_chat)
      end
      
      it 'does not return chats for other users' do
        expect(Chat.for_user(user)).not_to include(other_user_chat)
      end
    end
  end
  
  # Test instance methods
  describe 'instance methods' do
    let(:chat) { create(:group_chat) }
    let(:direct_chat) { create(:direct_chat) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }
    # Don't create chat_user1 here as it will interfere with the add_participant tests
    
    describe '#direct_chat?' do
      it 'returns true for direct chat type' do
        expect(direct_chat.direct_chat?).to be true
      end
      
      it 'returns false for other chat types' do
        expect(chat.direct_chat?).to be false
      end
    end
    
    describe '#group_chat?' do
      it 'returns true for group chat type' do
        expect(chat.group_chat?).to be true
      end
      
      it 'returns false for other chat types' do
        expect(direct_chat.group_chat?).to be false
      end
    end
    
    describe '#repository_chat?' do
      let(:repository_chat) { create(:repository_chat) }
      
      it 'returns true for repository chat type' do
        expect(repository_chat.repository_chat?).to be true
      end
      
      it 'returns false for other chat types' do
        expect(chat.repository_chat?).to be false
      end
    end
    
    describe '#add_participant' do
      it 'adds a user to the chat' do
        expect {
          chat.add_participant(user1)
        }.to change(chat.users, :count).by(1)
        
        expect(chat.users).to include(user1)
        expect(chat.participants_count).to eq(1)
      end
      
      it 'does not add the same user twice' do
        chat.add_participant(user1)
        
        expect {
          chat.add_participant(user1)
        }.not_to change(chat.users, :count)
        
        expect(chat.participants_count).to eq(1)
      end
      
      it 'allows specifying who added the participant' do
        chat_user = chat.add_participant(user1, added_by: user2)
        chat_user = chat.chat_users.find_by(user: user1)
        
        expect(chat_user.added_by).to eq(user2)
      end
    end
    
    describe '#remove_participant' do
      before do
        chat.add_participant(user1)
        chat.add_participant(user2)
      end
      
      it 'marks the user as left instead of removing them' do
        expect {
          chat.remove_participant(user1)
        }.to change { chat.chat_users.active.count }.by(-1)
          .and change { chat.participants_count }.by(-1)
        
        expect(chat.users).to include(user1) # Still associated but marked as left
        expect(chat.chat_users.find_by(user: user1).left_at).to be_present
      end
      
      it 'does nothing if user is not a participant' do
        expect {
          chat.remove_participant(create(:user))
        }.not_to change { chat.chat_users.active.count }
      end
    end
    
    describe '#update_last_message' do
      before do
        # Ensure the user is a participant in the chat
        chat.add_participant(user1)
      end
      
      let!(:message) { create(:message, chat: chat, user: user1) }
      
      it 'updates the last message timestamp and ID' do
        travel_to(1.hour.from_now) do
          new_message = create(:message, chat: chat, user: user1)
          chat.update_last_message(new_message)
          
          expect(chat.last_message_at).to be_within(1.second).of(new_message.created_at)
          expect(chat.last_message_id).to eq(new_message.id)
        end
      end
    end
    
    describe '#mark_as_read_for' do
      before { chat.add_participant(user1) }
      
      it 'updates the last read timestamp for the user' do
        time = 1.hour.ago
        
        travel_to(time) do
          chat.mark_as_read_for(user1)
        end
        
        chat_user = chat.chat_users.find_by(user: user1)
        expect(chat_user.last_read_at).to be_within(1.second).of(time)
      end
      
      it 'returns nil if user is not a participant' do
        expect(chat.mark_as_read_for(user2)).to be_nil
      end
    end
    
    describe '#unread_count_for' do
      before do
        chat.add_participant(user1)
        chat.add_participant(user2)
        
        # Create some messages before marking as read
        travel_to(3.hours.ago) do
          create_list(:message, 2, chat: chat, user: user2)
        end
        
        # Mark as read
        travel_to(2.hours.ago) do
          chat.mark_as_read_for(user1)
        end
        
        # Create some new messages after marking as read
        travel_to(1.hour.ago) do
          create_list(:message, 3, chat: chat, user: user2)
        end
      end
      
      it 'returns the count of unread messages' do
        expect(chat.unread_count_for(user1)).to eq(3)
      end
      
      it 'returns 0 if user is not a participant' do
        expect(chat.unread_count_for(create(:user))).to eq(0)
      end
      
      it 'returns 0 if user has no last_read_at' do
        user3 = create(:user)
        chat.add_participant(user3)
        expect(chat.unread_count_for(user3)).to eq(0)
      end
      
      it 'returns 0 if there are no new messages' do
        chat.mark_as_read_for(user1)
        expect(chat.unread_count_for(user1)).to eq(0)
      end
    end
    
    describe '#online_users_count' do
      before do
        # Set up online/offline users
        user1.update(last_seen_at: 1.minute.ago)  # Online
        user2.update(last_seen_at: 1.hour.ago)    # Offline
        user3.update(last_seen_at: 30.seconds.ago) # Online
        
        # Add users to chat
        [user1, user2, user3].each { |u| chat.add_participant(u) }
      end
      
      it 'returns the count of online users in the chat' do
        # Only user1 and user3 are online (last_seen within 5 minutes)
        expect(chat.online_users_count).to eq(2)
      end
      
      it 'returns 0 when no users are online' do
        # Make all users offline
        User.update_all(last_seen_at: 10.minutes.ago)
        expect(chat.reload.online_users_count).to eq(0)
      end
    end
  end
  
  # Test callbacks
  describe 'callbacks' do
    describe 'before_validation :set_defaults' do
      it 'sets default chat type to group' do
        chat = Chat.new
        chat.valid?
        expect(chat.chat_type).to eq('group')
      end
      
      it 'sets archived to false by default' do
        chat = Chat.new
        chat.valid?
        expect(chat.archived).to be false
      end
    end
  end
end
