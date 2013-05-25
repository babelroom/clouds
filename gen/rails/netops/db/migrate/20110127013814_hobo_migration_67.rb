class HoboMigration67 < ActiveRecord::Migration
  def self.up
    add_index :mails, [:origin_id]
  end

  def self.down
    remove_index :mails, :name => :index_mails_on_origin_id rescue ActiveRecord::StatementInvalid
  end
end
