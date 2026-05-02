-module(list_tests).

-include("test.hrl").

%%%===========================================================================
%%% list/0 — any list, contents not validated
%%%===========================================================================

empty_list_test() ->
    ?Z_OK(z:list(), []).

mixed_list_test() ->
    ?Z_OK(z:list(), [<<"foo">>, bar, 3]).

non_list_input_test() ->
    ?assertEqual({error, [not_list]}, z:parse(z:list(z:integer()), <<"foo">>)).

%%%===========================================================================
%%% list/1 — homogeneous list with element parser
%%%===========================================================================

empty_homogeneous_list_test() ->
    ?Z_OK(z:list(z:integer()), []).

singleton_homogeneous_list_test() ->
    ?Z_OK(z:list(z:integer()), [1]).

multi_homogeneous_list_test() ->
    ?Z_OK(z:list(z:integer()), [1, 2, 3]).

homogeneous_element_errors_test() ->
    ?assertEqual(
        {error, [
            {list, 2, [not_integer]},
            {list, 5, [not_integer]}
        ]},
        z:parse(z:list(z:integer()), [1, <<"2">>, 3, 4, <<"5">>])
    ).

%%%===========================================================================
%%% list/1 — fixed-length, per-position parsers
%%%===========================================================================

fixed_length_non_list_input_test() ->
    ?assertEqual({error, [not_list]}, z:parse(z:list([]), {})).

fixed_length_empty_match_test() ->
    ?assertEqual({ok, []}, z:parse(z:list([]), [])).

fixed_length_too_short_test() ->
    ?assertEqual(
        {error, [length_mismatch]},
        z:parse(z:list([z:integer()]), [])
    ).

fixed_length_match_test() ->
    ?assertEqual(
        {ok, [3, <<"foo">>]},
        z:parse(z:list([z:integer(), z:binary()]), [3, <<"foo">>])
    ).

fixed_length_position_errors_test() ->
    ?assertEqual(
        {error, [
            {list, 1, [not_integer]},
            {list, 2, [not_binary]}
        ]},
        z:parse(z:list([z:integer(), z:binary()]), [<<"three">>, foo])
    ).

%%%===========================================================================
%%% list/2 — homogeneous with min/max length options
%%%===========================================================================

max_satisfied_test() ->
    Z = z:list(z:integer(), #{max => 2}),
    ?assertEqual({ok, []}, z:parse(Z, [])),
    ?assertEqual({ok, [1]}, z:parse(Z, [1])),
    ?assertEqual({ok, [1, 2]}, z:parse(Z, [1, 2])).

max_violated_test() ->
    Z = z:list(z:integer(), #{max => 2}),
    ?assertEqual({error, [list_too_long]}, z:parse(Z, [1, 2, 3])).

min_satisfied_test() ->
    Z = z:list(z:integer(), #{min => 2}),
    ?assertEqual({ok, [1, 2]}, z:parse(Z, [1, 2])),
    ?assertEqual({ok, [1, 2, 3]}, z:parse(Z, [1, 2, 3])).

min_violated_test() ->
    Z = z:list(z:integer(), #{min => 2}),
    ?assertEqual({error, [list_too_short]}, z:parse(Z, [])),
    ?assertEqual({error, [list_too_short]}, z:parse(Z, [1])).

min_max_combined_test() ->
    Z = z:list(z:integer(), #{min => 1, max => 3}),
    ?assertEqual({error, [list_too_short]}, z:parse(Z, [])),
    ?assertEqual({ok, [1]}, z:parse(Z, [1])),
    ?assertEqual({ok, [1, 2, 3]}, z:parse(Z, [1, 2, 3])),
    ?assertEqual({error, [list_too_long]}, z:parse(Z, [1, 2, 3, 4])).

max_with_invalid_elements_test() ->
    Z = z:list(z:integer(), #{max => 5}),
    ?assertEqual(
        {error, [{list, 2, [not_integer]}]},
        z:parse(Z, [1, foo, 3])
    ).
