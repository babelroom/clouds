class HoboMigration115 < ActiveRecord::Migration
  def self.up
    add_column :invitations, :is_deleted, :boolean
  end

  def self.down
    remove_column :invitations, :is_deleted
  end
end
