-module(optional_tests).

-include("test.hrl").

optional_shape_test() ->
    Z = z:atom(),
    {optional, F} = z:optional(Z),
    ?assert(is_function(F, 1)),
    ?assertEqual(Z, F),
    ok.
