class HoboMigration89 < ActiveRecord::Migration
  def self.up
    add_column :accounts, :plan_usage, :text
    add_column :accounts, :plan_period_start, :datetime
  end

  def self.down
    remove_column :accounts, :plan_usage
    remove_column :accounts, :plan_period_start
  end
end
