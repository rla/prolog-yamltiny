Prolog-yamltiny
===============

A YAML subset parser for Prolog.

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

Installation
------------

Assuming you have Swi-Prolog installed, run `make install`. You should
first make sure that unit tests run without errors. 

License
-------

The MIT license.