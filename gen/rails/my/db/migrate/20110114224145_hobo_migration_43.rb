class HoboMigration43 < ActiveRecord::Migration
  def self.up
    change_column :conferences, :play_chimes, :string, :limit => 255
    change_column :conferences, :host_advance_start, :string, :limit => 255
    change_column :conferences, :record, :string, :limit => 255
  end

  def self.down
    change_column :conferences, :play_chimes, :boolean
    change_column :conferences, :host_advance_start, :integer
    change_column :conferences, :record, :boolean
  end
end
