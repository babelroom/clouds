class HoboMigration53 < ActiveRecord::Migration
  def self.up
    add_column :people, :origin_id, :string
    remove_column :people, :system_id

    remove_index :people, :name => :index_people_on_system_id rescue ActiveRecord::StatementInvalid
    add_index :people, [:origin_id]
  end

  def self.down
    remove_column :people, :origin_id
    add_column :people, :system_id, :integer

    remove_index :people, :name => :index_people_on_origin_id rescue ActiveRecord::StatementInvalid
    add_index :people, [:system_id]
  end
end
