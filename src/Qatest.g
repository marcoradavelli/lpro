grammar Qatest;

options {
  language = Java;
}

@header{
  package it.unibg.qatest;
  import java.io.*;
  import java.util.Hashtable;
  import javax.script.*;
  import it.unibg.qatest.environment.*;
}

@lexer::header {
  package it.unibg.qatest;
}

@members {
  public ParserEnvironment env = new ParserEnvironment();
}

// parser

qaTest: 'Title: ' string (opt=qaContainerOptions)? (qaPart[opt!=null ? opt : env.createDefaultOptions()])*;

qaContainerOptions returns[Hashtable<String,String> value]:
  { value=env.createDefaultOptions(); }
  (qaRevealOption { value.put("revealAnswer","true"); })?
  (maxTries=qaMaxTriesOption { value.put("maxTries",""+maxTries); })
  (caseSensitive=qaCaseSensitivity { value.put("caseSensitive",""+caseSensitive); })? ;

qaRevealOption: '[' 'reveal' 'correct' 'answer' ']';

qaMaxTriesOption returns[int maxTries]: 
  '[' 'max' val=INT 'tries' ']' 
  { maxTries=Integer.parseInt($val.getText()); };

qaCaseSensitivity returns[boolean isCaseSensitive]: 
  ('[' 'case' 'sensitive' ']' {isCaseSensitive=true;}) | ('[' 'case' 'insensitive' ']' {isCaseSensitive=false;});

qaPart[Hashtable<String,String> opt]: question[opt] | qaSection[opt];

qaSection[Hashtable<String,String> value]: 
  'Section' (name=ID)? ':' title=string 
  '{'
    { env.doSection(title); }
    (containerOptions=qaContainerOptions {value.putAll(containerOptions);})?
    (q=question[value])*
  '}';

question[Hashtable<String,String> value]:
  'Question' (name=ID)? ':' {score=1;} (score=scoreOption)? text=string '->' correctAns=correctAnswers '!'
  (candidates=candidateAnswers)?
  (nextRules=jumpRules)? 
  { env.doQuestion($name, text, value, candidates, correctAns, nextRules, score); };

correctAnswers returns[ArrayList<Hashtable<String,String>> correctAnswers]:
  { correctAnswers = new ArrayList<>(); }
  (value=answer {correctAnswers.add(value);} | ('{' value=answer {correctAnswers.add(value);} (',' value=answer {correctAnswers.add(value);} )* '}') );

candidateAnswers returns[ArrayList<Hashtable<String,String>> candidates]:
  { candidates = new ArrayList<>(); }
  'Candidates' '{' candidate=answer { candidates.add(candidate); } (',' candidate=answer { candidates.add(candidate); } )* '}';

jumpRules returns[ArrayList<Hashtable<String,String>> nextRules]:
  { nextRules = new ArrayList<>(); }
  next=nextRule {nextRules.add(next);} (',' next=nextRule {nextRules.add(next);})*;

nextRule returns[Hashtable<String,String> value]: 
  { value = new Hashtable<>(); }
  'Jumpto' next=string { value.put("next",next); } 'if' 'less' 'than' tries=INT 'tries' { value.put("tries",$tries.getText()); };

answer returns[Hashtable<String,String> value]: 
  (ans=textAnswer {value=ans;} | ans=numberAnswer {value=ans;} | ans=yesNoAnswer {value=ans;} | ans=optionAnswer{value=ans;});

textAnswer returns[Hashtable<String,String> value]: 
  text=string { value=new Hashtable<>(); value.put("answerType","text"); value.put("value", text); };

numberAnswer returns[Hashtable<String,String> value]: 
  { value = new Hashtable<>(); value.put("answerType", "number"); }
  (expression=expressionAnswer { value.put("value",""+expression); } | number=INT { value.put("value",$number.getText()); } | number=DOUBLE { value.put("value",$number.getText()); }) // se mettevo solo DOUBLE, dava errore di "no viable input" in alcuni casi.
  (epsilon=range { value.put("epsilon", ""+epsilon); })? ;

range returns[double value]:
  '+-' epsilon=DOUBLE { value=Double.parseDouble($epsilon.getText()); };

expressionAnswer returns[double value]: 
  'eval' expression=string { 
    value = env.eval(expression);
  };

yesNoAnswer returns[Hashtable<String,String> value]: 
  { value = new Hashtable<>(); value.put("answerType", "yesno"); value.put("value", "false"); } 
  ('no' | 'yes' { value.put("value", "true"); } );

optionAnswer returns[Hashtable<String,String> value]: 
  { value = new Hashtable<>(); value.put("answerType", "option"); } 
  '#' optionNumber=INT
  { value.put("value", $optionNumber.getText()); };

string returns[String value]: 
  val=STRING { value=$val.getText().substring(1,$val.getText().length()-1); };
  
scoreOption returns[int points]:
  '[' val=INT 'points' ']' { points = Integer.parseInt($val.getText()); };

// lexer

ID : '^'? ('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'_'|'0'..'9')*;

INT : ('0'..'9')+;

DOUBLE: '-'? INT ('.' INT (('E'|'e') '-'? INT)?)? ;

STRING : ('"' ('\\' .|~(('\\'|'"')))* '"'|'\'' ('\\' .|~(('\\'|'\'')))* '\'');

ML_COMMENT : '/*' ( options {greedy=false;} : . )*'*/';

SL_COMMENT : '//' ~(('\n'|'\r'))* ('\r'? '\n')?;

WS: (' '| '\t' | '\r' | '\n')+{skip();};

SCAN_ERROR: . {System.out.println("Trovato errore");} ;
