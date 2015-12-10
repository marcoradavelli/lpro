grammar Qatest;

options {
  language = Java;
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
  {boolean revealAnswer=false;}
  ('[' 'reveal' 'correct' 'answer' ']' {revealAnswer=true;})?
  ('[' 'max' maxTries=INT 'tries' ']');
  
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
  (expressionAnswer | number=INT | number=DOUBLE) // se mettevo solo DOUBLE, dava errore di "no viable input" in alcuni casi.
  ('+-' epsilon=DOUBLE)? ;

expressionAnswer: 'eval' expression=STRING;

yesNoAnswer: {boolean yes=false;} ('no' | {yes=true;}'yes');

optionAnswer: '#' optionNumber=INT;


// lexer

ID : '^'? ('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'_'|'0'..'9')*;

INT : ('0'..'9')+;

DOUBLE: '-'? INT ('.' INT (('E'|'e') '-'? INT)?)? ;

STRING : ('"' ('\\' .|~(('\\'|'"')))* '"'|'\'' ('\\' .|~(('\\'|'\'')))* '\'');

ML_COMMENT : '/*' ( options {greedy=false;} : . )*'*/';

SL_COMMENT : '//' ~(('\n'|'\r'))* ('\r'? '\n')?;

WS: (' '| '\t' | '\r' | '\n')+{skip();};

SCAN_ERROR: . {System.out.println("Trovato errore");} ;
