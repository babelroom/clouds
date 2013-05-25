class HoboMigration98 < ActiveRecord::Migration
  def self.up
    create_table :webhooks do |t|
      t.string   :uri
      t.text     :headers
      t.text     :body
      t.string   :progress
      t.string   :final_status
      t.datetime :created_at
      t.datetime :updated_at
    end
  end

  def self.down
    drop_table :webhooks
  end
end
