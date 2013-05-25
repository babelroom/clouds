class HoboMigration48 < ActiveRecord::Migration
  def self.up
    add_index :conferences, [:origin_ids]
  end

  def self.down
    remove_index :conferences, :name => :index_conferences_on_origin_ids rescue ActiveRecord::StatementInvalid
  end
end
