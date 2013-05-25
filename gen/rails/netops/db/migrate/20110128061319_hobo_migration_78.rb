class HoboMigration78 < ActiveRecord::Migration
  def self.up
    add_column :calls, :uuid, :string, :limit => 36

    add_index :calls, [:uuid], :unique => true
  end

  def self.down
    remove_column :calls, :uuid

    remove_index :calls, :name => :index_calls_on_uuid rescue ActiveRecord::StatementInvalid
  end
end
