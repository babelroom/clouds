class HoboMigration80 < ActiveRecord::Migration
  def self.up
    create_table :colmodels do |t|
      t.string   :jqgrid_id, :length => 30
      t.string   :elf, :length => 10
      t.text     :colmodel
      t.datetime :created_at
      t.datetime :updated_at
    end
  end

  def self.down
    drop_table :colmodels
  end
end
