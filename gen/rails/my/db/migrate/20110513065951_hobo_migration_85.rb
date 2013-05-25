class HoboMigration85 < ActiveRecord::Migration
  def self.up
    rename_column :accounts, :transcription_options, :external_token
  end

  def self.down
    rename_column :accounts, :external_token, :transcription_options
  end
end
