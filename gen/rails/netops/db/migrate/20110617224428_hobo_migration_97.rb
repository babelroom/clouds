class HoboMigration97 < ActiveRecord::Migration
  def self.up
    add_column :people, :token, :string, :limit => 40

    add_index :people, [:token]
  end

  def self.down
    remove_column :people, :token

    remove_index :people, :name => :index_people_on_token rescue ActiveRecord::StatementInvalid
  end
end
