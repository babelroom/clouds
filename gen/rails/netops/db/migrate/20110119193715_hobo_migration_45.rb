class HoboMigration45 < ActiveRecord::Migration
  def self.up
    add_column :servers, :notes, :text
  end

  def self.down
    remove_column :servers, :notes
  end
end
