import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

export default class extends Controller {
  static values = {
    chatId: String
  }
  
  connect() {
    // Subscribe to the chat channel for presence updates
    this.subscription = consumer.subscriptions.create(
      { channel: "ChatChannel", id: this.chatIdValue },
      {
        connected: this._connected.bind(this),
        disconnected: this._disconnected.bind(this),
        received: this._received.bind(this)
      }
    )
    
    // Set up periodic presence updates
    this.presenceInterval = setInterval(() => {
      this.sendPresencePing()
    }, 30000) // Every 30 seconds
    
    // Initial presence ping
    this.sendPresencePing()
  }
  
  disconnect() {
    // Unsubscribe from the channel
    if (this.subscription) {
      consumer.subscriptions.remove(this.subscription)
    }
    
    // Clear the presence interval
    if (this.presenceInterval) {
      clearInterval(this.presenceInterval)
    }
  }
  
  // Private methods
  
  _connected() {
    console.log(`Connected to chat ${this.chatIdValue}`)
    this.sendPresencePing()
  }
  
  _disconnected() {
    console.log(`Disconnected from chat ${this.chatIdValue}`)
  }
  
  _received(data) {
    if (data.type === 'presence') {
      this.handlePresenceUpdate(data)
    }
  }
  
  sendPresencePing() {
    if (this.subscription) {
      this.subscription.perform('presence_ping')
    }
  }
  
  handlePresenceUpdate(data) {
    const userId = data.user_id
    const isOnline = data.online
    const timestamp = data.timestamp ? new Date(data.timestamp) : new Date()
    
    // Update user status in the chat header
    const userStatusElement = document.querySelector(`[data-user-id="${userId}"] .user-status`)
    if (userStatusElement) {
      const statusIndicator = userStatusElement.querySelector('.status-indicator')
      const statusText = userStatusElement.querySelector('.status-text')
      
      if (statusIndicator) {
        statusIndicator.className = `inline-block h-2 w-2 rounded-full mr-1 ${isOnline ? 'bg-green-400' : 'bg-gray-400'}`
      }
      
      if (statusText) {
        statusText.textContent = isOnline ? 'Online' : `Last seen ${this.formatLastSeen(timestamp)}`
      }
    }
    
    // Update online count in group/repository chats
    if (data.online_count !== undefined) {
      const onlineCountElement = document.querySelector('.online-count')
      if (onlineCountElement) {
        onlineCountElement.textContent = `${data.online_count} online`
      }
    }
    
    // Update user status in the chat list (if visible)
    const chatItemElement = document.querySelector(`[data-chat-user-id="${userId}"] .user-status-indicator`)
    if (chatItemElement) {
      chatItemElement.className = `absolute bottom-0 right-0 block h-2.5 w-2.5 rounded-full ${isOnline ? 'bg-green-400' : 'bg-gray-400'} ring-2 ring-white dark:ring-gray-800`
    }
  }
  
  formatLastSeen(timestamp) {
    const now = new Date()
    const diffInSeconds = Math.floor((now - timestamp) / 1000)
    
    if (diffInSeconds < 60) {
      return 'just now'
    } else if (diffInSeconds < 3600) {
      const minutes = Math.floor(diffInSeconds / 60)
      return `${minutes} ${minutes === 1 ? 'minute' : 'minutes'} ago`
    } else if (diffInSeconds < 86400) {
      const hours = Math.floor(diffInSeconds / 3600)
      return `${hours} ${hours === 1 ? 'hour' : 'hours'} ago`
    } else {
      const days = Math.floor(diffInSeconds / 86400)
      return `${days} ${days === 1 ? 'day' : 'days'} ago`
    }
  }
}
