
#$db_create=#john
#$ws=##my Super Website
#$col_primary_key=db_schema:['PRIMARY KEY']
#$TODO=
#$system=my
#$col_boolean=#boolean
#$col_datetime=#datetime
#$col_integer=#integer
#$col_id=#integer
#$col_decimal=#decimal
#$col_string=#string
#$col_text=#text
#$col_timestamps={_:#created_at, type:$col_datetime},{_:#updated_at, type:$col_datetime}

{"$system":
[
    { _: #user,
    generators: [#rails_model,#rest_routes],
#    meta: [$db_create,{_:$ws, flags:[#a,#b]}],
    hobo_model_name: #hobo_user_model,
    rest_routes: [
        {_:#pk, pattern: "rgx: /(GET):\\/(users)\\/(\\d+)$/i, rgx_key: '_default_rgx_key', permfn: 'perm_the_same_user', dbfn: 'db_1_by_pk'", },
        ],
    columns: [
#| id                        | int(11)      | NO   | PRI | NULL                       | auto_increment |
#| crypted_password          | varchar(40)  | YES  |     | NULL                       |                |
#| salt                      | varchar(40)  | YES  |     | NULL                       |                |
#| remember_token            | varchar(255) | YES  |     | NULL                       |                |
#| remember_token_expires_at | datetime     | YES  |     | NULL                       |                |
        {_:#name, rails_flags:[#required], rest:[#pk]},
        {_:#email_address, type:#email_address, rails_map:{login:true}, index:true, rest:[#pk]},    # heavily overloaded with hobo ****, use to indicate !ephemeral
        {_:#administrator, type:$col_boolean, rails_map:{default:false}},
        $col_timestamps,

        # JR added @ TM
        #phone,
        #photo_file_name,
        #photo_content_type,
        {_:#photo_file_size, type:$col_integer},
        {_:#photo_updated_at, type:$col_datetime},

        # JR added
        {_:#deployed_at, type:$col_datetime},

        # JR added ---- these are all profile type things ...
#    last_name       :string, :required -- leave out the required, because we might not be able
#       to populate via conference invitation, and stuff breaks if a required field is not there
        {_:#last_name, rest:[#pk]},
        {_:#timezone, rails_map:{default:'Pacific Time (US & Canada)'}},
        {_:#company, rest:[#pk]},
        {_:#pin},
        # ---
        {_:#api_key},
        #avatar_small,
        #avatar_medium,
        #avatar_large,
        {_:#email, type:$col_string, rest:[#pk]},   # free of extra hobo **** semantics
        {_:#origin_data, type:$col_string, rest:[#pk]},
        {_:#origin_id, type:$col_id, rest:[#pk]},
        ],
    rails_extra: @schema/my/user.rb.sch,
    },
    { _: #conference,
#    meta: [$db_create,{_:#ws, flags:[#foo]}],
    generators: [#rails_model,#rest_routes],
    rest_routes: [
        {_:#pk, pattern: "rgx: /(GET):\\/(conferences)\\/(\\d+)$/i, rgx_key: '_default_rgx_key', permfn: 'perm_conference_owner_or_participant', dbfn: 'db_1_by_pk'", flags:{not_deleted:true}},
        {_:#cr, pattern: "rgx: /(POST):\\/(conferences)\\/?$/i, rgx_key: '_default_rgx_key', permfn: 'perm_valid_user', dbfn: 'db_create'", flags:{insert_uid_as:#owner_id}},
        {_:#up, pattern: "rgx: /(PUT):\\/(conferences)\\/(\\d+)$/i, rgx_key: '_default_rgx_key', permfn: 'perm_conference_owner_or_host', dbfn: 'db_update_by_pk'", flags:{not_deleted:true}},
        {_:#dl, pattern: "rgx: /(DELETE):\\/(conferences)\\/(\\d+)$/i, rgx_key: '_default_rgx_key', permfn: 'perm_conference_owner_or_host', dbfn: 'db_set_deleted_flag_by_pk'"},
        ],
    columns: [
        {_:#name, rest:[#pk,#cr,#up]},
        {_:#start, type:$col_datetime},
        {_:#config},
        $col_timestamps,
        {_:#deployed_at, type:$col_datetime},
        {_:#is_deleted, type:$col_boolean},
        {_:#schedule},          # NULL == template, (s)tanding, (o)nce, (e)veryday, week-(d)ays, (w)eekly, (b)i-weekly, (m)onthly, (q)uarter
        {_:#pin}, $TODO         # depreciated

        {_:#actual_start, type:$col_datetime},
        {_:#actual_end, type:$col_datetime},
        {_:#participant_emails, type:$col_text, rails_map:{limit:2147483647}},
        {_:#uri, index:true, rest:[#pk]},
        {_:#introduction, type:$col_text, rest:[#pk,#cr,#up]},
        {_:#access_config, type:$col_text, rest:[#pk,#cr,#up]},
        {_:#origin_data, type:$col_string, rest:[#pk,#cr,#up]},
        {_:#origin_id, type:$col_id, rest:[#pk,#cr,#up]},
        ],
    rails_extra: @schema/my/conference.rb.sch,
    },
    { _: #callee,
    generators: [#rails_model],
    columns: [
        {_:#started, type:$col_datetime},
        {_:#ended, type:$col_datetime},
        #participant,
        $col_timestamps,
    
# duration           
        #number,
        {_:#meta_data, type:$col_text},
        #accounting_code,
        #accounting_desc,
        #notes,
# unit cost ??       
# cost
# external billing references
        #external_id,
        ],
    rails_extra: @schema/my/callee.rb.sch,
    },
    { _: #account,
    generators: [#rails_model],
    columns: [
        #name,
        {_:#balance, type:$col_decimal, rails_map:{precision: 8, scale: 2}},
        {_:#balance_limit, type:$col_decimal, rails_map:{precision: 8, scale: 2}},
        {_:#max_call_rate, type:$col_decimal, rails_map:{precision: 8, scale: 2}},
        {_:#max_users, type:$col_integer, rails_map:{default:100}},
        {_:#max_duration, type:$col_integer, rails_map:{default:240}},
        #rec_notification,
        #rec_policy,
        #external_code,
        #external_token,
        {_:#rec_min, type:$col_integer},
        {_:#rec_max, type:$col_integer},
        {_:#suppress_charges_col, type:$col_boolean},
        #plan_code,
        {_:#plan_description, type:$col_text},  # think I actually want to depreciate this again
        {_:#plan_usage, type:$col_text},
        #plan_last_invoice,
        #change_to_plan_code,
        {_:#changing_flag, type:$col_boolean},
        $col_timestamps,
        ],
    rails_extra: @schema/my/account.rb.sch,
    },
    { _: #colmodel,
    generators: [#rails_model],
    columns: [
        {_:#jqgrid_id, type:$col_string, rails_map:{limit:30}},
        {_:#elf, type:$col_string, rails_map:{limit:10}},
        {_:#colmodel, type:$col_text},
        $col_timestamps,
        ],
    rails_extra: @schema/my/colmodel.rb.sch,
    },
    { _: #country,  # note this schema is depreciated, never (not yet?) used - JR 12/12
    generators: [#rails_model],
    columns: [
        #name,
        #prefix,
        $col_timestamps,
        ],
    rails_extra: @schema/my/country.rb.sch,
    },
    { _: #token,
    generators: [#rails_model],
    columns: [
        #template,
        #link_key,
        {_:#expires, type:$col_datetime},
        {_:#is_deleted, type:$col_boolean},
        $col_timestamps,
        ],
    rails_extra: @schema/my/email_request.rb.sch,
    },
    { _: #email,
    generators: [#rails_model],
    columns: [
        #email,
        $col_timestamps,
        ],
    rails_extra: @schema/my/email.rb.sch,
    },
    { _: #invitation,
    generators: [#rails_model],
    columns: [
        #pin,
        #dialin,    # TODO: big enough for full text? -- match dialin field in people table in netops
        #role,
        {_:#token, type:$col_string, rails_map:{limit:40, index: true}},    # depreciate soon
        $col_timestamps,
        {_:#deployed_at, type:$col_datetime},
        {_:#is_deleted, type:$col_boolean},
        ],
    rails_extra: @schema/my/invitation.rb.sch,
    },
    { _: #media_file,
    generators: [#rails_model,#rest_routes],
    rest_routes: [
        # added this but didn't use. should still be usabilty -- never tested
        {_:#av, pattern: "rgx: /(POST):\\/(avatar)\\/?$/i, rgx_key: '_default_rgx_key', permfn: 'perm_valid_user', dbfn: 'db_create'", flags:{insert_uid_as:#user_id}},
        ],
    columns: [
        #name,
        #content_type,
        {_:#size, type:$col_integer},
        #url,
        {_:#multipage, type:$col_integer},
        #upload_file_name,
        #upload_content_type,
        {_:#upload_file_size, type:$col_integer},
        {_:#upload_updated_at, type:$col_datetime},
        {_:#slideshow_pages, type:$col_integer},    # for netops
        #bucket,
        #length,
        $col_timestamps,
        {_:#upload_url, type:$col_string, rest:[#av]},
        ],
    rails_extra: @schema/my/media_file.rb.sch,
    },
    { _: #phone,
    generators: [#rails_model],
    columns: [
        #identifier,
        #phone_type,
        #dial_options,
        #call_options,
        #sms_carrier,
        #sms_identifier,
        #extension,
        {_:#delay, type:$col_integer, rails_map:{default:0}},
        {_:#dial_timeout, type:$col_integer, rails_map:{default:45}},
        {_:#acknowledgement, type:$col_boolean, rails_map:{default:true}},
        $col_timestamps,
        ],
    rails_extra: @schema/my/phone.rb.sch,
    },
    { _: #skin,
    generators: [#rails_model],
    columns: [
        {_:#name, type:$col_string, rails_flags:[#required, #unique]},
#    public      :boolean    # depreciate?
        {_:#immutable, type:$col_boolean, rails_map:{default:false}},
        #preview_url,
        {_:#body, type:$col_text},
        $col_timestamps,
        ],
    rails_extra: @schema/my/skin.rb.sch,
    },
    { _: #billing_record,
    generators: [#rails_model],
    columns: [
        #title,
        #legal_name,
        #attention,
        #address1,
        #address2,
        #city,
        #state,
        #zip,
        #country,
        #phone,
        #url,
        #code,
        #billing_address1,
        #billing_address2,
        #billing_city,
        #billing_state,
        #billing_country,
        #billing_zip,
        #billing_phone,
        $col_timestamps,
        ],
    rails_extra: @schema/my/billing_record.rb.sch,
    },
    { _: #guest,
    generators: [#verbatim],
    dest: "rails/$system/app/models/guest.rb",
    src: @schema/my/guest.rb.sch,
    },
    { _: #user_mailer,
    generators: [#verbatim],
    dest: "rails/$system/app/models/user_mailer.rb",
    src: @schema/my/user_mailer.rb.sch,
    },
    { _: #pin,
    generators: [#rails_model],
    columns: [
        $col_timestamps,
        {_:#pin, rails_map:{limit:6, index:true, unique:true}},
        {_:#invitation_id, type:$col_id},   # what about a cascading delete on this?
        ],
    },
    { _: #option,
    # there was a plan to use this for persisting table specific options
    # but it's on hold now
    # also not sure this table is going to fly with having a primary key
    # (and rails will implode without one)
    generators: [#rails_model],
    columns: [
        {_:#table, type:$col_string, rails_flags:[#required, #unique]}, # i.e. conference
        {_:#table_id, type:$col_id},             # i.e. 1234
        {_:#name, type:$col_string, rails_flags:[#required, #unique]},   # i.e. 'is_locked'
        {_:#value, type:$col_string},
        $col_timestamps,
        ],
    },
]
}

