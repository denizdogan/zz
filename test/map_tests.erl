-module(map_tests).

-include("test.hrl").

empty_map_passthrough_test() ->
    ?Z_OK(zz:map(), #{}).

populated_map_passthrough_test() ->
    ?Z_OK(zz:map(), #{foo => 1}).

schema_with_integer_test() ->
    ?Z_OK(zz:map(#{foo => zz:integer()}), #{foo => 1}).

schema_with_literal_test() ->
    ?Z_OK(zz:map(#{foo => zz:literal(1)}), #{foo => 1}).

list_input_is_not_map_test() ->
    ?assertEqual({error, [not_map]}, zz:parse(zz:map(), [1, 2, 3])).

tuple_input_is_not_map_test() ->
    ?assertEqual({error, [not_map]}, zz:parse(zz:map(), {1, 2, 3})).

atom_input_is_not_map_test() ->
    ?assertEqual({error, [not_map]}, zz:parse(zz:map(), map)).

unknown_keys_default_strips_test() ->
    %% map/1 defaults to strip when no options given
    ?assertEqual({ok, #{}}, zz:parse(zz:map(#{}), #{foo => 1})).

unknown_keys_strip_test() ->
    Z = zz:map(#{}, #{unknown_keys => strip}),
    ?assertEqual({ok, #{}}, zz:parse(Z, #{foo => 1})).

unknown_keys_strict_test() ->
    Z = zz:map(#{}, #{unknown_keys => strict}),
    {error, [{unknown_keys, Keys}]} = zz:parse(Z, #{foo => 1, bar => 2}),
    ?assertEqual([bar, foo], lists:sort(Keys)).

unknown_keys_passthrough_test() ->
    Z = zz:map(#{}, #{unknown_keys => passthrough}),
    ?assertEqual({ok, #{foo => 1}}, zz:parse(Z, #{foo => 1})).

schema_value_mismatch_test() ->
    ?assertEqual(
        {error, [{map_value, foo, [not_literal]}]},
        zz:parse(zz:map(#{foo => zz:literal(2)}), #{foo => 1})
    ).

optional_present_and_valid_test() ->
    Z = schema_foo_bar(),
    ?assertEqual({ok, #{foo => 2, bar => bar}}, zz:parse(Z, #{foo => 2, bar => bar})).

optional_present_required_invalid_test() ->
    Z = schema_foo_bar(),
    ?assertEqual(
        {error, [{map_value, foo, [not_literal]}]},
        zz:parse(Z, #{foo => 1, bar => bar})
    ).

optional_absent_required_invalid_test() ->
    Z = schema_foo_bar(),
    ?assertEqual(
        {error, [{map_value, foo, [not_literal]}]},
        zz:parse(Z, #{foo => 1})
    ).

optional_present_invalid_test() ->
    Z = schema_foo_bar(),
    ?assertEqual(
        {error, [{map_value, bar, [not_literal]}]},
        zz:parse(Z, #{foo => 2, bar => qux})
    ).

strict_combines_missing_and_unknown_test() ->
    Z = zz:map(#{foo => zz:integer()}, #{unknown_keys => strict}),
    ?assertEqual(
        {error, [
            {map_missing, foo},
            {unknown_keys, [bar]}
        ]},
        zz:parse(Z, #{bar => 1})
    ).

%%%===========================================================================
%%% Helpers
%%%===========================================================================

schema_foo_bar() ->
    zz:map(#{
        foo => zz:literal(2),
        bar => zz:optional(zz:literal(bar))
    }).
