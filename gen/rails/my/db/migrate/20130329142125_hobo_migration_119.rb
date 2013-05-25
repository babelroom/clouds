class HoboMigration119 < ActiveRecord::Migration
  def self.up
    remove_column :conferences, :record
    remove_column :conferences, :meeting_type
    remove_column :conferences, :play_chimes
    remove_column :conferences, :tracker
    remove_column :conferences, :announce_participants
    remove_column :conferences, :transcription
    remove_column :conferences, :transcription_access
    remove_column :conferences, :initial_mute
    remove_column :conferences, :host_advance_start
    remove_column :conferences, :who_can_invite
    remove_column :conferences, :waiting_room
    remove_column :conferences, :dashboard_access
  end

  def self.down
    add_column :conferences, :record, :string
    add_column :conferences, :meeting_type, :string
    add_column :conferences, :play_chimes, :string
    add_column :conferences, :tracker, :string
    add_column :conferences, :announce_participants, :string
    add_column :conferences, :transcription, :string
    add_column :conferences, :transcription_access, :string
    add_column :conferences, :initial_mute, :string
    add_column :conferences, :host_advance_start, :string
    add_column :conferences, :who_can_invite, :string
    add_column :conferences, :waiting_room, :string
    add_column :conferences, :dashboard_access, :string
  end
end
