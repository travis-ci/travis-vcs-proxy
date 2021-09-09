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

ActiveRecord::Schema.define(version: 2021_08_18_115729) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "commits", force: :cascade do |t|
    t.string "sha", null: false
    t.integer "user_id", null: false
    t.integer "repository_id", null: false
    t.integer "ref_id", null: false
    t.string "message"
    t.datetime "committed_at", null: false
    t.datetime "created_at", null: false
    t.index ["ref_id", "sha"], name: "index_commits_on_ref_id_and_sha"
    t.index ["repository_id"], name: "index_commits_on_repository_id"
    t.index ["user_id"], name: "index_commits_on_user_id"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "pull_requests", force: :cascade do |t|
    t.integer "base_id", null: false
    t.integer "head_id", null: false
    t.integer "repository_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at"
    t.integer "number"
    t.index ["repository_id"], name: "index_pull_requests_on_repository_id"
    t.index ["user_id"], name: "index_pull_requests_on_user_id"
  end

  create_table "refs", force: :cascade do |t|
    t.string "name", null: false
    t.integer "type", null: false
    t.integer "repository_id", null: false
    t.index ["repository_id", "type", "name"], name: "index_refs_on_repository_id_and_type_and_name", unique: true
  end

  create_table "repositories", force: :cascade do |t|
    t.string "name", null: false
    t.string "url", null: false
    t.integer "server_provider_id", null: false
    t.datetime "last_synced_at"
    t.index ["server_provider_id", "name"], name: "index_repositories_on_server_provider_id_and_name", unique: true
  end

  create_table "repository_permissions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "repository_id", null: false
    t.integer "permission", null: false
    t.index ["repository_id"], name: "index_repository_permissions_on_repository_id"
    t.index ["user_id"], name: "index_repository_permissions_on_user_id"
  end

  create_table "server_provider_permissions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "server_provider_id", null: false
    t.integer "permission", null: false
    t.index ["server_provider_id"], name: "index_server_provider_permissions_on_server_provider_id"
    t.index ["user_id"], name: "index_server_provider_permissions_on_user_id"
  end

  create_table "server_provider_user_settings", force: :cascade do |t|
    t.string "username", null: false
    t.string "value", null: false
    t.integer "server_provider_user_id", null: false
    t.boolean "is_syncing"
    t.index ["server_provider_user_id"], name: "index_server_provider_user_settings_on_server_provider_user_id"
  end

  create_table "server_providers", force: :cascade do |t|
    t.string "name", null: false
    t.string "url", null: false
    t.string "type", null: false
    t.string "listener_token"
    t.index ["listener_token"], name: "index_server_providers_on_listener_token", unique: true
    t.index ["type", "url"], name: "index_server_providers_on_type_and_url", unique: true
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
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.string "encrypted_otp_secret"
    t.string "encrypted_otp_secret_iv"
    t.string "encrypted_otp_secret_salt"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login"
    t.string "otp_backup_codes", array: true
    t.string "jti"
    t.string "confirmation_token"
    t.datetime "confirmation_sent_at"
    t.datetime "confirmed_at"
    t.string "unconfirmed_email"
    t.string "type", default: "", null: false
    t.datetime "created_at", null: false
    t.boolean "active", default: true
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
  end

  create_table "webhooks", force: :cascade do |t|
    t.bigint "repository_id"
    t.string "name"
    t.string "url"
    t.boolean "active"
    t.boolean "insecure_ssl"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["repository_id"], name: "index_webhooks_on_repository_id"
  end

  add_foreign_key "commits", "refs"
  add_foreign_key "commits", "repositories"
  add_foreign_key "commits", "users"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "users", column: "resource_owner_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "users", column: "resource_owner_id"
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
  add_foreign_key "webhooks", "repositories"
end
