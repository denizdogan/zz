-module(boolean_tests).

-include("test.hrl").

boolean_valid_test() ->
    ?Z_OK(zz:boolean(), true),
    ?Z_OK(zz:boolean(), false),
    ok.

boolean_invalid_test() ->
    Z = zz:boolean(),
    ?assertEqual({error, [not_boolean]}, zz:parse(Z, <<"false">>)),
    ?assertEqual({error, [not_boolean]}, zz:parse(Z, 0)),
    ?assertEqual({error, [not_boolean]}, zz:parse(Z, 1)),
    ?assertEqual({error, [not_boolean]}, zz:parse(Z, truthy)),
    ?assertEqual({error, [not_boolean]}, zz:parse(Z, [])),
    ok.
