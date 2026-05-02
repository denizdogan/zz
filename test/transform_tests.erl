-module(transform_tests).

-include("test.hrl").

identity_test() ->
    Z = zz:transform(zz:integer(), fun(X) -> X end),
    ?assertEqual({ok, 1}, zz:parse(Z, 1)).

binary_to_atom_test() ->
    Z = zz:transform(zz:binary(), fun binary_to_atom/1),
    ?assertEqual({ok, hello}, zz:parse(Z, <<"hello">>)).

double_test() ->
    Z = zz:transform(zz:integer(), fun(X) -> X * 2 end),
    ?assertEqual({ok, 6}, zz:parse(Z, 3)).

error_passes_through_test() ->
    Z = zz:transform(zz:integer(), fun(X) -> X + 1 end),
    ?assertEqual({error, [not_integer]}, zz:parse(Z, foo)).

chained_transforms_test() ->
    Z1 = zz:transform(zz:integer(), fun(X) -> X * 2 end),
    Z2 = zz:transform(Z1, fun(X) -> X + 1 end),
    ?assertEqual({ok, 7}, zz:parse(Z2, 3)).

inside_list_test() ->
    Z = zz:list(zz:transform(zz:integer(), fun(X) -> X * 10 end)),
    ?assertEqual({ok, [10, 20, 30]}, zz:parse(Z, [1, 2, 3])).

inside_map_test() ->
    Z = zz:map(#{
        n => zz:transform(zz:integer(), fun(X) -> X + 1 end)
    }),
    ?assertEqual({ok, #{n => 5}}, zz:parse(Z, #{n => 4})).

list_with_inner_error_test() ->
    Z = zz:list(zz:transform(zz:integer(), fun(X) -> X * 2 end)),
    ?assertEqual(
        {error, [{list, 2, [not_integer]}]},
        zz:parse(Z, [1, foo, 3])
    ).
