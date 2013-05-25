class HoboMigration87 < ActiveRecord::Migration
  def self.up
    add_column :accounts, :plan_code, :string
  end

  def self.down
    remove_column :accounts, :plan_code
  end
end
