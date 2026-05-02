-module(map_of_tests).

-include("test.hrl").

empty_map_test() ->
    Z = zz:map_of(zz:binary(), zz:integer()),
    ?assertEqual({ok, #{}}, zz:parse(Z, #{})).

binary_to_integer_test() ->
    Z = zz:map_of(zz:binary(), zz:integer()),
    ?assertEqual(
        {ok, #{<<"a">> => 1, <<"b">> => 2}},
        zz:parse(Z, #{<<"a">> => 1, <<"b">> => 2})
    ).

atom_to_binary_test() ->
    Z = zz:map_of(zz:atom(), zz:binary()),
    ?assertEqual(
        {ok, #{foo => <<"x">>, bar => <<"y">>}},
        zz:parse(Z, #{foo => <<"x">>, bar => <<"y">>})
    ).

non_map_input_test() ->
    Z = zz:map_of(zz:binary(), zz:integer()),
    ?assertEqual({error, [not_map]}, zz:parse(Z, [])).

bad_value_test() ->
    Z = zz:map_of(zz:binary(), zz:integer()),
    ?assertEqual(
        {error, [{map_value, <<"a">>, [not_integer]}]},
        zz:parse(Z, #{<<"a">> => foo})
    ).

bad_key_test() ->
    Z = zz:map_of(zz:binary(), zz:integer()),
    ?assertEqual(
        {error, [{map_key, 1, [not_binary]}]},
        zz:parse(Z, #{1 => 2})
    ).

bad_key_and_bad_value_test() ->
    Z = zz:map_of(zz:binary(), zz:integer()),
    %% Both keys are non-binary (key error); values vary.
    {error, Errs} = zz:parse(Z, #{1 => 2, foo => bar}),
    %% Map ordering is not guaranteed; check by membership.
    ?assertEqual(2, length(Errs)),
    true = lists:any(
        fun
            ({map_key, 1, [not_binary]}) -> true;
            (_) -> false
        end,
        Errs
    ),
    true = lists:any(
        fun
            ({map_key, foo, [not_binary]}) -> true;
            (_) -> false
        end,
        Errs
    ).

issues_value_test() ->
    Z = zz:map_of(zz:binary(), zz:integer()),
    {error, Errs} = zz:parse(Z, #{<<"a">> => foo}),
    ?assertEqual(
        [#{path => [<<"a">>], code => not_integer}],
        zz:issues(Errs)
    ).

issues_key_test() ->
    Z = zz:map_of(zz:binary(), zz:integer()),
    {error, Errs} = zz:parse(Z, #{1 => 2}),
    [Issue] = zz:issues(Errs),
    #{path := Path, code := Code, key := Key, errors := Inner} = Issue,
    ?assertEqual([], Path),
    ?assertEqual(invalid_key, Code),
    ?assertEqual(1, Key),
    ?assertEqual([#{path => [], code => not_binary}], Inner).

nested_in_schema_test() ->
    %% map_of nested as a value parser inside a regular map schema.
    Z = zz:map(#{
        counts => zz:map_of(zz:binary(), zz:integer())
    }),
    Input = #{counts => #{<<"a">> => 1, <<"b">> => 2}},
    ?assertEqual({ok, Input}, zz:parse(Z, Input)).
