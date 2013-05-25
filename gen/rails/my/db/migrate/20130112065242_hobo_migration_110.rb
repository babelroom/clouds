class HoboMigration110 < ActiveRecord::Migration
  def self.up
    rename_column :pins, :user_id, :invitation_id
  end

  def self.down
    rename_column :pins, :invitation_id, :user_id
  end
end
