class HoboMigration66 < ActiveRecord::Migration
  def self.up
    create_table :mails do |t|
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
    add_index :mails, [:system_id]
    add_index :mails, [:person_id]
  end

  def self.down
    drop_table :mails
  end
end
