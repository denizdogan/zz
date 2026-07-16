-module(bitstring_tests).

-include("test.hrl").

binary_is_bitstring_test() ->
    ?Z_OK(zz:bitstring(), <<"hello">>).

empty_bitstring_test() ->
    ?Z_OK(zz:bitstring(), <<>>).

partial_bitstring_test() ->
    ?Z_OK(zz:bitstring(), <<1:7>>).

atom_test() ->
    ?assertEqual({error, [not_bitstring]}, zz:parse(zz:bitstring(), foo)).

list_test() ->
    ?assertEqual({error, [not_bitstring]}, zz:parse(zz:bitstring(), [1])).

min_max_equal_test() ->
    Z = zz:bitstring(#{min => 8, max => 8}),
    ?Z_OK(Z, <<255>>),
    ?assertEqual({error, [bitstring_too_short]}, zz:parse(Z, <<1:7>>)),
    ?assertEqual({error, [bitstring_too_long]}, zz:parse(Z, <<1:9>>)).
