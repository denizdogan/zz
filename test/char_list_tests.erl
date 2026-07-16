-module(char_list_tests).

-eqwalizer({nowarn_function, improper_char_list/0}).

-include("test.hrl").

empty_char_list_test() ->
    ?Z_OK(zz:char_list(), []).

ascii_char_list_test() ->
    ?Z_OK(zz:char_list(), "hello").

unicode_char_list_test() ->
    ?Z_OK(zz:char_list(), [16#1F600, 65, 16#10FFFF]).

non_list_input_test() ->
    ?assertEqual({error, [not_list]}, zz:parse(zz:char_list(), <<"hello">>)).

improper_char_list_rejected_test() ->
    ?assertEqual({error, [not_list]}, zz:parse(zz:char_list(), improper_char_list())).

-spec improper_char_list() -> term().
improper_char_list() ->
    [$a | tail].

bad_element_test() ->
    ?assertEqual(
        {error, [{list, 2, [not_char]}]},
        zz:parse(zz:char_list(), [$a, foo, $b])
    ).

multiple_bad_elements_test() ->
    ?assertEqual(
        {error, [
            {list, 2, [not_char]},
            {list, 4, [not_char]}
        ]},
        zz:parse(zz:char_list(), [$a, -1, $b, 16#FFFFFF])
    ).
