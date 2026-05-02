-module(nullable_tests).

-include("test.hrl").

undefined_test() ->
    Z = zz:nullable(zz:integer()),
    ?assertEqual({ok, undefined}, zz:parse(Z, undefined)).

inner_match_test() ->
    Z = zz:nullable(zz:integer()),
    ?assertEqual({ok, 42}, zz:parse(Z, 42)).

inner_mismatch_test() ->
    Z = zz:nullable(zz:integer()),
    {error, [{no_match, Branches}]} = zz:parse(Z, foo),
    ?assertEqual([[not_literal], [not_integer]], Branches).

nullable_binary_test() ->
    Z = zz:nullable(zz:binary()),
    ?assertEqual({ok, undefined}, zz:parse(Z, undefined)),
    ?assertEqual({ok, <<"x">>}, zz:parse(Z, <<"x">>)).

nested_in_map_test() ->
    Z = zz:map(#{
        nickname => zz:nullable(zz:binary())
    }),
    ?assertEqual(
        {ok, #{nickname => undefined}},
        zz:parse(Z, #{nickname => undefined})
    ),
    ?assertEqual(
        {ok, #{nickname => <<"alice">>}},
        zz:parse(Z, #{nickname => <<"alice">>})
    ).
