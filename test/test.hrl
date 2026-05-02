-include_lib("eunit/include/eunit.hrl").

-define(Z_OK(Z, Input), ?assertEqual({ok, Input}, zz:parse(Z, Input))).
