class HoboMigration5 < ActiveRecord::Migration
  def self.up
    rename_column :interconnects, :description, :notes
  end

  def self.down
    rename_column :interconnects, :notes, :description
  end
end
