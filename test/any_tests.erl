-module(any_tests).

-include("test.hrl").

atom_test() ->
    ?Z_OK(zz:any(), foo).

integer_test() ->
    ?Z_OK(zz:any(), 42).

binary_test() ->
    ?Z_OK(zz:any(), <<"hello">>).

list_test() ->
    ?Z_OK(zz:any(), [1, 2, 3]).

map_test() ->
    ?Z_OK(zz:any(), #{a => 1}).

tuple_test() ->
    ?Z_OK(zz:any(), {a, b, c}).
