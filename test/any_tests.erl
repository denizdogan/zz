-module(any_tests).

-include("test.hrl").

identity_test() ->
    ?Z_OK(zz:any(), #{key => [foo, {42, <<"value">>}]}).
