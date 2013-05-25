class HoboMigration60 < ActiveRecord::Migration
  def self.up
    remove_column :systems, :description
    remove_column :systems, :configuration
  end

  def self.down
    add_column :systems, :description, :text
    add_column :systems, :configuration, :string
  end
end
