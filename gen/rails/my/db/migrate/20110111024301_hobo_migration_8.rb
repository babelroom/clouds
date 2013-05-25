class HoboMigration8 < ActiveRecord::Migration
  def self.up
    add_column :callees, :answer, :decimal, :scale => 1, :precision => 8
    add_column :callees, :accept, :decimal, :scale => 1, :precision => 8
    add_column :callees, :retries, :integer
    add_column :callees, :fail_reason, :string
    add_column :callees, :destination, :string
    add_column :callees, :type, :string

    add_column :participants, :name, :string
    add_column :participants, :email, :string
    add_column :participants, :role, :string
    add_column :participants, :status, :string
  end

  def self.down
    remove_column :callees, :answer
    remove_column :callees, :accept
    remove_column :callees, :retries
    remove_column :callees, :fail_reason
    remove_column :callees, :destination
    remove_column :callees, :type

    remove_column :participants, :name
    remove_column :participants, :email
    remove_column :participants, :role
    remove_column :participants, :status
  end
end
