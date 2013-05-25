class HoboMigration96 < ActiveRecord::Migration
  def self.up
    create_table :countries do |t|
      t.string   :name
      t.string   :prefix
      t.datetime :created_at
      t.datetime :updated_at
    end
  end

  def self.down
    drop_table :countries
  end
end
