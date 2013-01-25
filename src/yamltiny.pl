:- module(yamltiny, [
    yamltiny_parse/2,
    yamltiny_read/2,
    yamltiny_lex/2,
    yamltiny_parse_document/2
]).

:- use_module(library(readutil)).
:- use_module(library(apply)).

%% yamltiny_read(+Spec, -Documents:list) is det.
%
% Reads and parses given YAMLtiny file.

yamltiny_read(File, Documents):-
    read_file_to_codes(File, Codes, []),
    yamltiny_parse(Codes, Documents).

%% yamltiny_parse(+Codes:list, -Documents:list) is det.
%
% Parses the list of codes into a list of YAMLtiny documents. 
    
yamltiny_parse(Codes, Documents):-
    yamltiny_lex(Codes, Lines),
    phrase(documents(DocLines), Lines, []),
    maplist(yamltiny_parse_document, DocLines, Tmp),
    Documents = Tmp.

% Parses tokens into a list of document.
% Documents are separated by markers --- or ...

documents([Document|Documents]) -->
    document(Document),
    { length(Document, Len), Len > 0 }, !,
    documents(Documents).
    
documents([]) --> [].

document([]) -->
    [line(0, "---", _)], !.
    
document([]) -->
    [line(0, "...", _)], !.
    
document([Line|Lines]) -->
    [Line], !, document(Lines).
    
document([]) --> [].

%% yamltiny_parse_document(+Lines:list, -Document) is det.
%
% Parses the list of line tokens into a YAMLtiny document.

yamltiny_parse_document(Lines, Document):-
    phrase(hash_or_array_or_text(0, Tmp), Lines, []),
    Document = Tmp.

% Generic block parser.
% Case for array.

hash_or_array_or_text(Depth, array(Array)) -->
    lookahead(line(Depth, Text, _)),
    { prefix("- ", Text) }, !,
    array(Depth, Array).

% Case for hash 'a: 3'.
    
hash_or_array_or_text(Depth, hash(Hash)) -->
    lookahead(line(Depth, Text, _)),
    { sublistchk(": ", Text) }, !,
    hash(Depth, Hash).

% Case for hash 'a:\n'.
    
hash_or_array_or_text(Depth, hash(Hash)) -->
    lookahead(line(Depth, Text, _)),
    { suffix(":", Text) }, !,
    hash(Depth, Hash).

% Case for text.
    
hash_or_array_or_text(Depth, Text) -->
    text(Depth, Text).  

% Handles array.
% Array entry.

array(Depth, [Entry|Array]) -->
    lookahead(line(Depth, Text, _)),
    { prefix("- ", Text) }, !,
    array_entry(Depth, Entry),
    array(Depth, Array).

% Array end. Next line indented left.
   
array(Depth, []) -->
    lookahead(line(Indent, _, _)),
    { Indent < Depth }, !.
    
% Array end. Part of hash value on the
% same indent level.

array(Depth, []) -->
    lookahead(line(Depth, Text, _)),
    { suffix(":", Text) ; sublistchk(": ", Text) }, !.

% Array end. End of input.
   
array(_, []) -->
    at_end, !.
    
array(_, _) -->
    [ line(_, _, Nr) ],
    { throw(syntax_error(Nr)) }.

% Array entry '- something'. Strips prefix
% '- ' and treats rest as generic value.

array_entry(Depth, Entry) -->
    [ line(Depth, Text, Nr) ],    
    { array_entry_suffix(Text, Suffix) },
    { length(Suffix, LenS) },
    { length(Text, LenT) },
    { Indent is Depth + LenT - LenS },
    pushback(line(Indent, Suffix, Nr)),
    hash_or_array_or_text(Indent, Entry).
    
array_entry_suffix(Text, Suffix):-
    append("-", Tmp, Text),
    trim_left(Tmp, Suffix).

% Handles hash.
% Simple hash entry.

hash(Depth, [Entry|Hash]) -->
    lookahead(line(Depth, Text, _)),
    { \+ prefix("- ", Text) },
    { sublistchk(": ", Text) }, !,
    hash_entry(Depth, Entry),
    hash(Depth, Hash).

% Hash entry 'a:\n'.
    
hash(Depth, [Entry|Hash]) -->
    lookahead(line(Depth, Text, _)),
    { \+ prefix("- ", Text) },
    { suffix(":", Text) }, !,
    hash_entry(Depth, Entry),
    hash(Depth, Hash).

% Hash end. Next line indented left.
   
hash(Depth, []) -->
    lookahead(line(Indent, _, _)),
    { Indent < Depth }, !.

% Hash end. End of input.
   
hash(_, []) -->
    at_end, !.

% Syntax error.
    
hash(Depth, _) -->
    [ line(Indent, _, Nr) ],
    { throw(syntax_error(Nr, Depth, Indent)) }.

% Case for 'a:\n  '.

