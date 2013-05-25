class HoboMigration40 < ActiveRecord::Migration
  def self.up
    add_column :conferences, :pin, :string
    add_column :conferences, :type, :string
    add_column :conferences, :tracker, :string
    add_column :conferences, :play_chimes, :boolean
    add_column :conferences, :announce_participants, :string
    add_column :conferences, :waiting_room, :string
    add_column :conferences, :initial_mute, :string
    add_column :conferences, :dashboard_access, :string
    add_column :conferences, :host_advance_start, :integer
    add_column :conferences, :record, :boolean
    add_column :conferences, :transcription, :string
    add_column :conferences, :transcirption_access, :string
  end

  def self.down
    remove_column :conferences, :pin
    remove_column :conferences, :type
    remove_column :conferences, :tracker
    remove_column :conferences, :play_chimes
    remove_column :conferences, :announce_participants
    remove_column :conferences, :waiting_room
    remove_column :conferences, :initial_mute
    remove_column :conferences, :dashboard_access
    remove_column :conferences, :host_advance_start
    remove_column :conferences, :record
    remove_column :conferences, :transcription
    remove_column :conferences, :transcirption_access
  end
end
