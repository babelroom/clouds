class HoboMigration88 < ActiveRecord::Migration
  def self.up
    add_column :accounts, :external_code, :string
  end

  def self.down
    remove_column :accounts, :external_code
  end
end
