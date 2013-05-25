class HoboMigration66 < ActiveRecord::Migration
  def self.up
    add_column :invitations, :dialin, :string
  end

  def self.down
    remove_column :invitations, :dialin
  end
end
