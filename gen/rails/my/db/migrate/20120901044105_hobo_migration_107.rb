class HoboMigration107 < ActiveRecord::Migration
  def self.up
    change_column :conferences, :participant_emails, :text, :limit => 4294967294
  end

  def self.down
    change_column :conferences, :participant_emails, :text
  end
end
