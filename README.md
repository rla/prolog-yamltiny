Prolog-yamltiny
===============

A YAML subset parser for Prolog. The subset of YAML was partially
taken from http://search.cpan.org/~adamk/YAML-Tiny-1.51/lib/YAML/Tiny.pm#YAML_TINY_SPECIFICATION

This implementation, however, supports no directives. Single/double block
literals are not supported. At the moment, writing YAML documents is
not supported. No types are supported, all primitive values are atoms.

Dependencies
------------

The code has been tested on Swi-Prolog. It uses DCG's to implement
the lexer and the parser. For IO it depends on `library(readutil)`,
for various other predicates it depends on `library(apply)`.

Unit tests
----------

Unit tests cover most features. The tests are in the file `src/tests.pl`
and can be ran with the command `make test` or by loading the file
manually into Swi-Prolog and calling `run_tests`.

Example usage
-------------

Predicates:

* `yamltiny_parse(+Codes:list, -Documents:list) is det`.
* `yamltiny_read(+Filename:atom, -Documents:list) is det`.

Complete Prolog program:

    :- use_module(library(yamltiny)).
    
    main:-
        yamltiny_read('file.yml', Documents),
        writeln(Documents).

Input file:

    - a
    - b
    - c

Prolog term (contains one documents):

    [ array([a, b, c]) ]
    
Input file:

    a: hello
    b: world
    
Prolog term:
    
    [ hash(a-hello, b-world) ]

Installation
------------

Assuming you have Swi-Prolog installed, run `make install`. You should
first make sure that unit tests run without errors. 

License
-------

The MIT license. See LICENSE file.