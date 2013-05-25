class HoboMigration9 < ActiveRecord::Migration
  def self.up
    add_column :conferences, :owner_id, :integer

    add_index :conferences, [:owner_id]
  end

  def self.down
    remove_column :conferences, :owner_id

    remove_index :conferences, :name => :index_conferences_on_owner_id rescue ActiveRecord::StatementInvalid
  end
end
