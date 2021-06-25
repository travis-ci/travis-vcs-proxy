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

ActiveRecord::Schema.define(version: 2021_06_17_063016) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "commits", force: :cascade do |t|
    t.string "sha", null: false
    t.integer "user_id", null: false
    t.integer "repository_id", null: false
    t.integer "ref_id", null: false
    t.datetime "created_at", null: false
  end

  create_table "jwt_deny_lists", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.index ["jti"], name: "index_jwt_deny_lists_on_jti"
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer "resource_owner_id", null: false
    t.integer "application_id", null: false
    t.string "token"
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "created_at"
    t.datetime "revoked_at"
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uuid", null: false
    t.string "secret", null: false
    t.string "redirect_uri", null: false
    t.integer "owner_id"
  end

  create_table "pull_requests", force: :cascade do |t|
    t.integer "base_id", null: false
    t.integer "head_id", null: false
    t.integer "repository_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at"
    t.integer "number"
  end

  create_table "refs", force: :cascade do |t|
    t.string "name", null: false
    t.integer "type", null: false
    t.integer "repository_id", null: false
  end

  create_table "repositories", force: :cascade do |t|
    t.string "name", null: false
    t.string "url", null: false
    t.integer "server_provider_id", null: false
  end

  create_table "repository_permissions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "repository_id", null: false
    t.integer "permission", null: false
  end

  create_table "server_provider_permissions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "server_provider_id", null: false
    t.integer "permission", null: false
  end

  create_table "server_provider_user_settings", force: :cascade do |t|
    t.string "value", null: false
    t.integer "server_provider_user_id", null: false
    t.boolean "is_syncing"
  end

  create_table "server_providers", force: :cascade do |t|
    t.string "name", null: false
    t.string "url", null: false
    t.string "type", null: false
    t.string "listener_token"
  end

  create_table "settings", force: :cascade do |t|
    t.string "var", null: false
    t.text "value"
    t.string "target_type", null: false
    t.bigint "target_id", null: false
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["target_type", "target_id", "var"], name: "index_settings_on_target_type_and_target_id_and_var", unique: true
    t.index ["target_type", "target_id"], name: "index_settings_on_target"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "confirmation_token"
    t.datetime "confirmation_sent_at"
    t.string "type", null: false
    t.datetime "created_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "commits", "refs"
  add_foreign_key "commits", "repositories"
  add_foreign_key "commits", "users"
  add_foreign_key "oauth_applications", "users", column: "owner_id"
  add_foreign_key "pull_requests", "commits", column: "base_id"
  add_foreign_key "pull_requests", "commits", column: "head_id"
  add_foreign_key "pull_requests", "repositories"
  add_foreign_key "pull_requests", "users"
  add_foreign_key "refs", "repositories"
  add_foreign_key "repositories", "server_providers"
  add_foreign_key "repository_permissions", "repositories"
  add_foreign_key "repository_permissions", "users"
  add_foreign_key "server_provider_permissions", "server_providers"
  add_foreign_key "server_provider_permissions", "users"
  add_foreign_key "server_provider_user_settings", "server_provider_permissions", column: "server_provider_user_id"
end
