-module(pid_tests).

-include("test.hrl").

self_pid_test() ->
    ?Z_OK(zz:pid(), self()).

dead_pid_test() ->
    {Pid, MonitorRef} = spawn_monitor(fun() -> ok end),
    receive
        {'DOWN', MonitorRef, process, Pid, normal} -> ok
    end,
    ?Z_OK(zz:pid(), Pid).

reference_test() ->
    ?assertEqual({error, [not_pid]}, zz:parse(zz:pid(), make_ref())).
