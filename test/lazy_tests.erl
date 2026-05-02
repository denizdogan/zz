-module(lazy_tests).

-include("test.hrl").

%% Helper: simple binary tree where leaves are 'leaf' and nodes are
%% {node, Left, Right}.
tree() ->
    zz:union([
        zz:literal(leaf),
        zz:tuple({
            zz:literal(node),
            zz:lazy(fun() -> tree() end),
            zz:lazy(fun() -> tree() end)
        })
    ]).

%% Mutual recursion: 'a' wraps 'b' which wraps 'a' or 'a_leaf'.
a() ->
    zz:union([
        zz:literal(a_leaf),
        zz:tuple({zz:literal(a), zz:lazy(fun b/0)})
    ]).

b() ->
    zz:tuple({zz:literal(b), zz:lazy(fun a/0)}).

leaf_test() ->
    ?assertEqual({ok, leaf}, zz:parse(tree(), leaf)).

shallow_node_test() ->
    Input = {node, leaf, leaf},
    ?assertEqual({ok, Input}, zz:parse(tree(), Input)).

deep_node_test() ->
    Input = {node, {node, leaf, leaf}, {node, leaf, {node, leaf, leaf}}},
    ?assertEqual({ok, Input}, zz:parse(tree(), Input)).

bad_leaf_test() ->
    %% 'other' is not 'leaf' (literal mismatch on first branch) and
    %% not a tuple (second branch). Both branches fail.
    ?assertEqual(
        {error, [{no_match, [[not_literal], [not_tuple]]}]},
        zz:parse(tree(), other)
    ).

bad_node_inner_test() ->
    %% 'banana' (the 3rd tuple element) is neither 'leaf' nor a tuple.
    %% The full input fails the leaf branch with not_literal, and the
    %% tuple branch with a nested no_match at position 3.
    ?assertEqual(
        {error, [
            {no_match, [
                [not_literal],
                [{tuple, 3, [{no_match, [[not_literal], [not_tuple]]}]}]
            ]}
        ]},
        zz:parse(tree(), {node, leaf, banana})
    ).

non_recursive_lazy_test() ->
    Z = zz:lazy(fun() -> zz:integer() end),
    ?assertEqual({ok, 1}, zz:parse(Z, 1)),
    ?assertEqual({error, [not_integer]}, zz:parse(Z, foo)).

list_of_trees_test() ->
    Z = zz:list(zz:lazy(fun() -> tree() end)),
    Input = [leaf, {node, leaf, leaf}, leaf],
    ?assertEqual({ok, Input}, zz:parse(Z, Input)).

mutual_recursion_test() ->
    %% {a, {b, a_leaf}}
    ?assertEqual({ok, {a, {b, a_leaf}}}, zz:parse(a(), {a, {b, a_leaf}})),
    %% {a, {b, {a, {b, a_leaf}}}}
    Deep = {a, {b, {a, {b, a_leaf}}}},
    ?assertEqual({ok, Deep}, zz:parse(a(), Deep)),
    %% Plain a_leaf parses as 'a'.
    ?assertEqual({ok, a_leaf}, zz:parse(a(), a_leaf)).

mutual_recursion_bad_test() ->
    %% {a, a_leaf} fails: second element should be a {b, _} tuple.
    ?assertMatch({error, _}, zz:parse(a(), {a, a_leaf})).
