-module(zz_bench).

-eqwalizer(ignore).

-export([run/0, run/1, run/2]).

-define(DEFAULT_N, 1000000).
-define(DEFAULT_SAMPLES, 5).

run() ->
    run(?DEFAULT_N, ?DEFAULT_SAMPLES).

run(N) ->
    run(N, ?DEFAULT_SAMPLES).

run(N, Samples) ->
    process_flag(priority, high),
    print_env(N, Samples),
    [bench(Name, Z, Input, N, Samples) || {Name, Z, Input} <- cases()],
    ok.

print_env(N, Samples) ->
    io:format("~n", []),
    io:format("erlang:        ~ts~n", [erlang:system_info(otp_release)]),
    io:format("system:        ~ts/~p~n", [
        erlang:system_info(system_architecture), erlang:system_info(schedulers)
    ]),
    io:format("samples/case:  ~p~n", [Samples]),
    io:format("iters/sample:  ~p~n", [N]),
    io:format("~n", []),
    io:format("~-50ts ~10ts ~10ts ~10ts ~10ts~n", [
        <<"benchmark">>, <<"min us/op">>, <<"med us/op">>, <<"max us/op">>, <<"spread">>
    ]),
    io:format("~s~n", [lists:duplicate(94, $-)]).

cases() ->
    BigList = lists:seq(1, 100),
    BigMap = maps:from_list([{I, I} || I <- lists:seq(1, 50)]),
    SchemaSmall = #{a => zz:integer(), b => zz:integer(), c => zz:integer()},
    SchemaLarge = maps:from_list([
        {list_to_atom("k" ++ integer_to_list(I)), zz:integer()}
     || I <- lists:seq(1, 20)
    ]),
    InputLarge = maps:from_list([
        {list_to_atom("k" ++ integer_to_list(I)), I}
     || I <- lists:seq(1, 20)
    ]),
    [
        {<<"atom/0 ok">>, zz:atom(), foo},
        {<<"binary/0 ok">>, zz:binary(), <<"hello">>},
        {<<"binary/1 min/max ok">>, zz:binary(#{min => 1, max => 100}), <<"hello">>},
        {<<"integer/0 ok">>, zz:integer(), 42},
        {<<"integer/1 min/max ok">>, zz:integer(#{min => 0, max => 1000}), 42},
        {<<"float/0 ok">>, zz:float(), 3.14},
        {<<"list/1 100 ints">>, zz:list(zz:integer()), BigList},
        {<<"list/2 100 ints with min/max">>, zz:list(zz:integer(), #{min => 1, max => 1000}),
            BigList},
        {<<"tuple/1 3 elements">>, zz:tuple({zz:integer(), zz:binary(), zz:atom()}),
            {1, <<"x">>, foo}},
        {<<"map/0 (10-key passthrough)">>, zz:map(),
            maps:from_list([{I, I} || I <- lists:seq(1, 10)])},
        {<<"map/1 small schema (3 keys)">>, zz:map(SchemaSmall), #{a => 1, b => 2, c => 3}},
        {<<"map/1 large schema (20 keys)">>, zz:map(SchemaLarge), InputLarge},
        {<<"map/2 strict, 3 keys">>, zz:map(SchemaSmall, #{unknown_keys => strict}), #{
            a => 1, b => 2, c => 3
        }},
        {<<"map/2 passthrough, 3+10 keys">>, zz:map(SchemaSmall, #{unknown_keys => passthrough}),
            maps:merge(#{a => 1, b => 2, c => 3}, BigMap)},
        {<<"map_of/2 50 entries">>, zz:map_of(zz:integer(), zz:integer()), BigMap},
        {<<"enum/1 5 values, hit last">>, zz:enum([a, b, c, d, e]), e},
        {<<"union/1 5 branches, hit last">>,
            zz:union([zz:integer(), zz:float(), zz:atom(), zz:binary(), zz:boolean()]), true},
        {<<"literal/1 ok">>, zz:literal(<<"x">>), <<"x">>}
    ].

bench(Name, Z, Input, N, Samples) ->
    %% Multi-iteration warm-up: trigger JIT inlining for the closure.
    warmup(Z, Input, 100000),
    Times = [run_sample(Z, Input, N) || _ <- lists:seq(1, Samples)],
    Sorted = lists:sort(Times),
    Min = hd(Sorted) / N,
    Max = lists:last(Sorted) / N,
    Median = lists:nth((Samples div 2) + 1, Sorted) / N,
    Spread =
        case Median of
            +0.0 -> 0.0;
            _ -> (Max - Min) / Median * 100
        end,
    io:format("~-50ts ~10.3f ~10.3f ~10.3f ~9.1f%~n", [Name, Min, Median, Max, Spread]).

warmup(_Z, _Input, 0) ->
    ok;
warmup(Z, Input, K) ->
    _ = Z(Input),
    warmup(Z, Input, K - 1).

run_sample(Z, Input, N) ->
    erlang:garbage_collect(),
    {Time, _} = timer:tc(fun() -> loop(Z, Input, N) end),
    Time.

loop(_, _, 0) ->
    ok;
loop(Z, Input, N) ->
    _ = Z(Input),
    loop(Z, Input, N - 1).
