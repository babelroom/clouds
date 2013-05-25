class HoboMigration51 < ActiveRecord::Migration
  def self.up
    add_column :conferences, :participant_emails, :text

    change_column :users, :timezone, :string, :limit => 255, :default => "Pacific Time (US & Canada)"
  end

  def self.down
    remove_column :conferences, :participant_emails

    change_column :users, :timezone, :string, :default => "US/Pacific"
  end
end
