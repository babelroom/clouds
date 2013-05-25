class HoboMigration41 < ActiveRecord::Migration
  def self.up
    add_column :conferences, :who_can_invite, :string
    add_column :conferences, :transcription_access, :string
  end

  def self.down
    remove_column :conferences, :who_can_invite
    remove_column :conferences, :transcription_access
  end
end
