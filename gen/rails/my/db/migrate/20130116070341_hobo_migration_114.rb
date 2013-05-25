class HoboMigration114 < ActiveRecord::Migration
  def self.up
    add_column :invitations, :deployed_at, :datetime
  end

  def self.down
    remove_column :invitations, :deployed_at
  end
end
