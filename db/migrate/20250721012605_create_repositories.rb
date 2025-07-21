class CreateRepositories < ActiveRecord::Migration[8.0]
  def change
    create_table :repositories do |t|
      t.bigint :github_repo_id, null: false
      t.string :name, null: false
      t.boolean :private, default: false, null: false
      t.datetime :last_synced_at

      t.timestamps
    end

    add_index :repositories, :github_repo_id, unique: true
    add_index :repositories, [:name, :github_repo_id], unique: true
    add_index :repositories, :last_synced_at
  end
end
