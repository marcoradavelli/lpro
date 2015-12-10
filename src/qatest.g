grammar qatest;

options {
  language = Java;
}

@header{
  package it.unibg.qatest;
}

@lexer::header {
  package it.unibg.qatest;
}

@lexer::members {
  
}

QATEST: 'Title: ' STRING (QACONTAINER_OPTIONS)? (QAPART)*;

QACONTAINER_OPTIONS:
  ('[' 'max' maxTries=INT 'tries' ']') & 
  {boolean revealAnswer=false;}
  ('[' 'reveal' 'correct' 'answer' ']' {revealAnswer=true;})? ;
  
QAPART: QUESTION | QASECTION;

QASECTION: 
  'Section' (name=ID)? ':' title=STRING 
  '{'
    (containerOptions=QACONTAINER_OPTIONS)?
    (q=QUESTION)*
  '}';

QUESTION:
  'Question' (name=ID)? ':' text=STRING '->' correct=ANSWER '!'
  ('Candidates' '{' candidate=ANSWER (',' candidate=ANSWER)* '}')?
  (nextRule=NEXTRULE (',' nextRule=NEXTRULE)* )? ;
  
NEXTRULE: 'Jumpto' next=[QAPART | STRING] 'if' 'less' 'than' tries=INT 'tries';

ANSWER: (TEXTANSWER | NUMBERANSWER | YESNOANSWER | OPTIONANSWER);

TEXTANSWER: text=STRING;

NUMBERANSWER: 
  (EXPRESSIONANSWER | number=DOUBLE)
  ('+-' epsilon=DOUBLE)? ;

EXPRESSIONANSWER: 'eval' expression=STRING;

YESNOANSWER: {boolean yes=false;} ('no' | {yes=true;}'yes');

OPTIONANSWER: '#' optionNumber=INT;

fragment LETTER:
('a'..'z'|'A'..'Z');

ID: LETTER ('0'..'9'|LETTER|'_')*;

WS: (' '| '\t' | '\r' | '\n')+{skip();};

INT : ('0'..'9')+;

STRING : ('"' ('\\' .|~(('\\'|'"')))* '"'|'\'' ('\\' .|~(('\\'|'\'')))* '\'');

ML_COMMENT : '/*' ( options {greedy=false;} : . )*'*/';

SL_COMMENT : '//' ~(('\n'|'\r'))* ('\r'? '\n')?;

SCAN_ERROR: . {System.out.println("Trovato errore: "+myVar++);} ;

DOUBLE: '-'? INT ('.' INT (('E'|'e') '-'? INT)?)?;
