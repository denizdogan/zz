-module(issues_tests).

-include("test.hrl").

empty_test() ->
    ?assertEqual([], zz:issues([])).

leaf_atom_test() ->
    ?assertEqual(
        [#{path => [], code => not_integer}],
        zz:issues([not_integer])
    ).

multiple_leaves_test() ->
    ?assertEqual(
        [
            #{path => [], code => binary_too_short},
            #{path => [], code => regex_mismatch}
        ],
        zz:issues([binary_too_short, regex_mismatch])
    ).

list_path_test() ->
    {error, Errs} = zz:parse(zz:list(zz:integer()), [1, foo, 2, bar]),
    ?assertEqual(
        [
            #{path => [2], code => not_integer},
            #{path => [4], code => not_integer}
        ],
        zz:issues(Errs)
    ).

tuple_path_test() ->
    {error, Errs} = zz:parse(zz:tuple({zz:integer(), zz:binary()}), {foo, 1}),
    ?assertEqual(
        [
            #{path => [1], code => not_integer},
            #{path => [2], code => not_binary}
        ],
        zz:issues(Errs)
    ).

map_path_test() ->
    {error, Errs} = zz:parse(zz:map(#{name => zz:binary()}), #{name => 1}),
    ?assertEqual(
        [#{path => [name], code => not_binary}],
        zz:issues(Errs)
    ).

map_missing_key_test() ->
    {error, Errs} = zz:parse(zz:map(#{name => zz:binary()}), #{}),
    ?assertEqual(
        [#{path => [name], code => missing_key}],
        zz:issues(Errs)
    ).

nested_map_in_list_test() ->
    Z = zz:list(zz:map(#{age => zz:integer(#{min => 0})})),
    {error, Errs} = zz:parse(Z, [#{age => 1}, #{age => -1}, #{age => foo}]),
    ?assertEqual(
        [
            #{path => [2, age], code => integer_too_small},
            #{path => [3, age], code => not_integer}
        ],
        zz:issues(Errs)
    ).

unknown_keys_test() ->
    Z = zz:map(#{}, #{unknown_keys => strict}),
    {error, Errs} = zz:parse(Z, #{foo => 1, bar => 2}),
    [Issue] = zz:issues(Errs),
    #{path := Path, code := Code, keys := Keys} = Issue,
    ?assertEqual([], Path),
    ?assertEqual(unknown_keys, Code),
    true = is_list(Keys),
    ?assertEqual([bar, foo], lists:sort(Keys)).

no_match_test() ->
    Z = zz:union([zz:integer(), zz:binary()]),
    {error, Errs} = zz:parse(Z, foo),
    ?assertEqual(
        [
            #{
                path => [],
                code => no_match,
                branches => [
                    [#{path => [], code => not_integer}],
                    [#{path => [], code => not_binary}]
                ]
            }
        ],
        zz:issues(Errs)
    ).

deeply_nested_test() ->
    Z = zz:map(#{
        users => zz:list(zz:map(#{name => zz:binary()}))
    }),
    {error, Errs} = zz:parse(Z, #{users => [#{name => <<"a">>}, #{name => 1}]}),
    ?assertEqual(
        [#{path => [users, 2, name], code => not_binary}],
        zz:issues(Errs)
    ).
