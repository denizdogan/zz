-module(otp29_tests).

-include("test.hrl").

-if(?OTP_RELEASE >= 29).

native_record_identity_test() ->
    Record = native_record(1),
    Equal = native_record(1),
    ?Z_OK(zz:any(), Record),
    ?assertEqual({ok, Equal}, zz:parse(zz:literal(Record), Equal)),
    ?assertEqual({ok, Equal}, zz:parse(zz:enum([other, Record]), Equal)).

native_record_exact_comparisons_test() ->
    Record = native_record(1),
    Literal = zz:literal(Record),
    Enum = zz:enum([Record]),
    OtherRecord = records:create(?MODULE, other_fixture, [{value, 1}], #{is_exported => false}),
    lists:foreach(
        fun(Other) ->
            ?assertEqual({error, [not_literal]}, zz:parse(Literal, Other)),
            ?assertEqual({error, [not_in_enum]}, zz:parse(Enum, Other))
        end,
        [native_record(2), native_record(1.0), OtherRecord, {fixture, 1}, #{value => 1}]
    ).

native_record_rejected_by_collections_test() ->
    Record = native_record(1),
    ?assertNot(is_tuple(Record)),
    ?assertNot(is_map(Record)),
    ?assertEqual({error, [not_tuple]}, zz:parse(zz:tuple(), Record)),
    ?assertEqual({error, [not_tuple]}, zz:parse(zz:tuple({zz:any()}), Record)),
    ?assertEqual({error, [not_map]}, zz:parse(zz:map(), Record)),
    ?assertEqual({error, [not_map]}, zz:parse(zz:map(#{}), Record)),
    ?assertEqual({error, [not_map]}, zz:parse(zz:map_of(zz:any(), zz:any()), Record)).

native_record_nested_schema_test() ->
    Key = native_record(key),
    Value = native_record(value),
    Z = zz:map(#{
        Key => zz:list(zz:tuple({zz:any(), zz:literal(Value)}))
    }),
    Input = #{Key => [{Value, Value}]},
    ?Z_OK(Z, Input).

native_record_map_of_keys_and_values_test() ->
    Key = native_record(key),
    Value = native_record(value),
    Input = #{Key => Value},
    ?Z_OK(zz:map(), Input),
    ?Z_OK(zz:map_of(zz:any(), zz:any()), Input),
    ?Z_OK(zz:map_of(zz:literal(Key), zz:literal(Value)), Input),
    KeyParser = fun(K) -> {ok, native_record(K)} end,
    ValueParser = fun(V) -> {ok, native_record(V)} end,
    ?assertEqual(
        {ok, Input},
        zz:parse(zz:map_of(KeyParser, ValueParser), #{key => value})
    ).

native_record_collision_issue_test() ->
    Key = native_record(same),
    KeyParser = fun(_OriginalKey) -> {ok, native_record(same)} end,
    Z = zz:map_of(KeyParser, zz:any()),
    {error, Errors} = zz:parse(Z, #{first => 1, second => 2}),
    ?assertEqual([{map_key_collision, Key}], Errors),
    ?assertEqual(
        [#{path => [], code => map_key_collision, key => Key}],
        zz:issues(Errors)
    ).

native_record_map_of_errors_test() ->
    Key = native_record(key),
    Value = native_record(value),
    Z = zz:map_of(zz:binary(), zz:integer()),
    {error, Errors} = zz:parse(Z, #{Key => Value}),
    ?assertEqual(
        [{map_key, Key, [not_binary]}, {map_value, Key, [not_integer]}],
        Errors
    ),
    ?assertEqual(
        [
            #{
                path => [],
                code => invalid_key,
                key => Key,
                errors => [#{path => [], code => not_binary}]
            },
            #{path => [Key], code => not_integer}
        ],
        zz:issues(Errors)
    ).

native_record_path_formatting_test() ->
    Key = native_record(key),
    Z = zz:map(#{payload => zz:map(#{Key => zz:integer()})}),
    {error, Errors} = zz:parse(Z, #{payload => #{Key => native_record(value)}}),
    Issues = zz:issues(Errors),
    ?assertEqual([#{path => [payload, Key], code => not_integer}], Issues),
    Expected = iolist_to_binary([
        "payload.", io_lib:format("~tp", [Key]), ": not_integer\n"
    ]),
    ?assertEqual(Expected, zz:format_issues(Issues)).

native_record(Value) ->
    records:create(?MODULE, fixture, [{value, Value}], #{is_exported => false}).

-endif.
