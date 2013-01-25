:- begin_tests(yamltiny).
:- use_module(yamltiny).

test(lex_single_line):-
    yamltiny_lex("a", [
        line(0, "a", 1)
    ]).
    
test(lex_single_line_extra_spaces):-
    yamltiny_lex("a  ", [
        line(0, "a", 1)
    ]).
    
test(lex_multiple_lines):-
    yamltiny_lex("a\nb\nc", [
        line(0, "a", 1),
        line(0, "b", 2),
        line(0, "c", 3)
    ]).

test(lex_multiple_lines_indent):-
    yamltiny_lex("a\n  b\nc", [
        line(0, "a", 1),
        line(2, "b", 2),
        line(0, "c", 3)
    ]).
    
test(lex_multiple_lines_extra_lns):-
    yamltiny_lex("a\nb\n\nc", [
        line(0, "a", 1),
        line(0, "b", 2),
        line(0, "c", 4)
    ]).
    
test(lex_multiple_lines_comment):-
    yamltiny_lex("a\n#b\nc", [
        line(0, "a", 1),
        line(0, "c", 3)
    ]).

test(singleton_hash):-
    yamltiny_parse_document([
        line(0, "a: hello", 1)
    ], hash([
        a-hello
    ])).
    
test(singleton_array):-
    yamltiny_parse_document([
        line(0, "- hello", 1)
    ], array([
        hello
    ])).
    
test(singleton_array_hash):-
    yamltiny_parse_document([
        line(0, "- a: hello", 1)
    ], array([
        hash([ a-hello ])
    ])).
    
test(simple_hash):-
    yamltiny_parse_document([
        line(0, "a: hello", 1),
        line(0, "b: world", 2),
        line(0, "c: people", 3)
    ], hash([
        a-hello,
        b-world,
        c-people
    ])).
    
test(simple_array):-
    yamltiny_parse_document([
        line(0, "- hello", 1),
        line(0, "- world", 2),
        line(0, "- people", 3)
    ], array([
        hello,
        world,
        people
    ])).
    
test(simple_array_hash):-
    yamltiny_parse_document([
        line(0, "- a: hello", 1),
        line(0, "- b: world", 2),
        line(0, "- c: people", 3)
    ], array([
        hash([ a-hello ]),
        hash([ b-world ]),
        hash([ c-people ])
    ])).
    
test(array_of_hashes):-
    yamltiny_parse_document([
        line(0, "- a1: hello1", 1),
        line(2, "a2: hello2", 2),
        line(0, "- b1: world1", 3),
        line(2, "b2: world2", 4),
        line(0, "- c1: people1", 5),
        line(2, "c2: people2", 6)
    ], array([
        hash([ a1-hello1, a2-hello2 ]),
        hash([ b1-world1, b2-world2 ]),
        hash([ c1-people1, c2-people2])
    ])).
    
test(array_in_hash_value):-
    yamltiny_parse_document([
        line(0, "a:", 1),
        line(0, "- b", 2),
        line(0, "- c", 3),
        line(0, "d: e", 4)
    ], hash([
        a-array([ b, c ]),
        d-e
    ])).
    
test(array_deep_nest):-
    yamltiny_parse_document([
        line(0, "a:", 1),
        line(2, "- b:", 2),
        line(4, "- c:", 3),
        line(6, "- e", 4)
    ], hash([
        a-array([ hash([ b-array([ hash([ c-array([e]) ]) ]) ]) ])
    ])).

:- end_tests(yamltiny).
