class HoboMigration72 < ActiveRecord::Migration
  def self.up
    remove_index :conferences, :name => :index_conferences_on_uri rescue ActiveRecord::StatementInvalid
  end

  def self.down
    add_index :conferences, [:uri]
  end
end
