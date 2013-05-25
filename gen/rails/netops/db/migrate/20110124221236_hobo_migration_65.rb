class HoboMigration65 < ActiveRecord::Migration
  def self.up
    add_column :pins, :email, :string
    add_column :pins, :person_id, :integer
    add_column :pins, :conference_id, :integer
    add_column :pins, :system_id, :integer
  end

  def self.down
    remove_column :pins, :email
    remove_column :pins, :person_id
    remove_column :pins, :conference_id
    remove_column :pins, :system_id
  end
end
