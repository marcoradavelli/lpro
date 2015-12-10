grammar Qatest;

options {
  language = Java;
  k=1;
}

@header{
  package it.unibg.qatest;
}

@lexer::header {
  package it.unibg.qatest;
}

@members {
  
}

// parser

qaTest: 'Title: ' STRING (qaContainerOptions)? (qaPart)*;

qaContainerOptions:
  ('[' 'max' maxTries=INT 'tries' ']')
  {boolean revealAnswer=false;}
  ('[' 'reveal' 'correct' 'answer' ']' {revealAnswer=true;})? ;
  
qaPart: question | qaSection;

qaSection: 
  'Section' (name=ID)? ':' title=STRING 
  '{'
    (containerOptions=qaContainerOptions)?
    (q=question)*
  '}';

question:
  'Question' (name=ID)? ':' text=STRING '->' correct=answer '!'
  ('Candidates' '{' candidate=answer (',' candidate=answer)* '}')?
  (next=nextRule (',' next=nextRule)* )? ;
  
nextRule: 'Jumpto' (qaPart | next=STRING) 'if' 'less' 'than' tries=INT 'tries';

answer: (textAnswer | numberAnswer | yesNoAnswer | optionAnswer);

textAnswer: text=STRING;

numberAnswer: 
  (expressionAnswer | number=DOUBLE)
  ('+-' epsilon=DOUBLE)? ;

expressionAnswer: 'eval' expression=STRING;

yesNoAnswer: {boolean yes=false;} ('no' | {yes=true;}'yes');

optionAnswer: '#' optionNumber=INT;


// lexer

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
