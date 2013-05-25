class HoboMigration76 < ActiveRecord::Migration
  def self.up
    remove_column :calls, :caller_id

    remove_index :calls, :name => :index_calls_on_caller_id rescue ActiveRecord::StatementInvalid
  end

  def self.down
    add_column :calls, :caller_id, :string

    add_index :calls, [:caller_id]
  end
end
