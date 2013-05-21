
{#conference_options:
[
    { _: #access_config,
    generators: [#js_options],
    a_top_level_field: #john,
    fields: [
        {_:#is_locked, type: #checkbox, default: true, description: "this is a description" },
        {_:#is_locked, type: {
                    "nested": "one_level", nested_furter:{nested: #two_levels},
                    },
                default: true, description: "this is a description" },
        {number: 23, bool: true, null: null},
        {float: 1.22, exp: 1e10, nexp: 1e-10},  # my tpl to parse json fails the 1e-10 --- FYI
        {a: 0.22, b: 1.22, c: 10.22, d: #2., e: #01.2},
        ],
    },
]
}

