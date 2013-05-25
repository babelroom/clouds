class HoboMigration92 < ActiveRecord::Migration
  def self.up
    rename_column :calls, :notes, :meta_data
  end

  def self.down
    rename_column :calls, :meta_data, :notes
  end
end
