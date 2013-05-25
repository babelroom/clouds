class HoboMigration74 < ActiveRecord::Migration
  def self.up
    remove_column :calls, :uuid

    remove_index :calls, :name => :index_calls_on_caller_id rescue ActiveRecord::StatementInvalid
  end

  def self.down
    add_column :calls, :uuid, :string, :limit => 36

    add_index :calls, [:caller_id]
  end
end
