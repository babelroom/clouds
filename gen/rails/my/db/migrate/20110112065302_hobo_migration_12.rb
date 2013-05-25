class HoboMigration12 < ActiveRecord::Migration
  def self.up
    create_table :recordings do |t|
      t.datetime :created_at
      t.datetime :updated_at
    end
  end

  def self.down
    drop_table :recordings
  end
end
