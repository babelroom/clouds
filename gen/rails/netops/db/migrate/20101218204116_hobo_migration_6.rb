class HoboMigration6 < ActiveRecord::Migration
  def self.up
    add_column :interconnects, :did, :string
    add_column :interconnects, :config, :string
  end

  def self.down
    remove_column :interconnects, :did
    remove_column :interconnects, :config
  end
end
