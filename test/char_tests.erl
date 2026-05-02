-module(char_tests).

-include("test.hrl").

zero_codepoint_test() ->
    ?Z_OK(zz:char(), 0).

ascii_test() ->
    ?Z_OK(zz:char(), $a).

high_codepoint_test() ->
    ?Z_OK(zz:char(), 16#10FFFF).

negative_integer_test() ->
    ?assertEqual({error, [not_char]}, zz:parse(zz:char(), -1)).

above_max_test() ->
    ?assertEqual({error, [not_char]}, zz:parse(zz:char(), 16#110000)).

float_test() ->
    ?assertEqual({error, [not_char]}, zz:parse(zz:char(), 3.14)).

binary_test() ->
    ?assertEqual({error, [not_char]}, zz:parse(zz:char(), <<"a">>)).

atom_test() ->
    ?assertEqual({error, [not_char]}, zz:parse(zz:char(), foo)).
