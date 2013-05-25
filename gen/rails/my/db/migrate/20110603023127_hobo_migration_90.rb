class HoboMigration90 < ActiveRecord::Migration
  def self.up
    rename_column :accounts, :plan_period_start, :plan_last_invoice
    change_column :accounts, :plan_last_invoice, :string, :limit => 255
  end

  def self.down
    rename_column :accounts, :plan_last_invoice, :plan_period_start
    change_column :accounts, :plan_period_start, :datetime
  end
end
