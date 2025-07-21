# frozen_string_literal: true

class ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat, only: [:show, :edit, :update, :destroy, :add_participant, :remove_participant, :leave, :promote_admin, :demote_admin]
  before_action :authorize_chat_access!, only: [:show]
  before_action :authorize_chat_management!, only: [:edit, :update, :destroy, :add_participant, :remove_participant, :promote_admin, :demote_admin]
  
  # GET /chats/:id
  def show
    @messages = @chat.messages.includes(:user).order(created_at: :desc).limit(50).reverse
    @message = @chat.messages.new
    
    # Mark messages as read
    mark_messages_as_read
    
    # Track user activity
    current_user.update_columns(last_seen_at: Time.current, online: true)
    
    respond_to do |format|
      format.html
      format.json { render json: @chat }
    end
  end
  
  # GET /chats
  def index
    @chats = current_user.chats
                        .includes(:messages, :users)
                        .order('messages.created_at DESC, chats.updated_at DESC')
    
    # Group by chat type
    @direct_chats = @chats.select(&:direct_chat?)
    @group_chats = @chats.select(&:group_chat?)
    @repository_chats = @chats.select(&:repository_chat?)
    
    # Get unread counts for each chat
    @unread_counts = {}
    current_user.chat_users.includes(:chat).each do |chat_user|
      @unread_counts[chat_user.chat_id] = chat_user.unread_messages_count
    end
  end
  
  # GET /chats/1
  def show
    # Mark messages as read when opening the chat
    @chat.mark_as_read_for(current_user)
    
    # Load messages with pagination
    @messages = @chat.messages
                     .includes(:user)
                     .order(created_at: :desc)
                     .page(params[:page])
                     .per(50)
    
    # For the message form
    @message = @chat.messages.new
    
    # Get chat participants
    @participants = @chat.users.distinct
    
    # Get users that can be added to this chat
    if @chat.repository_chat? && @chat.repository
      @available_users = @chat.repository.users.where.not(id: @participants.pluck(:id))
    else
      @available_users = User.none # Only allow adding users to repository chats for now
    end
  end
  
  # GET /chats/new
  def new
    @chat = Chat.new(chat_type: params[:type] || 'direct')
    
    # For direct chats, pre-select the other user if provided
    if @chat.direct_chat? && params[:user_id].present?
      @other_user = User.find_by(id: params[:user_id])
      @chat.name = "#{current_user.username} and #{@other_user&.username}" if @other_user
    end
    
    # For repository chats, pre-select the repository if provided
    if @chat.repository_chat? && params[:repository_id].present?
      @repository = Repository.find_by(id: params[:repository_id])
      @chat.repository = @repository
      @chat.name = @repository&.full_name
    end
  end
  
  # POST /chats
  def create
    chat_type = params.dig(:chat, :chat_type) || 'direct'
    
    begin
      case chat_type
      when 'direct'
        other_user_id = params.dig(:chat, :user_id)
        @chat = ChatService.find_or_create_direct_chat(current_user.id, other_user_id)
        redirect_to @chat, notice: 'Direct chat was successfully created.'
        
      when 'group'
        @chat = ChatService.create_chat(
          current_user,
          'group',
          name: chat_params[:name],
          description: chat_params[:description],
          participant_ids: Array(chat_params[:participant_ids]).reject(&:blank?)
        )
        redirect_to @chat, notice: 'Group chat was successfully created.'
        
      when 'repository'
        repository_id = params.dig(:chat, :repository_id)
        @chat = ChatService.create_chat(
          current_user,
          'repository',
          repository_id: repository_id,
          name: chat_params[:name],
          description: chat_params[:description]
        )
        redirect_to @chat, notice: 'Repository chat was successfully created.'
        
      else
        redirect_to chats_path, alert: 'Invalid chat type.'
      end
    rescue ChatService::Error => e
      @chat ||= Chat.new(chat_params)
      flash.now[:alert] = e.message
      render :new, status: :unprocessable_entity
    end
  end
  
  # POST /chats/1/add_participant
  def add_participant
    user_ids = Array(params[:user_id] || params[:user_ids]).reject(&:blank?)
    
    begin
      added_users = ChatService.add_participants(@chat, current_user, user_ids)
      
      if added_users.any?
        redirect_to @chat, notice: "Successfully added #{added_users.count} participant(s) to the chat."
      else
        redirect_to @chat, alert: 'No new participants were added.'
      end
    rescue ChatService::Error => e
      redirect_to @chat, alert: e.message
    end
  end
  
  # DELETE /chats/1/remove_participant/:user_id
  def remove_participant
    user = User.find(params[:user_id])
    
    begin
      ChatService.remove_participant(@chat, current_user, user.id, params[:reason])
      
      if current_user == user
        # If user is removing themselves, redirect to chats list
        redirect_to chats_path, notice: 'You have left the chat.'
      else
        redirect_to @chat, notice: "#{user.username} has been removed from the chat."
      end
    rescue ChatService::Error => e
      redirect_to @chat, alert: e.message
    end
  end
  
  # POST /chats/1/promote_admin/:user_id
  def promote_admin
    user = User.find(params[:user_id])
    
    begin
      ChatService.promote_to_admin(@chat, current_user, user.id)
      redirect_to @chat, notice: "#{user.username} has been promoted to admin."
    rescue ChatService::Error => e
      redirect_to @chat, alert: e.message
    end
  end
  
  # POST /chats/1/demote_admin/:user_id
  def demote_admin
    user = User.find(params[:user_id])
    
    begin
      ChatService.demote_admin(@chat, current_user, user.id)
      redirect_to @chat, notice: "#{user.username} has been demoted from admin."
    rescue ChatService::Error => e
      redirect_to @chat, alert: e.message
    end
  end
  
  # DELETE /chats/1/leave
  def leave
    begin
      ChatService.remove_participant(@chat, current_user, current_user.id)
      redirect_to chats_path, notice: 'You have left the chat.'
    rescue ChatService::Error => e
      redirect_to @chat, alert: e.message
    end
  end
  
  # GET /chats/1/edit
  def edit
    # Only group chats can be edited
    unless @chat.group_chat?
      redirect_to @chat, alert: 'Only group chats can be edited.'
      return
    end
    
    @available_users = User.where.not(id: @chat.users.pluck(:id))
  end
  
  # PATCH/PUT /chats/1
  def update
    if @chat.update(chat_params)
      redirect_to @chat, notice: 'Chat was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  # DELETE /chats/1
  def destroy
    @chat.destroy
    redirect_to chats_url, notice: 'Chat was successfully destroyed.'
  end
  
  private
  
  def set_chat
    @chat = Chat.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to chats_path, alert: 'Chat not found.'
  end
  
  def authorize_chat_access!
    return if @chat.users.include?(current_user)
    
    redirect_to chats_path, alert: 'You do not have access to this chat.'
  end
  
  def authorize_chat_management!
    # Only allow chat admins to manage the chat
    chat_user = @chat.chat_users.find_by(user: current_user)
    
    unless chat_user&.admin? || @chat.direct_chat?
      redirect_to @chat, alert: 'You do not have permission to perform this action.'
    end
  end
  
  def chat_params
    params.require(:chat).permit(
      :name,
      :description,
      :chat_type,
      :repository_id,
      participant_ids: []
    )
  end
end
