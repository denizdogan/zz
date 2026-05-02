-module(zz_tests).

-include("test.hrl").

parse_delegates_test() ->
    Z = fun(X) -> {ok, {wrapped, X}} end,
    ?assertEqual({ok, {wrapped, 42}}, zz:parse(Z, 42)),
    ?assertEqual({ok, {wrapped, foo}}, zz:parse(Z, foo)).

parse_propagates_error_test() ->
    Z = fun(_) -> {error, [boom]} end,
    ?assertEqual({error, [boom]}, zz:parse(Z, anything)),
    ?assertEqual({error, [boom]}, zz:parse(Z, 42)).

%%%===========================================================================
%%% list-of-list combinations
%%%===========================================================================

list_of_boolean_test() ->
    Z = zz:list(zz:boolean()),
    ?assertEqual({ok, [true, false]}, Z([true, false])).

list_of_list_first_position_error_test() ->
    Z = zz:list(zz:list(zz:boolean())),
    ?assertEqual({error, [{list, 1, [not_list]}]}, Z([true])).

list_of_list_second_position_error_test() ->
    Z = zz:list(zz:list(zz:boolean())),
    ?assertEqual({error, [{list, 2, [not_list]}]}, Z([[true, true], true])).

triple_nested_list_ok_test() ->
    Z = zz:list(zz:list(zz:list(zz:boolean()))),
    ?assertEqual({ok, [[[true, false], [true]]]}, Z([[[true, false], [true]]])).

triple_nested_list_inner_not_list_test() ->
    Z = zz:list(zz:list(zz:list(zz:boolean()))),
    ?assertEqual(
        {error, [{list, 2, [{list, 3, [not_list]}]}]},
        Z([[[true, false], [true]], [[false, false, false], [true], 123]])
    ).

triple_nested_list_leaf_not_boolean_test() ->
    Z = zz:list(zz:list(zz:list(zz:boolean()))),
    ?assertEqual(
        {error, [{list, 2, [{list, 3, [{list, 5, [not_boolean]}]}]}]},
        Z([
            [[true, false], [true]],
            [[false, false, false], [true], [false, false, false, true, 123]]
        ])
    ).

%%%===========================================================================
%%% map-with-element combinations
%%%===========================================================================

map_with_boolean_value_ok_test() ->
    Z = zz:map(#{foo => zz:boolean()}),
    ?assertEqual({ok, #{foo => true}}, Z(#{foo => true})).

map_with_boolean_value_error_test() ->
    Z = zz:map(#{foo => zz:boolean()}),
    ?assertEqual({error, [{map, foo, [not_boolean]}]}, Z(#{foo => 123})).

list_of_map_value_error_test() ->
    Z = zz:list(zz:map(#{foo => zz:boolean()})),
    ?assertEqual({error, [{list, 1, [{map, foo, [not_boolean]}]}]}, Z([#{foo => 123}])).

list_of_map_mixed_errors_test() ->
    Z = zz:list(zz:map(#{foo => zz:boolean()})),
    ?assertEqual(
        {error, [
            {list, 1, [{map, foo, [not_boolean]}]},
            {list, 4, [{map, foo, missing_key}]}
        ]},
        Z([#{foo => 123}, #{foo => true}, #{foo => false}, #{bar => true}])
    ).

%%%===========================================================================
%%% optional in map schemas
%%%===========================================================================

optional_absent_test() ->
    Z = zz:map(#{foo => zz:optional(zz:binary(#{}))}),
    ?assertEqual({ok, #{}}, Z(#{bar => 123})).

optional_present_valid_test() ->
    Z = zz:map(#{foo => zz:optional(zz:binary(#{}))}),
    ?assertEqual({ok, #{foo => <<>>}}, Z(#{foo => <<>>})).

optional_present_invalid_test() ->
    Z = zz:map(#{foo => zz:optional(zz:binary(#{}))}),
    ?assertEqual({error, [{map, foo, [not_binary]}]}, Z(#{foo => 123})).

optional_input_not_map_test() ->
    Z = zz:map(#{foo => zz:optional(zz:binary(#{}))}),
    ?assertEqual({error, [not_map]}, Z([])).

%%%===========================================================================
%%% deeply nested list+map combinations
%%%===========================================================================

deeply_nested_empty_test() ->
    Z = deep_schema(),
    ?assertEqual({ok, []}, Z([])).

deeply_nested_valid_test() ->
    Z = deep_schema(),
    ?assertEqual(
        {ok, [#{a => [#{b => true}]}]},
        Z([#{a => [#{b => true}]}])
    ).

deeply_nested_leaf_error_test() ->
    Z = deep_schema(),
    ?assertEqual(
        {error, [{list, 1, [{map, a, [{list, 1, [{map, b, [not_boolean]}]}]}]}]},
        Z([#{a => [#{b => 1}]}])
    ).

deeply_nested_multi_position_errors_test() ->
    Z = deep_schema(),
    ?assertEqual(
        {error, [
            {list, 1, [not_map]},
            {list, 2, [not_map]},
            {list, 3, [{map, a, [{list, 1, [{map, b, missing_key}]}]}]},
            {list, 4, [{map, a, missing_key}]},
            {list, 5, [{map, a, missing_key}]}
        ]},
        Z([
            true,
            [{foo, bar}],
            #{a => [#{a => true}]},
            #{b => [#{x => false}]},
            #{b => #{b => false}}
        ])
    ).

%%%===========================================================================
%%% Helpers
%%%===========================================================================

deep_schema() ->
    zz:list(zz:map(#{a => zz:list(zz:map(#{b => zz:boolean()}))})).
