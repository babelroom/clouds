class HoboMigration108 < ActiveRecord::Migration
  def self.up
    change_column :conferences, :participant_emails, :text, :limit => 4294967295
  end

  def self.down
    change_column :conferences, :participant_emails, :text, :limit => 2147483647
  end
end
