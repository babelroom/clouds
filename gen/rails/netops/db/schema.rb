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

ActiveRecord::Schema.define(:version => 20110827183215) do

  create_table "calls", :force => true do |t|
    t.datetime "started"
    t.datetime "ended"
    t.text     "meta_data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deployed_at"
    t.integer  "conference_id"
    t.integer  "person_id"
    t.string   "uuid",          :limit => 36
  end

  add_index "calls", ["conference_id"], :name => "index_calls_on_conference_id"
  add_index "calls", ["person_id"], :name => "index_calls_on_person_id"
  add_index "calls", ["uuid"], :name => "index_calls_on_uuid", :unique => true

  create_table "colmodels", :force => true do |t|
    t.string   "jqgrid_id"
    t.string   "elf"
    t.text     "colmodel"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "conferences", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "system_id"
    t.string   "fs_server"
    t.datetime "start"
    t.string   "origin_id"
    t.boolean  "is_deleted"
    t.datetime "actual_start"
    t.datetime "actual_end"
    t.string   "schedule"
    t.string   "state"
    t.string   "conference_key"
  end

  add_index "conferences", ["origin_id"], :name => "index_conferences_on_origin_id"
  add_index "conferences", ["system_id"], :name => "index_conferences_on_system_id"

  create_table "emails", :force => true do |t|
    t.string   "email"
    t.integer  "origin_id"
    t.string   "template"
    t.text     "kv_pairs"
    t.text     "content"
    t.string   "progress"
    t.string   "final_status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "system_id"
    t.integer  "person_id"
  end

  add_index "emails", ["origin_id"], :name => "index_emails_on_origin_id"
  add_index "emails", ["person_id"], :name => "index_emails_on_person_id"
  add_index "emails", ["system_id"], :name => "index_emails_on_system_id"

  create_table "interconnects", :force => true do |t|
    t.string   "name"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "did"
    t.string   "config"
  end

  create_table "job_triggers", :force => true do |t|
    t.integer  "interval_ms"
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "jobs", :force => true do |t|
    t.string   "name"
    t.integer  "pid"
    t.text     "parameters"
    t.datetime "started"
    t.datetime "ended"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "script_name"
  end

  add_index "jobs", ["user_id"], :name => "index_jobs_on_user_id"

  create_table "logs", :force => true do |t|
    t.string   "name"
    t.string   "table"
    t.integer  "id_in_table"
    t.string   "content_type"
    t.string   "path"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "people", :force => true do |t|
    t.string   "name"
    t.string   "dialout"
    t.string   "email"
    t.string   "pin"
    t.string   "dialin"
    t.string   "configuration"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "conference_id"
    t.boolean  "is_deleted"
    t.datetime "deployed_at"
    t.string   "fs_server"
    t.string   "origin_id"
    t.integer  "system_id"
    t.string   "last_name"
    t.string   "token",         :limit => 40
  end

  add_index "people", ["conference_id"], :name => "index_people_on_conference_id"
  add_index "people", ["email"], :name => "index_people_on_email"
  add_index "people", ["origin_id"], :name => "index_people_on_origin_id"
  add_index "people", ["system_id"], :name => "index_people_on_system_id"
  add_index "people", ["token"], :name => "index_people_on_token"

  create_table "pins", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "pin",           :limit => 6
    t.string   "email"
    t.integer  "person_id"
    t.integer  "conference_id"
    t.integer  "system_id"
  end

  add_index "pins", ["pin"], :name => "index_pins_on_pin", :unique => true

  create_table "script_formats", :force => true do |t|
    t.string   "name"
    t.string   "view"
    t.string   "validation"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "scripts", :force => true do |t|
    t.string   "name"
    t.datetime "version"
    t.boolean  "is_deleted"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "startup"
    t.integer  "script_format_id"
  end

  add_index "scripts", ["script_format_id"], :name => "index_scripts_on_script_format_id"

  create_table "server_services", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "service_metrics", :force => true do |t|
    t.string   "name"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "service_id"
  end

  add_index "service_metrics", ["service_id"], :name => "index_service_metrics_on_service_id"

  create_table "services", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "systems", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "access"
    t.text     "notes"
    t.string   "system_type"
    t.string   "config_key"
  end

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
  end

  add_index "users", ["state"], :name => "index_users_on_state"

  create_table "webhooks", :force => true do |t|
    t.string   "uri"
    t.text     "json"
    t.text     "body"
    t.string   "progress"
    t.string   "final_status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "webhooks", ["final_status"], :name => "index_webhooks_on_final_status"

end
