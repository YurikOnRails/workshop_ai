# frozen_string_literal: true

class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat
  before_action :set_message, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_chat_access!

  # GET /chats/1/messages
  def index
    @messages = @chat.messages
                    .includes(:user)
                    .order(created_at: :desc)
                    .page(params[:page])
                    .per(50)

    respond_to do |format|
      format.html
      format.json { render json: @messages, include: { user: { only: [ :id, :username, :avatar_url ] } } }
    end
  end

  # GET /chats/1/messages/1
  def show
    respond_to do |format|
      format.html
      format.json { render json: @message, include: { user: { only: [ :id, :username, :avatar_url ] } } }
    end
  end

  # GET /chats/1/messages/new
  def new
    @message = @chat.messages.new
  end

  # POST /chats/1/messages
  def create
    @message = @chat.messages.new(message_params)
    @message.user = current_user

    respond_to do |format|
      if @message.save
        format.html { redirect_to @chat, notice: "Message was successfully sent." }
        format.json { render :show, status: :created, location: [ @chat, @message ] }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /chats/1/messages/1
  def update
    # Only allow the message author to edit their own messages
    if @message.user != current_user
      respond_to do |format|
        format.html { redirect_to @chat, alert: "You can only edit your own messages." }
        format.json { render json: { error: "You can only edit your own messages." }, status: :forbidden }
      end
      return
    end

    # Prevent editing messages older than 15 minutes
    if @message.created_at < 15.minutes.ago
      respond_to do |format|
        format.html { redirect_to @chat, alert: "Messages can only be edited within 15 minutes of posting." }
        format.json { render json: { error: "Messages can only be edited within 15 minutes of posting." }, status: :forbidden }
      end
      return
    end

    if @message.update(message_params.merge(edited: true))
      respond_to do |format|
        format.html { redirect_to @chat, notice: "Message was successfully updated." }
        format.json { render :show, status: :ok, location: [ @chat, @message ] }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /chats/1/messages/1
  def destroy
    # Only allow the message author or chat admin to delete messages
    chat_user = @chat.chat_users.find_by(user: current_user)
    unless @message.user == current_user || (chat_user && chat_user.admin?)
      respond_to do |format|
        format.html { redirect_to @chat, alert: "You do not have permission to delete this message." }
        format.json { render json: { error: "You do not have permission to delete this message." }, status: :forbidden }
      end
      return
    end

    @message.destroy

    respond_to do |format|
      format.html { redirect_to @chat, notice: "Message was successfully deleted." }
      format.json { head :no_content }
    end
  end

  # POST /chats/1/messages/mark_read
  def mark_read
    last_message_id = params[:last_message_id]

    if last_message_id.present?
      # Mark all messages up to and including last_message_id as read
      unread_messages = current_user.unread_messages
                                   .where(chat: @chat)
                                   .where("message_id <= ?", last_message_id)

      unread_count = unread_messages.count
      unread_messages.destroy_all

      # Update the chat user's last_read_at
      chat_user = @chat.chat_users.find_by(user: current_user)
      chat_user&.update(last_read_at: Time.current)

      render json: { status: "success", unread_count: unread_count }
    else
      render json: { status: "error", message: "No last_message_id provided" }, status: :bad_request
    end
  end

  private

  def set_chat
    @chat = Chat.find(params[:chat_id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to chats_path, alert: "Chat not found." }
      format.json { render json: { error: "Chat not found." }, status: :not_found }
    end
  end

  def set_message
    @message = @chat.messages.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to @chat, alert: "Message not found." }
      format.json { render json: { error: "Message not found." }, status: :not_found }
    end
  end

  def authorize_chat_access!
    return if @chat.users.include?(current_user)

    respond_to do |format|
      format.html { redirect_to chats_path, alert: "You do not have access to this chat." }
      format.json { render json: { error: "You do not have access to this chat." }, status: :forbidden }
    end
  end

  def message_params
    params.require(:message).permit(:content, :message_type)
  end
end
