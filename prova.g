lexer grammar prova;

options {
  language = Java;
}

@lexer::header {
   package myCompiler;
}

@lexer::members {
  public int myVar=0;

    public void myFunction() {
    }
}


WHILE: 'WHILE';   // put always keywords on top
WHI: ('W' | 'w')('H' | 'h')('I' | 'i');

fragment LETTER:
('a'..'z'|'A'..'Z');

ID: LETTER ('0'..'9'|LETTER|'_')*;
WS: (' '| '\t' | '\r' | '\n')+{skip();};

SCAN_ERROR: . {System.out.println("Trovato errore: "+myVar++);} ;
