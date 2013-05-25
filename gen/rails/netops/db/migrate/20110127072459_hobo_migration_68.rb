class HoboMigration68 < ActiveRecord::Migration
  def self.up
    drop_table :mails

    create_table :emails do |t|
      t.string   :email
      t.integer  :origin_id
      t.string   :template
      t.text     :kv_pairs
      t.text     :content
      t.string   :progress
      t.string   :final_status
      t.datetime :created_at
      t.datetime :updated_at
      t.integer  :system_id
      t.integer  :person_id
    end
    add_index :emails, [:origin_id]
    add_index :emails, [:system_id]
    add_index :emails, [:person_id]
  end

  def self.down
    create_table "mails", :force => true do |t|
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

    add_index "mails", ["origin_id"], :name => "index_mails_on_origin_id"
    add_index "mails", ["person_id"], :name => "index_mails_on_person_id"
    add_index "mails", ["system_id"], :name => "index_mails_on_system_id"

    drop_table :emails
  end
end
