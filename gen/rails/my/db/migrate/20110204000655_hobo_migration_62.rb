class HoboMigration62 < ActiveRecord::Migration
  def self.up
    create_table :email_requests do |t|
      t.string   :template
      t.string   :key
      t.datetime :expires
      t.boolean  :is_deleted
      t.datetime :created_at
      t.datetime :updated_at
      t.integer  :user_id
    end
    add_index :email_requests, [:user_id]
  end

  def self.down
    drop_table :email_requests
  end
end
