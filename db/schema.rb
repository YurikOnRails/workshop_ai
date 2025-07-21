# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_21_020438) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "chat_users", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.bigint "user_id", null: false
    t.datetime "joined_at", null: false
    t.datetime "left_at"
    t.boolean "muted", default: false, null: false
    t.boolean "admin", default: false, null: false
    t.datetime "last_read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id", "user_id"], name: "index_chat_users_on_chat_and_user", unique: true
    t.index ["chat_id"], name: "index_chat_users_on_chat_id"
    t.index ["last_read_at"], name: "index_chat_users_on_last_read_at"
    t.index ["left_at"], name: "index_chat_users_on_left_at"
    t.index ["user_id"], name: "index_chat_users_on_user_id"
    t.check_constraint "left_at IS NULL OR left_at >= joined_at", name: "check_timeline"
    t.unique_constraint ["chat_id", "user_id"], name: "unique_chat_user"
  end

  create_table "chats", force: :cascade do |t|
    t.string "chat_type", null: false
    t.bigint "repository_id"
    t.string "name"
    t.text "description"
    t.datetime "last_message_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_type"], name: "index_chats_on_chat_type"
    t.index ["last_message_at"], name: "index_chats_on_last_message_at"
    t.index ["repository_id", "chat_type"], name: "index_chats_on_repository_id_and_chat_type", unique: true, where: "(repository_id IS NOT NULL)"
    t.index ["repository_id"], name: "index_chats_on_repository_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.bigint "user_id", null: false
    t.text "content", null: false
    t.datetime "edited_at"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id", "created_at"], name: "index_messages_on_chat_id_and_created_at"
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["deleted_at"], name: "index_messages_on_deleted_at"
    t.index ["user_id"], name: "index_messages_on_user_id"
    t.check_constraint "length(TRIM(BOTH FROM content)) > 0 AND length(TRIM(BOTH FROM content)) <= 10000", name: "check_content_length"
  end

  create_table "repositories", force: :cascade do |t|
    t.bigint "github_repo_id", null: false
    t.string "name", null: false
    t.boolean "private", default: false, null: false
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["github_repo_id"], name: "index_repositories_on_github_repo_id", unique: true
    t.index ["last_synced_at"], name: "index_repositories_on_last_synced_at"
    t.index ["name", "github_repo_id"], name: "index_repositories_on_name_and_github_repo_id", unique: true
  end

  create_table "unread_messages", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "chat_id", null: false
    t.bigint "last_read_message_id", null: false
    t.integer "unread_count", default: 0, null: false
    t.datetime "last_notified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_unread_messages_on_chat_id"
    t.index ["last_notified_at"], name: "index_unread_messages_on_last_notified_at"
    t.index ["last_read_message_id"], name: "index_unread_messages_on_last_read_message_id"
    t.index ["user_id", "chat_id"], name: "index_unread_messages_on_user_and_chat", unique: true
    t.index ["user_id"], name: "index_unread_messages_on_user_id"
    t.check_constraint "unread_count >= 0", name: "check_unread_count"
    t.unique_constraint ["user_id", "chat_id"], name: "unique_user_chat"
  end

  create_table "user_repositories", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "repository_id", null: false
    t.boolean "admin", default: false, null: false
    t.datetime "last_accessed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["last_accessed_at"], name: "index_user_repositories_on_last_accessed_at"
    t.index ["repository_id"], name: "index_user_repositories_on_repository_id"
    t.index ["user_id", "repository_id"], name: "index_user_repos_on_user_and_repo", unique: true
    t.index ["user_id"], name: "index_user_repositories_on_user_id"
    t.unique_constraint ["user_id", "repository_id"], name: "unique_user_repository"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "github_id", null: false
    t.string "username", null: false
    t.string "email"
    t.string "avatar_url"
    t.integer "private_repos_count", default: 0, null: false
    t.integer "stars_count", default: 0, null: false
    t.integer "private_stars_count", default: 0, null: false
    t.boolean "online", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_seen_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["github_id"], name: "index_users_on_github_id", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "chat_users", "chats"
  add_foreign_key "chat_users", "users"
  add_foreign_key "chats", "repositories"
  add_foreign_key "messages", "chats"
  add_foreign_key "messages", "users"
  add_foreign_key "unread_messages", "chats"
  add_foreign_key "unread_messages", "messages", column: "last_read_message_id"
  add_foreign_key "unread_messages", "users"
  add_foreign_key "user_repositories", "repositories"
  add_foreign_key "user_repositories", "users"
end
