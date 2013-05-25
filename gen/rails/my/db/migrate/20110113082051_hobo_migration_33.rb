class HoboMigration33 < ActiveRecord::Migration
  def self.up
    add_column :phones, :phone_type, :string
  end

  def self.down
    remove_column :phones, :phone_type
  end
end
