class HoboMigration86 < ActiveRecord::Migration
  def self.up
    add_column :callees, :external_id, :string
  end

  def self.down
    remove_column :callees, :external_id
  end
end
