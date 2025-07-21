# frozen_string_literal: true

class CleanupDuplicateMigrations < ActiveRecord::Migration[8.0]
  def up
    # This migration is a no-op as we're just cleaning up previous migrations
    # All the actual schema changes are already applied
    puts 'Cleaning up duplicate migrations...'
    
    # The following migrations are consolidated and can be safely removed:
    # - 20250721041118_make_last_read_message_id_nullable_in_unread_messages.rb
    # - 20250721041948_make_last_read_message_id_nullable_in_unread_messages_again.rb
    # - 20250721042127_make_last_read_message_id_nullable_in_unread_messages_final.rb
    # - 20250721043609_make_last_read_message_id_nullable_in_chat_users.rb
    
    # We don't actually need to perform any database changes here
    # The schema is already in the correct state
    # This is just for cleaning up the migration history
  end
  
  def down
    # Nothing to do here as we're just cleaning up migration files
    # The actual schema changes should not be reverted
  end
end
