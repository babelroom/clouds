class HoboMigration62 < ActiveRecord::Migration
  def self.up
    add_column :systems, :system_type, :string
  end

  def self.down
    remove_column :systems, :system_type
  end
end
