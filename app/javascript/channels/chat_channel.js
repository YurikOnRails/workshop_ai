import consumer from "./consumer"

// Track typing indicators by user ID
const typingUsers = new Set()
let typingTimeout

// Function to update the typing indicator UI
function updateTypingIndicator() {
  const typingIndicator = document.getElementById('typing-indicator')
  const typingUsersList = document.getElementById('typing-users')
  
  if (!typingIndicator || !typingUsersList) return
  
  if (typingUsers.size > 0) {
    const userList = Array.from(typingUsers).slice(0, 3).join(', ')
    const moreCount = typingUsers.size - 3
    const moreText = moreCount > 0 ? ` and ${moreCount} more` : ''
    
    typingUsersList.textContent = `${userList}${moreText} ${typingUsers.size === 1 ? 'is' : 'are'} typing...`
    typingIndicator.style.display = 'block'
  } else {
    typingIndicator.style.display = 'none'
  }
}

// Function to handle incoming messages
function handleNewMessage(data) {
  // Skip if this is our own message (handled by the form submission)
  if (data.user_id === window.currentUserId) return
  
  const messagesContainer = document.querySelector('.messages')
  if (!messagesContainer) return
  
  // Check if we already have this message (prevent duplicates)
  if (document.querySelector(`[data-message-id="${data.id}"]`)) return
  
  // Create message element
  const messageElement = createMessageElement(data)
  
  // Add to the messages container
  messagesContainer.appendChild(messageElement)
  
  // Scroll to bottom if we're near the bottom
  const isNearBottom = messagesContainer.scrollHeight - messagesContainer.scrollTop - messagesContainer.clientHeight < 200
  if (isNearBottom) {
    messagesContainer.scrollTop = messagesContainer.scrollHeight
  }
  
  // Update unread count in the UI if needed
  updateUnreadCount()
}

