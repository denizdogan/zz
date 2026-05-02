-module(literal_tests).

-include("test.hrl").

literal_valid_test() ->
    ?Z_OK(z:literal(1), 1),
    ?Z_OK(z:literal([]), []),
    ?Z_OK(z:literal([1, 2, <<"three">>]), [1, 2, <<"three">>]),
    ?Z_OK(z:literal($a), 97),
    ok.

literal_invalid_test() ->
    ?assertEqual({error, [not_literal]}, z:parse(z:literal(1), 2)),
    ?assertEqual({error, [not_literal]}, z:parse(z:literal(foo), bar)),
    ?assertEqual({error, [not_literal]}, z:parse(z:literal([]), [1])),
    ?assertEqual({error, [not_literal]}, z:parse(z:literal(<<"x">>), <<"y">>)),
    %% =:= is strict — int vs float of same value mismatch
    ?assertEqual({error, [not_literal]}, z:parse(z:literal(1), 1.0)),
    ok.

literal_undefined_test() ->
    ?Z_OK(z:literal(undefined), undefined),
    ?assertEqual({error, [not_literal]}, z:parse(z:literal(undefined), null)),
    ?assertEqual({error, [not_literal]}, z:parse(z:literal(undefined), <<"undefined">>)),
    ok.
