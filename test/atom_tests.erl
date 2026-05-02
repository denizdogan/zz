-module(atom_tests).

-include("test.hrl").

atom_valid_test() ->
    ?Z_OK(z:atom(), foo),
    ?Z_OK(z:atom(), '$a'),
    ?Z_OK(z:atom(), 'wow so cool'),
    ok.

atom_invalid_test() ->
    Z = z:atom(),
    ?assertEqual({error, [not_atom]}, z:parse(Z, 55)),
    ?assertEqual({error, [not_atom]}, z:parse(Z, 1.5)),
    ?assertEqual({error, [not_atom]}, z:parse(Z, <<"foo">>)),
    ?assertEqual({error, [not_atom]}, z:parse(Z, [foo])),
    ?assertEqual({error, [not_atom]}, z:parse(Z, {foo})),
    ?assertEqual({error, [not_atom]}, z:parse(Z, #{foo => bar})),
    ok.
