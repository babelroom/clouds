class HoboMigration50 < ActiveRecord::Migration
  def self.up
    add_column :conferences, :origin_id, :string

    add_index :conferences, [:origin_id]
  end

  def self.down
    remove_column :conferences, :origin_id

    remove_index :conferences, :name => :index_conferences_on_origin_id rescue ActiveRecord::StatementInvalid
  end
end
