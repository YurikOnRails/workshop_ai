class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.bigint :github_id, null: false
      t.string :username, null: false
      t.string :email
      t.string :avatar_url
      t.integer :private_repos_count, default: 0, null: false
      t.integer :stars_count, default: 0, null: false
      t.integer :private_stars_count, default: 0, null: false
      t.boolean :online, default: false, null: false

      t.timestamps
    end

    add_index :users, :github_id, unique: true
    add_index :users, :username, unique: true
    add_index :users, :email, unique: true
  end
end
