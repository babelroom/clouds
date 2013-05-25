class HoboMigration71 < ActiveRecord::Migration
  def self.up
    add_index :conferences, [:uri]
  end

  def self.down
    remove_index :conferences, :name => :index_conferences_on_uri rescue ActiveRecord::StatementInvalid
  end
end
