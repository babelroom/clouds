class HoboMigration101 < ActiveRecord::Migration
  def self.up
    add_column :accounts, :plan_description, :text
    add_column :accounts, :change_to_plan_code, :string
    add_column :accounts, :changing_flag, :boolean
  end

  def self.down
    remove_column :accounts, :plan_description
    remove_column :accounts, :change_to_plan_code
    remove_column :accounts, :changing_flag
  end
end