hash_entry(Depth, Entry) -->
    { Entry = Key-Value },
    [ line(Depth, Text, _) ],
    { suffix(":", Text) },
    lookahead(line(Indent, _, _)),
    { Indent > Depth },
    { append(Codes, ":", Text) },
    { atom_codes(Key, Codes) }, !,
    hash_or_array_or_text(Indent, Value).
    
% Case for 'a:\n- '.

hash_entry(Depth, Entry) -->
    { Entry = Key-Value },
    [ line(Depth, Text, _) ],
    { suffix(":", Text) },
    lookahead(line(Depth, Next, _)),
    { prefix("- ", Next) },
    { append(Codes, ":", Text) },
    { atom_codes(Key, Codes) }, !,
    hash_or_array_or_text(Depth, Value).
    
% Case for simple 'a: 1'.

hash_entry(Depth, Entry) -->
    { Entry = Key-Value },
    [ line(Depth, Text, _) ],
    { sublistchk(": ", Text) }, !,    
    { atom_codes(Atom, Text) },
    { atomic_list_concat([Key, Value], ': ', Atom) }.

% Handles simple text.

text(Depth, Text) -->
    text_collect(Depth, [], List),
    { reverse(List, Reversed) },
    { maplist(atom_codes, Atoms, Reversed) },
    { atomic_list_concat(Atoms, '', Text) }.

% Case for line indented at least Depth
% or deeper.

text_collect(Depth, In, Out) -->
    [ line(Indent, Text, _) ],
    { Indent >= Depth }, !,
    text_collect(Depth, [Text|In], Out).

% Case for line indented left.
    
text_collect(Depth, Texts, Texts) -->
    lookahead(line(Indent, _, _)),
    { Indent < Depth }, !.

% Case for end of input.
    
text_collect(_, Texts, Texts) -->
    at_end.
    
%% yamltiny_lex(+Codes:list, -Tokens:list) is det.
%
% Turns codes into line tokens.
% Tokens will be in form line(Indent, Text, Nr).

yamltiny_lex(Codes, Tokens):-
    phrase(lines(1, Lines), Codes, []),
    maplist(token, Lines, Tmp),
    exclude(empty, Tmp, Tokens).

% Helper to remove empty line tokens.
    
empty(line(_, Text, _)):-
    length(Text, 0).

% Turns line into token.

token(Nr-Line, line(Indent, Trimmed, Nr)):-
    phrase(indent(Indent, Tmp), Line, []),
    without_comment(Tmp, Text),
    trim_right(Text, Trimmed).
    
% Strips comment from line.

without_comment(Text, Without):-
    nth0(Pos, Text, 35),
    prefix(Without, Text),
    length(Without, Pos), !.

without_comment(Text, Text).    

% Extracts indent from line.
    
indent(Indent, Text) -->
    " ", !,
    indent(OldIndent, Text),
    { Indent is OldIndent + 1 }.
    
indent(0, Text) -->
    rest(Text).

% Line is pair Pos-Text.

lines(Nr, [Nr-Line|Lines]) -->
    line(Line),
    { length(Line, Len), Len > 0 }, !,
    lines(Nr, Lines).
    
lines(Nr, Lines) -->
    ln, !, { NewNr is Nr + 1 },
    lines(NewNr, Lines).

lines(_, []) -->
    at_end.

% Parses one line.

line([Code|Line]) -->
    [Code], { \+ code_type(Code, end_of_line) }, !,
    line(Line).

line([]) --> "".

% Detects line end. All three different
% kind of line ends are detected.
    
ln --> "\n\r", !.
ln --> "\n", !.
ln --> "\r".

% For writing YAML.

/*
emit_hash([Entry|Entries]) -->
    emit_hash_entry(Entry),
    emit_hash(Entries).
    
emit_hash([]) --> "".

emit_hash_entry(Key-Value):-
    emit_hash_key(Key),
    emit_hash_value(Value),
    ln.
*/

% Grammar helper to extract the rest of elements
% of the list.

rest(Rest, Rest, []).

% Grammar helper to detect the end of the input.

at_end([], []).

% Grammar helper to insert new token.

pushback(Term, List, [Term|List]).

% Grammar helper to look ahead the next token.
    
lookahead(Term, [Term|Rest], [Term|Rest]).

sublistchk(Part, List):-
    prefix(Part, List), !.
    
sublistchk(Part, [_|List]):-
    sublistchk(Part, List).
    
suffix(Part, List):-
    reverse(Part, PartR),
    reverse(List, ListR),
    prefix(PartR, ListR).

% Trims whitespaces from the beginning of the list of codes.

trim_left([Code|Codes], Result):-
    code_type(Code, space), !,
    trim_left(Codes, Result).
    
trim_left(Codes, Codes).

% Trims whitespace from the end of the list of codes.

trim_right(Codes, Result):-
    reverse(Codes, CodesR),
    trim_left(CodesR, ResultR),
    reverse(ResultR, Result).