-module(map_tests).

-include("test.hrl").

empty_map_passthrough_test() ->
    ?Z_OK(z:map(), #{}).

populated_map_passthrough_test() ->
    ?Z_OK(z:map(), #{foo => 1}).

schema_with_integer_test() ->
    ?Z_OK(z:map(#{foo => z:integer()}), #{foo => 1}).

schema_with_literal_test() ->
    ?Z_OK(z:map(#{foo => z:literal(1)}), #{foo => 1}).

list_input_is_not_map_test() ->
    ?assertEqual({error, [not_map]}, z:parse(z:map(), [1, 2, 3])).

tuple_input_is_not_map_test() ->
    ?assertEqual({error, [not_map]}, z:parse(z:map(), {1, 2, 3})).

atom_input_is_not_map_test() ->
    ?assertEqual({error, [not_map]}, z:parse(z:map(), map)).

unknown_keys_default_strips_test() ->
    %% map/1 defaults to strip when no options given
    ?assertEqual({ok, #{}}, z:parse(z:map(#{}), #{foo => 1})).

unknown_keys_strip_test() ->
    Z = z:map(#{}, #{unknown_keys => strip}),
    ?assertEqual({ok, #{}}, z:parse(Z, #{foo => 1})).

unknown_keys_strict_test() ->
    Z = z:map(#{}, #{unknown_keys => strict}),
    {error, [{unknown_keys, Keys}]} = z:parse(Z, #{foo => 1, bar => 2}),
    ?assertEqual([bar, foo], lists:sort(Keys)).

unknown_keys_passthrough_test() ->
    Z = z:map(#{}, #{unknown_keys => passthrough}),
    ?assertEqual({ok, #{foo => 1}}, z:parse(Z, #{foo => 1})).

schema_value_mismatch_test() ->
    ?assertEqual(
        {error, [{map, foo, [not_literal]}]},
        z:parse(z:map(#{foo => z:literal(2)}), #{foo => 1})
    ).

optional_present_and_valid_test() ->
    Z = schema_foo_bar(),
    ?assertEqual({ok, #{foo => 2, bar => bar}}, z:parse(Z, #{foo => 2, bar => bar})).

optional_present_required_invalid_test() ->
    Z = schema_foo_bar(),
    ?assertEqual(
        {error, [{map, foo, [not_literal]}]},
        z:parse(Z, #{foo => 1, bar => bar})
    ).

optional_absent_required_invalid_test() ->
    Z = schema_foo_bar(),
    ?assertEqual(
        {error, [{map, foo, [not_literal]}]},
        z:parse(Z, #{foo => 1})
    ).

optional_present_invalid_test() ->
    Z = schema_foo_bar(),
    ?assertEqual(
        {error, [{map, bar, [not_literal]}]},
        z:parse(Z, #{foo => 2, bar => qux})
    ).

strict_combines_missing_and_unknown_test() ->
    Z = z:map(#{foo => z:integer()}, #{unknown_keys => strict}),
    ?assertEqual(
        {error, [
            {map, foo, missing_key},
            {unknown_keys, [bar]}
        ]},
        z:parse(Z, #{bar => 1})
    ).

%%%===========================================================================
%%% Helpers
%%%===========================================================================

schema_foo_bar() ->
    z:map(#{
        foo => z:literal(2),
        bar => z:optional(z:literal(bar))
    }).
