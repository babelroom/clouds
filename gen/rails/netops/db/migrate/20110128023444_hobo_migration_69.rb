class HoboMigration69 < ActiveRecord::Migration
  def self.up
    add_column :calls, :deployed_at, :datetime
    add_column :calls, :conference_id, :integer
    add_column :calls, :person_id, :integer

    add_index :calls, [:conference_id]
    add_index :calls, [:person_id]
  end

  def self.down
    remove_column :calls, :deployed_at
    remove_column :calls, :conference_id
    remove_column :calls, :person_id

    remove_index :calls, :name => :index_calls_on_conference_id rescue ActiveRecord::StatementInvalid
    remove_index :calls, :name => :index_calls_on_person_id rescue ActiveRecord::StatementInvalid
  end
end
