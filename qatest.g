lexer grammar qatest;

options {
  language = Java;
}

@lexer::header {
   package it.unibg.qatest;
}

@lexer::members {
}


WHILE: 'WHILE';   // put always  keywords on top
WHI: ('W' | 'w')('H' | 'h')('I' | 'i');

fragment LETTER:
('a'..'z'|'A'..'Z');

ID: LETTER ('0'..'9'|LETTER|'_')*;
WS: (' '| '\t' | '\r' | '\n')+{skip();};

SCAN_ERROR: . {System.out.println("Trovato errore: "+myVar++);} ;
