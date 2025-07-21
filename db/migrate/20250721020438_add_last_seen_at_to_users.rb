class AddLastSeenAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :last_seen_at, :datetime, default: -> { 'CURRENT_TIMESTAMP' }, null: false

    # Backfill existing users with current time
    reversible do |dir|
      dir.up do
        User.update_all(last_seen_at: Time.current)
      end
    end
  end
end
