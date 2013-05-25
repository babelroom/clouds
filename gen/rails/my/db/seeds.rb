# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
    # master conference template should be id == '1'
    Conference.create(
        :created_at => Time.now,
        :updated_at => Time.now,

#leave last
        :skin_id => 1,
        :name => 'Master Conference Template'
    )

    # master account
    Account.create(
        :balance => 0.00,
        :balance_limit => 0.00,
        :max_call_rate => 0.00,
        :max_users => 100,
        :max_duration => 240,
        :plan_code => 'free',
        :created_at => Time.now,
        :updated_at => Time.zone.now,

#leave last
        :name => 'Primary Account'
    )

    # default skin should be == '1'
    Skin.create(
        :created_at => Time.now,
        :updated_at => Time.now,

        :immutable => true,
        :name => 'Default skin (readonly)'
    )


