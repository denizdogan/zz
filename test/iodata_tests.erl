-module(iodata_tests).

-eqwalizer(ignore).

-include("test.hrl").

binary_test() ->
    ?Z_OK(zz:iodata(), <<"hello">>).

empty_binary_test() ->
    ?Z_OK(zz:iodata(), <<>>).

empty_list_test() ->
    ?Z_OK(zz:iodata(), []).

bytes_list_test() ->
    ?Z_OK(zz:iodata(), [104, 105]).

mixed_iolist_test() ->
    ?Z_OK(zz:iodata(), [<<"foo">>, $-, [<<"bar">>, $-, [98, 97, 122]]]).

improper_iolist_test() ->
    ?Z_OK(zz:iodata(), [$h, $i, <<"!">>]).

improper_list_with_binary_tail_test() ->
    ?Z_OK(zz:iodata(), [104, 105 | <<"!">>]).

atom_test() ->
    ?assertEqual({error, [not_iodata]}, zz:parse(zz:iodata(), foo)).

integer_test() ->
    ?assertEqual({error, [not_iodata]}, zz:parse(zz:iodata(), 1)).

negative_byte_test() ->
    ?assertEqual({error, [not_iodata]}, zz:parse(zz:iodata(), [-1])).

byte_too_large_test() ->
    ?assertEqual({error, [not_iodata]}, zz:parse(zz:iodata(), [256])).

list_with_atom_test() ->
    ?assertEqual({error, [not_iodata]}, zz:parse(zz:iodata(), [foo])).
