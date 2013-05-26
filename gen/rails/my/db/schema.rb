# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130427061723) do

  create_table "accounts", :force => true do |t|
    t.string   "name"
    t.decimal  "balance",              :precision => 8, :scale => 2
    t.decimal  "balance_limit",        :precision => 8, :scale => 2
    t.decimal  "max_call_rate",        :precision => 8, :scale => 2
    t.integer  "max_users",                                          :default => 100
    t.integer  "max_duration",                                       :default => 240
    t.string   "rec_notification"
    t.string   "rec_policy"
    t.string   "external_token"
    t.integer  "rec_min"
    t.integer  "rec_max"
    t.boolean  "suppress_charges_col"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "owner_id"
    t.string   "plan_code"
    t.string   "external_code"
    t.text     "plan_usage"
    t.string   "plan_last_invoice"
    t.text     "plan_description"
    t.string   "change_to_plan_code"
    t.boolean  "changing_flag"
  end

  add_index "accounts", ["owner_id"], :name => "index_accounts_on_owner_id"

  create_table "billing_records", :force => true do |t|
    t.string   "title"
    t.string   "legal_name"
    t.string   "attention"
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "country"
    t.string   "phone"
    t.string   "url"
    t.string   "code"
    t.string   "billing_address1"
    t.string   "billing_address2"
    t.string   "billing_city"
    t.string   "billing_state"
    t.string   "billing_country"
    t.string   "billing_zip"
    t.string   "billing_phone"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "account_id"
  end

  add_index "billing_records", ["account_id"], :name => "index_billing_records_on_account_id"

  create_table "callees", :force => true do |t|
    t.string   "participant"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "conference_id"
    t.datetime "started"
    t.datetime "ended"
    t.text     "meta_data"
    t.string   "accounting_code"
    t.string   "accounting_desc"
    t.string   "notes"
    t.integer  "account_id"
    t.string   "number"
    t.string   "external_id"
  end

  add_index "callees", ["account_id"], :name => "index_callees_on_account_id"
  add_index "callees", ["conference_id"], :name => "index_callees_on_conference_id"

  create_table "colmodels", :force => true do |t|
    t.string   "jqgrid_id",  :limit => 30
    t.string   "elf",        :limit => 10
    t.text     "colmodel"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "conferences", :force => true do |t|
    t.string   "name"
    t.datetime "start"
    t.string   "config"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "owner_id"
    t.integer  "account_id"
    t.string   "pin"
    t.datetime "actual_start"
    t.datetime "actual_end"
    t.text     "participant_emails", :limit => 2147483647
    t.boolean  "is_deleted"
    t.datetime "deployed_at"
    t.string   "schedule"
    t.string   "uri"
    t.integer  "skin_id"
    t.text     "introduction"
    t.text     "access_config"
    t.string   "origin_data"
    t.integer  "origin_id"
  end

  add_index "conferences", ["account_id"], :name => "index_conferences_on_account_id"
  add_index "conferences", ["owner_id"], :name => "index_conferences_on_owner_id"
  add_index "conferences", ["skin_id"], :name => "index_conferences_on_skin_id"
  add_index "conferences", ["uri"], :name => "index_conferences_on_uri"

  create_table "countries", :force => true do |t|
    t.string   "name"
    t.string   "prefix"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "emails", :force => true do |t|
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "owner_id"
  end

  add_index "emails", ["owner_id"], :name => "index_emails_on_owner_id"

  create_table "invitations", :force => true do |t|
    t.string   "pin"
    t.string   "role"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "conference_id"
    t.integer  "user_id"
    t.string   "dialin"
    t.string   "token",         :limit => 40
    t.datetime "deployed_at"
    t.boolean  "is_deleted"
  end

  add_index "invitations", ["conference_id"], :name => "index_invitations_on_conference_id"
  add_index "invitations", ["token"], :name => "index_invitations_on_token"
  add_index "invitations", ["user_id"], :name => "index_invitations_on_user_id"

  create_table "media_files", :force => true do |t|
    t.string   "name"
    t.string   "content_type"
    t.integer  "size"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "conference_id"
    t.integer  "user_id"
    t.string   "upload_file_name"
    t.string   "upload_content_type"
    t.integer  "upload_file_size"
    t.datetime "upload_updated_at"
    t.integer  "slideshow_pages"
    t.string   "bucket"
    t.string   "length"
    t.integer  "multipage"
    t.string   "upload_url"
  end

  add_index "media_files", ["conference_id"], :name => "index_media_files_on_conference_id"
  add_index "media_files", ["user_id"], :name => "index_media_files_on_user_id"

  create_table "options", :force => true do |t|
    t.string   "table"
    t.integer  "table_id"
    t.string   "name"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "options", ["table", "table_id", "name"], :name => "index_options_on_table_and_table_id_and_name", :unique => true

  create_table "phones", :force => true do |t|
    t.string   "identifier"
    t.string   "dial_options"
    t.string   "call_options"
    t.string   "sms_carrier"
    t.string   "sms_identifier"
    t.string   "extension"
    t.integer  "delay",           :default => 0
    t.integer  "dial_timeout",    :default => 45
    t.boolean  "acknowledgement", :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "owner_id"
    t.string   "phone_type"
  end

  add_index "phones", ["owner_id"], :name => "index_phones_on_owner_id"

  create_table "pins", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "invitation_id"
    t.string   "pin",           :limit => 6
  end

  add_index "pins", ["pin"], :name => "index_pins_on_pin", :unique => true

  create_table "skins", :force => true do |t|
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.boolean  "immutable",   :default => false
    t.string   "preview_url"
  end

  create_table "tokens", :force => true do |t|
    t.string   "template"
    t.string   "link_key"
    t.datetime "expires"
    t.boolean  "is_deleted"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  add_index "tokens", ["user_id"], :name => "index_email_requests_on_user_id"
  add_index "tokens", ["user_id"], :name => "index_tokens_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "name"
    t.string   "email_address"
    t.boolean  "administrator",                           :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state",                                   :default => "active"
    t.datetime "key_timestamp"
    t.string   "last_name"
    t.string   "timezone",                                :default => "Pacific Time (US & Canada)"
    t.string   "company"
    t.string   "pin"
    t.datetime "deployed_at"
    t.string   "phone"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.string   "api_key"
    t.string   "avatar_small"
    t.string   "avatar_medium"
    t.string   "avatar_large"
    t.string   "email"
    t.string   "origin_data"
    t.integer  "origin_id"
  end

  add_index "users", ["email_address"], :name => "index_users_on_email_address"
  add_index "users", ["state"], :name => "index_users_on_state"

end
