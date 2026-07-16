-module(format_issues_tests).

-include("test.hrl").

empty_test() ->
    ?assertEqual(<<>>, zz:format_issues([])).

single_atom_path_test() ->
    Issues = [#{path => [name], code => not_binary}],
    ?assertEqual(<<"name: not_binary\n">>, zz:format_issues(Issues)).

empty_path_test() ->
    Issues = [#{path => [], code => not_integer}],
    ?assertEqual(<<"(root): not_integer\n">>, zz:format_issues(Issues)).

deep_path_test() ->
    Issues = [#{path => [users, 2, age], code => integer_too_small}],
    ?assertEqual(
        <<"users.2.age: integer_too_small\n">>,
        zz:format_issues(Issues)
    ).

multiple_test() ->
    Issues = [
        #{path => [name], code => not_binary},
        #{path => [age], code => integer_too_small}
    ],
    ?assertEqual(
        <<"name: not_binary\nage: integer_too_small\n">>,
        zz:format_issues(Issues)
    ).

binary_path_segment_test() ->
    Issues = [#{path => [<<"key">>], code => not_integer}],
    ?assertEqual(<<"key: not_integer\n">>, zz:format_issues(Issues)).

with_extras_test() ->
    Issues = [#{path => [], code => unknown_keys, keys => [foo, bar]}],
    Result = zz:format_issues(Issues),
    %% Format includes the extras map after the code.
    ?assertEqual(
        <<"(root): unknown_keys #{keys => [foo,bar]}\n">>,
        Result
    ).

unusual_path_segment_test() ->
    %% Path segments are arbitrary terms (map keys can be anything).
    %% Tuple/float/list segments fall through to the io_lib:format clause.
    Issues = [#{path => [{a, b}], code => not_integer}],
    ?assertEqual(<<"{a,b}: not_integer\n">>, zz:format_issues(Issues)).

end_to_end_via_issues_test() ->
    Z = zz:map(#{
        name => zz:binary(),
        age => zz:integer(#{min => 0})
    }),
    {error, Errs} = zz:parse(Z, #{name => 1, age => -1}),
    Output = zz:format_issues(zz:issues(Errs)),
    %% Normalize map-defined issue order while retaining exact lines and cardinality.
    Lines = binary:split(Output, <<"\n">>, [global, trim_all]),
    ?assertEqual(
        [<<"age: integer_too_small">>, <<"name: not_binary">>],
        lists:sort(Lines)
    ).
