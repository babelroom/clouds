class HoboMigration11 < ActiveRecord::Migration
  def self.up
    create_table :emails do |t|
      t.string   :email
      t.datetime :created_at
      t.datetime :updated_at
      t.integer  :owner_id
    end
    add_index :emails, [:owner_id]
  end

  def self.down
    drop_table :emails
  end
end
