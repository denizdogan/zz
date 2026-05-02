-module(pid_tests).

-include("test.hrl").

self_pid_test() ->
    ?Z_OK(zz:pid(), self()).

spawned_pid_test() ->
    P = spawn(fun() -> ok end),
    ?Z_OK(zz:pid(), P).

atom_test() ->
    ?assertEqual({error, [not_pid]}, zz:parse(zz:pid(), foo)).

integer_test() ->
    ?assertEqual({error, [not_pid]}, zz:parse(zz:pid(), 1)).

binary_test() ->
    ?assertEqual({error, [not_pid]}, zz:parse(zz:pid(), <<"x">>)).

reference_test() ->
    ?assertEqual({error, [not_pid]}, zz:parse(zz:pid(), make_ref())).
