-module(atom_tests).

-include("test.hrl").

atom_valid_test() ->
    ?Z_OK(zz:atom(), foo),
    ?Z_OK(zz:atom(), '$a'),
    ?Z_OK(zz:atom(), 'wow so cool'),
    ok.

atom_invalid_test() ->
    Z = zz:atom(),
    ?assertEqual({error, [not_atom]}, zz:parse(Z, 55)),
    ?assertEqual({error, [not_atom]}, zz:parse(Z, 1.5)),
    ?assertEqual({error, [not_atom]}, zz:parse(Z, <<"foo">>)),
    ?assertEqual({error, [not_atom]}, zz:parse(Z, [foo])),
    ?assertEqual({error, [not_atom]}, zz:parse(Z, {foo})),
    ?assertEqual({error, [not_atom]}, zz:parse(Z, #{foo => bar})),
    ok.
