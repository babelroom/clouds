class HoboMigration71 < ActiveRecord::Migration
  def self.up
    add_index :calls, [:caller_id]
  end

  def self.down
    remove_index :calls, :name => :index_calls_on_caller_id rescue ActiveRecord::StatementInvalid
  end
end
