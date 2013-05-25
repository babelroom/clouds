class HoboMigration2 < ActiveRecord::Migration
  def self.up
    create_table :jobs do |t|
      t.string    :name
      t.integer   :pid
      t.text      :parameters
      t.timestamp :started
      t.timestamp :ended
      t.string    :status
      t.datetime  :created_at
      t.datetime  :updated_at
      t.integer   :user_id
    end
    add_index :jobs, [:user_id]

    create_table :service_metrics do |t|
      t.string   :name
      t.string   :value
      t.datetime :created_at
      t.datetime :updated_at
      t.integer  :service_id
    end
    add_index :service_metrics, [:service_id]

    create_table :server_services do |t|
      t.datetime :created_at
      t.datetime :updated_at
    end

    create_table :services do |t|
      t.string   :name
      t.datetime :created_at
      t.datetime :updated_at
    end

    create_table :job_triggers do |t|
      t.integer  :interval_ms
      t.string   :name
      t.text     :description
      t.datetime :created_at
      t.datetime :updated_at
    end

    create_table :servers do |t|
      t.string   :name
      t.integer  :ipv4
      t.string   :cluster
      t.string   :group
      t.datetime :created_at
      t.datetime :updated_at
    end

    create_table :script_formats do |t|
      t.string   :name
      t.string   :view
      t.string   :validation
      t.text     :notes
      t.datetime :created_at
      t.datetime :updated_at
    end

    create_table :scripts do |t|
      t.string    :name
      t.timestamp :version
      t.boolean   :is_deleted
      t.text      :description
      t.datetime  :created_at
      t.datetime  :updated_at
    end
  end

  def self.down
    drop_table :jobs
    drop_table :service_metrics
    drop_table :server_services
    drop_table :services
    drop_table :job_triggers
    drop_table :servers
    drop_table :script_formats
    drop_table :scripts
  end
end
