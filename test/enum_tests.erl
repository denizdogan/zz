-module(enum_tests).

-include("test.hrl").

atom_match_test() ->
    Z = zz:enum([red, green, blue]),
    ?Z_OK(Z, red),
    ?Z_OK(Z, green),
    ?Z_OK(Z, blue).

atom_no_match_test() ->
    Z = zz:enum([red, green, blue]),
    ?assertEqual({error, [not_in_enum]}, zz:parse(Z, yellow)).

integer_match_test() ->
    Z = zz:enum([1, 2, 3]),
    ?Z_OK(Z, 1),
    ?Z_OK(Z, 2),
    ?Z_OK(Z, 3).

binary_match_test() ->
    Z = zz:enum([<<"yes">>, <<"no">>]),
    ?Z_OK(Z, <<"yes">>).

empty_enum_test() ->
    Z = zz:enum([]),
    ?assertEqual({error, [not_in_enum]}, zz:parse(Z, anything)).

mixed_types_test() ->
    Z = zz:enum([1, foo, <<"bar">>]),
    ?Z_OK(Z, 1),
    ?Z_OK(Z, foo),
    ?Z_OK(Z, <<"bar">>),
    ?assertEqual({error, [not_in_enum]}, zz:parse(Z, 2)).

strict_equality_test() ->
    %% =:= semantics: integer 1 != float 1.0
    Z = zz:enum([1, 2, 3]),
    ?assertEqual({error, [not_in_enum]}, zz:parse(Z, 1.0)).

nested_in_map_test() ->
    Z = zz:map(#{
        color => zz:enum([red, green, blue])
    }),
    ?assertEqual({ok, #{color => red}}, zz:parse(Z, #{color => red})),
    ?assertEqual(
        {error, [{map_value, color, [not_in_enum]}]},
        zz:parse(Z, #{color => purple})
    ).
