class HoboMigration54 < ActiveRecord::Migration
  def self.up
    add_column :people, :system_id, :integer

    add_index :people, [:system_id]
  end

  def self.down
    remove_column :people, :system_id

    remove_index :people, :name => :index_people_on_system_id rescue ActiveRecord::StatementInvalid
  end
end
