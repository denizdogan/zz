-module(reference_tests).

-include("test.hrl").

make_ref_test() ->
    ?Z_OK(zz:reference(), make_ref()).

distinct_refs_test() ->
    ?Z_OK(zz:reference(), make_ref()),
    ?Z_OK(zz:reference(), make_ref()).

atom_test() ->
    ?assertEqual({error, [not_reference]}, zz:parse(zz:reference(), foo)).

integer_test() ->
    ?assertEqual({error, [not_reference]}, zz:parse(zz:reference(), 1)).

pid_test() ->
    ?assertEqual({error, [not_reference]}, zz:parse(zz:reference(), self())).

binary_test() ->
    ?assertEqual({error, [not_reference]}, zz:parse(zz:reference(), <<"x">>)).
