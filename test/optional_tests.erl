-module(optional_tests).

-include("test.hrl").

optional_shape_test() ->
    Z = zz:atom(),
    {optional, F} = zz:optional(Z),
    ?assert(is_function(F, 1)),
    ?assertEqual(Z, F),
    ok.
