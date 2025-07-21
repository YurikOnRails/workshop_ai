class CreateUserRepositories < ActiveRecord::Migration[8.0]
  def change
    create_table :user_repositories do |t|
      t.references :user, null: false, foreign_key: true
      t.references :repository, null: false, foreign_key: true
      t.boolean :admin, default: false, null: false
      t.datetime :last_accessed_at

      t.timestamps
    end

    add_index :user_repositories, [:user_id, :repository_id], unique: true, name: 'index_user_repos_on_user_and_repo'
    # repository_id is already indexed by the foreign key constraint
    add_index :user_repositories, :last_accessed_at
    
    # Add a check to ensure a user can't be added to the same repository twice
    execute <<-SQL
      ALTER TABLE user_repositories
      ADD CONSTRAINT unique_user_repository
      UNIQUE (user_id, repository_id);
    SQL
  end
end
