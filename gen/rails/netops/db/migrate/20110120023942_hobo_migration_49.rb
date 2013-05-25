class HoboMigration49 < ActiveRecord::Migration
  def self.up
    remove_column :conferences, :origin_ids

    remove_index :conferences, :name => :index_conferences_on_origin_ids rescue ActiveRecord::StatementInvalid
  end

  def self.down
    add_column :conferences, :origin_ids, :string

    add_index :conferences, [:origin_ids]
  end
end
