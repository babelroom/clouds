class HoboMigration55 < ActiveRecord::Migration
  def self.up
    add_index :people, [:email]
  end

  def self.down
    remove_index :people, :name => :index_people_on_email rescue ActiveRecord::StatementInvalid
  end
end
