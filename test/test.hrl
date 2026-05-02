-include_lib("eunit/include/eunit.hrl").

-define(Z_OK(Z, Input),
    (fun() ->
        __Input = (Input),
        ?assertEqual({ok, __Input}, zz:parse(Z, __Input))
    end)()
).
