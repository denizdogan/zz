-module(union_tests).

-include("test.hrl").

single_branch_match_test() ->
    ?Z_OK(zz:union([zz:integer()]), 1).

left_bias_when_multiple_branches_succeed_test() ->
    First = fun(_Input) -> {ok, first} end,
    Second = fun(_Input) -> {ok, second} end,
    ?assertEqual({ok, first}, zz:parse(zz:union([First, Second]), input)).

transformed_later_branch_success_test() ->
    First = fun(_Input) -> {error, [first_failed]} end,
    Second = fun(Input) -> {ok, {second, Input}} end,
    ?assertEqual(
        {ok, {second, input}},
        zz:parse(zz:union([First, Second]), input)
    ).

multi_branch_match_in_either_order_test() ->
    ?Z_OK(zz:union([zz:binary(), zz:integer()]), <<"a">>),
    ?Z_OK(zz:union([zz:binary(), zz:integer()]), 1).

single_branch_no_match_test() ->
    %% No match returns one no_match wrapper containing each branch's
    %% own errors, in input order.
    ?assertEqual(
        {error, [{no_match, [[not_integer]]}]},
        zz:parse(zz:union([zz:integer()]), <<"foo">>)
    ).

multi_branch_no_match_test() ->
    ?assertEqual(
        {error, [{no_match, [[not_integer], [not_list], [not_tuple]]}]},
        zz:parse(zz:union([zz:integer(), zz:list(), zz:tuple()]), #{foo => bar})
    ).

empty_union_test() ->
    Z = zz:union([]),
    ?assertEqual({error, [{no_match, []}]}, zz:parse(Z, 1)),
    ?assertEqual({error, [{no_match, []}]}, zz:parse(Z, foo)),
    ?assertEqual({error, [{no_match, []}]}, zz:parse(Z, [])).
