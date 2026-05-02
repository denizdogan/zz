-module(union_tests).

-include("test.hrl").

single_branch_match_test() ->
    ?Z_OK(zz:union([zz:integer()]), 1).

multi_branch_first_match_test() ->
    ?Z_OK(zz:union([zz:integer(), zz:binary()]), 1).

multi_branch_later_match_test() ->
    ?Z_OK(zz:union([zz:integer(), zz:binary()]), <<"a">>).

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
