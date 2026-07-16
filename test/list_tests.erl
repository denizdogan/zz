-module(list_tests).

-include("test.hrl").

%%%===========================================================================
%%% list/0 — any list, contents not validated
%%%===========================================================================

empty_list_test() ->
    ?Z_OK(zz:list(), []).

mixed_list_test() ->
    ?Z_OK(zz:list(), [<<"foo">>, bar, 3]).

improper_list_passthrough_rejected_test() ->
    ?assertEqual({error, [not_list]}, zz:parse(zz:list(), [1 | tail])).

non_list_input_test() ->
    ?assertEqual({error, [not_list]}, zz:parse(zz:list(zz:integer()), <<"foo">>)).

%%%===========================================================================
%%% list/1 — homogeneous list with element parser
%%%===========================================================================

empty_homogeneous_list_test() ->
    ?Z_OK(zz:list(zz:integer()), []).

singleton_homogeneous_list_test() ->
    ?Z_OK(zz:list(zz:integer()), [1]).

multi_homogeneous_list_test() ->
    ?Z_OK(zz:list(zz:integer()), [1, 2, 3]).

improper_homogeneous_list_rejected_test() ->
    ?assertEqual({error, [not_list]}, zz:parse(zz:list(zz:integer()), [1 | tail])).

homogeneous_element_errors_test() ->
    ?assertEqual(
        {error, [
            {list, 2, [not_integer]},
            {list, 5, [not_integer]}
        ]},
        zz:parse(zz:list(zz:integer()), [1, <<"2">>, 3, 4, <<"5">>])
    ).

%%%===========================================================================
%%% list/2 — homogeneous with min/max length options
%%%===========================================================================

max_satisfied_test() ->
    Z = zz:list(zz:integer(), #{max => 2}),
    ?assertEqual({ok, []}, zz:parse(Z, [])),
    ?assertEqual({ok, [1]}, zz:parse(Z, [1])),
    ?assertEqual({ok, [1, 2]}, zz:parse(Z, [1, 2])).

max_violated_test() ->
    Z = zz:list(zz:integer(), #{max => 2}),
    ?assertEqual({error, [list_too_long]}, zz:parse(Z, [1, 2, 3])).

min_satisfied_test() ->
    Z = zz:list(zz:integer(), #{min => 2}),
    ?assertEqual({ok, [1, 2]}, zz:parse(Z, [1, 2])),
    ?assertEqual({ok, [1, 2, 3]}, zz:parse(Z, [1, 2, 3])).

min_violated_test() ->
    Z = zz:list(zz:integer(), #{min => 2}),
    ?assertEqual({error, [list_too_short]}, zz:parse(Z, [])),
    ?assertEqual({error, [list_too_short]}, zz:parse(Z, [1])).

min_max_combined_test() ->
    Z = zz:list(zz:integer(), #{min => 1, max => 3}),
    ?assertEqual({error, [list_too_short]}, zz:parse(Z, [])),
    ?assertEqual({ok, [1]}, zz:parse(Z, [1])),
    ?assertEqual({ok, [1, 2, 3]}, zz:parse(Z, [1, 2, 3])),
    ?assertEqual({error, [list_too_long]}, zz:parse(Z, [1, 2, 3, 4])).

max_with_invalid_elements_test() ->
    Z = zz:list(zz:integer(), #{max => 5}),
    ?assertEqual(
        {error, [{list, 2, [not_integer]}]},
        zz:parse(Z, [1, foo, 3])
    ).

improper_list_with_options_rejected_test() ->
    Z = zz:list(zz:integer(), #{min => 1, max => 3}),
    ?assertEqual({error, [not_list]}, zz:parse(Z, [1 | tail])),
    ?assertEqual({error, [not_list]}, zz:parse(Z, [1, 2, 3, 4 | tail])).
