-module(union_tests).

-include("test.hrl").

single_branch_match_test() ->
    ?Z_OK(z:union([z:integer()]), 1).

multi_branch_first_match_test() ->
    ?Z_OK(z:union([z:integer(), z:binary()]), 1).

multi_branch_later_match_test() ->
    ?Z_OK(z:union([z:integer(), z:binary()]), <<"a">>).

multi_branch_match_in_either_order_test() ->
    ?Z_OK(z:union([z:binary(), z:integer()]), <<"a">>),
    ?Z_OK(z:union([z:binary(), z:integer()]), 1).

single_branch_no_match_test() ->
    %% No match returns one no_match wrapper containing each branch's
    %% own errors, in input order.
    ?assertEqual(
        {error, [{no_match, [[not_integer]]}]},
        z:parse(z:union([z:integer()]), <<"foo">>)
    ).

multi_branch_no_match_test() ->
    ?assertEqual(
        {error, [{no_match, [[not_integer], [not_list], [not_tuple]]}]},
        z:parse(z:union([z:integer(), z:list(), z:tuple()]), #{foo => bar})
    ).

empty_union_test() ->
    Z = z:union([]),
    ?assertEqual({error, [{no_match, []}]}, z:parse(Z, 1)),
    ?assertEqual({error, [{no_match, []}]}, z:parse(Z, foo)),
    ?assertEqual({error, [{no_match, []}]}, z:parse(Z, [])).
