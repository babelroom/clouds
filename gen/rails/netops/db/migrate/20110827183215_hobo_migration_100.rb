class HoboMigration100 < ActiveRecord::Migration
  def self.up
    add_index :webhooks, [:final_status]
  end

  def self.down
    remove_index :webhooks, :name => :index_webhooks_on_final_status rescue ActiveRecord::StatementInvalid
  end
end
