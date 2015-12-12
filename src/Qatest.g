grammar Qatest;

options {
  language = Java;
}

@header{
  package it.unibg.qatest;
  import java.io.*;
  import java.util.Hashtable;
  import javax.script.*;
}

@lexer::header {
  package it.unibg.qatest;
}

@members {
  String skip;
  boolean skipIsSection;
  
  String read(String s) {
    System.out.print(s);
    BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
    return br.readLine();
  }
  Hashtable<String,String> createDefaultOptions() {
    Hashtable<String,String> value=new Hashtable<String,String>(); 
    value.put("maxTries","1"); 
    value.put("revealAnswer","false");
    return value;
  }
}

// parser

qaTest: 'Title: ' STRING (qaContainerOptions)? (qaPart)*;

qaContainerOptions returns[Hashtable<String,String> value]:
  { boolean revealAnswer=false; value=createDefaultOptions(); }
  ('[' 'reveal' 'correct' 'answer' ']' { value.put("revealAnswer","true"); })?
  ('[' 'max' maxTries=INT 'tries' ']') { value.put("maxTries",$maxTries.getText()); };
  
qaPart: question[createDefaultOptions()] | qaSection;

qaSection: 
  'Section' (name=ID)? ':' title=STRING 
  '{'
    { 
    if (skip!=null && skipIsSection && skip.equals($title.getText())) skip=null;
    System.out.println("Section "+$title.getText()); 
    Hashtable<String,String> value = createDefaultOptions();
    }
    (containerOptions=qaContainerOptions {value = containerOptions;})?
    (q=question[value])*
  '}';

question[Hashtable<String,String> value]:
  'Question' (name=ID)? ':' text=STRING '->' correct=answer '!'
  { ArrayList<Hashtable<String,String>> candidates = new ArrayList<>(); }
  ('Candidates' '{' candidate=answer { candidates.add(candidate); } (',' candidate=answer { candidates.add(candidate); } )* '}')?
  (next=nextRule (',' next=nextRule)* )? 
  { 
  boolean isCorrect=false; // at the beginning it should be false, otherwise it would skip the question
  int count=0;
  if (skip!=null && !skipIsSection && skip.equals($text.getText())) skip=null;
  if (skip==null) {
    while (!isCorrect && count < Integer.parseInt(value.get("maxTries"))) {
      System.out.println($text.getText());
      if (candidates.size()>0) {
        for (int i=0; i<candidates.size(); i++) {
          System.out.println((i+1)+") "+candidates.get(i));
        }
        String s = read("Select option (1 - "+candidates.size()+"): "); 
        isCorrect = s.equals(correct);
        System.out.println(isCorrect ? "Correct!" : "Wrong!"); 
        count++;
      }
    }
    if (!isCorrect) {
      System.out.println("No more tries available for this question.");
      if (Boolean.parseBoolean(value.get("revealAnswer"))) {
        System.out.println("The correct answer is " + correct);
      }
    }
  }
  }
  ;
  
nextRule: 'Jumpto' (qaPart | next=STRING) 'if' 'less' 'than' tries=INT 'tries';

answer returns[Hashtable<String,String> value]: 
  (ans=textAnswer {value=ans;} | ans=numberAnswer {value=ans;} | ans=yesNoAnswer {value=ans;} | ans=optionAnswer{value=ans;});

textAnswer returns[Hashtable<String,String> value]: text=STRING { Hashtable<String,String> value=new Hashtable<>(); value.put("answerType","text"); value.put("value", $text.getText()); };

numberAnswer returns[Hashtable<String,String> value]: 
  { value = new Hashtable<>(); value.put("answerType", "number"); }
  (expression=expressionAnswer { value.put("value",""+expression); } | number=INT { value.put("value",$number.getText()); } | number=DOUBLE { value.put("value",$number.getText()); }) // se mettevo solo DOUBLE, dava errore di "no viable input" in alcuni casi.
  ('+-' epsilon=DOUBLE { value.put("epsilon", $epsilon.getText()); })? ;

expressionAnswer returns[double value]: 
  'eval' expression=STRING { 
    ScriptEngineManager manager = new ScriptEngineManager(); //Source: http://stackoverflow.com/questions/2605032/is-there-an-eval-function-in-java
    ScriptEngine engine = manager.getEngineByName("js");
    value = Double.parseDouble(engine.eval($expression.getText()));
  };

yesNoAnswer returns[Hashtable<String,String> value]: 
  { value = new Hashtable<>(); value.put("answerType", "yesno"); value.put("value", "false"); } 
  ('no' | 'yes' { value.put("value", "true"); } );

optionAnswer returns[Hashtable<String,String> value]: 
  { value = new Hashtable<>(); value.put("answerType", "option"); } 
  '#' optionNumber=INT
  { value.put("value", $optionNumber.getText()); };


// lexer

ID : '^'? ('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'_'|'0'..'9')*;

INT : ('0'..'9')+;

DOUBLE: '-'? INT ('.' INT (('E'|'e') '-'? INT)?)? ;

STRING : ('"' ('\\' .|~(('\\'|'"')))* '"'|'\'' ('\\' .|~(('\\'|'\'')))* '\'');

ML_COMMENT : '/*' ( options {greedy=false;} : . )*'*/';

SL_COMMENT : '//' ~(('\n'|'\r'))* ('\r'? '\n')?;

WS: (' '| '\t' | '\r' | '\n')+{skip();};

SCAN_ERROR: . {System.out.println("Trovato errore");} ;
