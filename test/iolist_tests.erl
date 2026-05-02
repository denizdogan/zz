-module(iolist_tests).

-eqwalizer(ignore).

-include("test.hrl").

empty_list_test() ->
    ?Z_OK(zz:iolist(), []).

bytes_list_test() ->
    ?Z_OK(zz:iolist(), [104, 105]).

mixed_iolist_test() ->
    ?Z_OK(zz:iolist(), [<<"foo">>, $-, [<<"bar">>, $-, [98, 97, 122]]]).

improper_list_with_binary_tail_test() ->
    ?Z_OK(zz:iolist(), [104, 105 | <<"!">>]).

binary_input_rejected_test() ->
    ?assertEqual({error, [not_iolist]}, zz:parse(zz:iolist(), <<"hello">>)).

atom_test() ->
    ?assertEqual({error, [not_iolist]}, zz:parse(zz:iolist(), foo)).

integer_test() ->
    ?assertEqual({error, [not_iolist]}, zz:parse(zz:iolist(), 1)).

negative_byte_test() ->
    ?assertEqual({error, [not_iolist]}, zz:parse(zz:iolist(), [-1])).

byte_too_large_test() ->
    ?assertEqual({error, [not_iolist]}, zz:parse(zz:iolist(), [256])).

list_with_atom_test() ->
    ?assertEqual({error, [not_iolist]}, zz:parse(zz:iolist(), [foo])).
