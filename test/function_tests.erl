-module(function_tests).

-include("test.hrl").

zero_arg_test() ->
    F = fun() -> ok end,
    ?Z_OK(zz:function(), F).

one_arg_test() ->
    F = fun(X) -> X end,
    ?Z_OK(zz:function(), F).

bif_test() ->
    ?Z_OK(zz:function(), fun erlang:is_atom/1).

atom_test() ->
    ?assertEqual({error, [not_function]}, zz:parse(zz:function(), foo)).

integer_test() ->
    ?assertEqual({error, [not_function]}, zz:parse(zz:function(), 1)).

arity_match_test() ->
    F = fun(X, Y) -> {X, Y} end,
    ?Z_OK(zz:function(2), F).

arity_mismatch_test() ->
    F = fun(X) -> X end,
    ?assertEqual(
        {error, [function_arity_mismatch]},
        zz:parse(zz:function(2), F)
    ).

arity_non_function_test() ->
    ?assertEqual({error, [not_function]}, zz:parse(zz:function(2), foo)).
