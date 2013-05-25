class HoboMigration92 < ActiveRecord::Migration
  def self.up
    add_column :conferences, :skin_id, :integer

    add_index :conferences, [:skin_id]
  end

  def self.down
    remove_column :conferences, :skin_id

    remove_index :conferences, :name => :index_conferences_on_skin_id rescue ActiveRecord::StatementInvalid
  end
end