// Function to create a message element from message data
function createMessageElement(message) {
  const messageElement = document.createElement('div')
  messageElement.className = `message ${message.user_id === window.currentUserId ? 'own-message' : ''}`
  messageElement.dataset.messageId = message.id
  
  const userAvatar = message.user.avatar_url || '/default-avatar.png'
  const timestamp = new Date(message.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  
  messageElement.innerHTML = `
    <div class="message-avatar">
      <img src="${userAvatar}" alt="${message.user.username}'s avatar">
    </div>
    <div class="message-content">
      <div class="message-header">
        <span class="message-username">${message.user.username}</span>
        <span class="message-time">${timestamp}</span>
        ${message.edited ? '<span class="message-edited">(edited)</span>' : ''}
      </div>
      <div class="message-text">${formatMessageContent(message)}</div>
    </div>
  `
  
  return messageElement
}

// Format message content based on message type
function formatMessageContent(message) {
  switch (message.message_type) {
    case 'markdown':
      return marked.parse(message.content) // Requires marked.js to be included
    case 'code':
      return `<pre><code>${escapeHtml(message.content)}</code></pre>`
    default: // text
      return escapeHtml(message.content).replace(/\n/g, '<br>')
  }
}

// Helper function to escape HTML
function escapeHtml(unsafe) {
  if (!unsafe) return ''
  return unsafe
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;")
}

// Function to update the unread count in the UI
function updateUnreadCount() {
  const unreadCount = document.querySelectorAll('.unread-marker').length
  const unreadBadge = document.getElementById('unread-badge')
  
  if (unreadBadge) {
    if (unreadCount > 0) {
      unreadBadge.textContent = unreadCount
      unreadBadge.style.display = 'inline-block'
    } else {
      unreadBadge.style.display = 'none'
    }
  }
}

document.addEventListener('turbo:load', function() {
  const chatContainer = document.getElementById('chat-container')
  if (!chatContainer) return
  
  const chatId = chatContainer.dataset.chatId
  if (!chatId) return
  
  // Store current user ID for comparison
  window.currentUserId = chatContainer.dataset.currentUserId
  
  // Connect to the chat channel
  consumer.subscriptions.create(
    { channel: 'ChatChannel', chat_id: chatId },
    {
      connected() {
        console.log(`Connected to chat channel ${chatId}`)
      },
      
      disconnected() {
        console.log(`Disconnected from chat channel ${chatId}`)
      },
      
      received(data) {
        console.log('Received data:', data)
        
        switch (data.action) {
          case 'new_message':
            handleNewMessage(data.message)
            break
            
          case 'update_message':
            updateMessage(data.message)
            break
            
          case 'delete_message':
            deleteMessage(data.message_id)
            break
            
          case 'user_typing':
            handleUserTyping(data)
            break
            
          case 'messages_read':
            handleMessagesRead(data)
            break
        }
      },
      
      // Method to send a typing indicator
      typing() {
        this.perform('receive', { action: 'typing' })
      },
      
      // Method to mark messages as read
      markAsRead(lastMessageId) {
        this.perform('receive', { 
          action: 'mark_read',
          last_message_id: lastMessageId 
        })
      }
    }
  )
  
  // Set up typing indicator
  const messageInput = document.getElementById('message_content')
  if (messageInput) {
    let typing = false
    let lastTypingTime = 0
    
    messageInput.addEventListener('input', () => {
      const now = Date.now()
      
      // Only send typing indicator every 3 seconds while typing
      if (!typing || (now - lastTypingTime > 3000)) {
        consumer.subscriptions.subscriptions[0].typing()
        lastTypingTime = now
      }
      
      if (!typing) {
        typing = true
      }
      
      // Reset typing status after 3 seconds of inactivity
      clearTimeout(typingTimeout)
      typingTimeout = setTimeout(() => {
        typing = false
      }, 3000)
    })
  }
  
  // Mark messages as read when scrolling
  const messagesContainer = document.querySelector('.messages')
  if (messagesContainer) {
    let lastMessageId = null
    
    messagesContainer.addEventListener('scroll', () => {
      // Find the last visible message
      const messages = Array.from(document.querySelectorAll('.message'))
      const containerRect = messagesContainer.getBoundingClientRect()
      
      for (let i = messages.length - 1; i >= 0; i--) {
        const messageRect = messages[i].getBoundingClientRect()
        if (messageRect.bottom <= containerRect.bottom + 100) { // 100px buffer
          const messageId = messages[i].dataset.messageId
          if (messageId && messageId !== lastMessageId) {
            lastMessageId = messageId
            consumer.subscriptions.subscriptions[0].markAsRead(messageId)
          }
          break
        }
      }
    })
  }
})

// Handle user typing indicator
function handleUserTyping(data) {
  // Skip our own typing indicator
  if (data.user_id === window.currentUserId) return
  
  // Add user to typing users
  typingUsers.add(data.username)
  updateTypingIndicator()
  
  // Remove user after 3 seconds
  setTimeout(() => {
    typingUsers.delete(data.username)
    updateTypingIndicator()
  }, 3000)
}

// Handle messages read indicator
function handleMessagesRead(data) {
  // Skip our own read receipts
  if (data.user_id === window.currentUserId) return
  
  // Update the UI to show messages as read by this user
  const messages = document.querySelectorAll(`.message[data-message-id]`)
  messages.forEach(message => {
    const messageId = parseInt(message.dataset.messageId, 10)
    if (messageId <= data.last_read_message_id) {
      message.classList.add('read')
    }
  })
}

// Update a message in the UI
function updateMessage(messageData) {
  const messageElement = document.querySelector(`[data-message-id="${messageData.id}"]`)
  if (!messageElement) return
  
  // Update the message content
  const contentElement = messageElement.querySelector('.message-text')
  if (contentElement) {
    contentElement.innerHTML = formatMessageContent(messageData)
  }
  
  // Update the edited indicator
  const editedElement = messageElement.querySelector('.message-edited')
  if (messageData.edited) {
    if (!editedElement) {
      const timeElement = messageElement.querySelector('.message-time')
      if (timeElement) {
        timeElement.insertAdjacentHTML('afterend', ' <span class="message-edited">(edited)</span>')
      }
    }
  } else if (editedElement) {
    editedElement.remove()
  }
}

// Delete a message from the UI
function deleteMessage(messageId) {
  const messageElement = document.querySelector(`[data-message-id="${messageId}"]`)
  if (messageElement) {
    // Replace with a deleted message indicator
    messageElement.outerHTML = `
      <div class="message deleted" data-message-id="${messageId}">
        <div class="message-content">
          <div class="message-text">This message was deleted.</div>
        </div>
      </div>
    `
  }
}
