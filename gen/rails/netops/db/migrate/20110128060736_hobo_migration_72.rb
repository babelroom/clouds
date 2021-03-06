class HoboMigration72 < ActiveRecord::Migration
  def self.up
    remove_index :calls, :name => :index_calls_on_caller_id rescue ActiveRecord::StatementInvalid
    add_index :calls, [:caller_id], :unique => true
  end

  def self.down
    remove_index :calls, :name => :index_calls_on_caller_id rescue ActiveRecord::StatementInvalid
    add_index :calls, [:caller_id]
  end
end
