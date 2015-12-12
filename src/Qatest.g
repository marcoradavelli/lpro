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
  String skip=null;
  boolean skipIsSection;
  
  String read(String s) {
    if (skip!=null) return null;
    System.out.print(s+" ");
    BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
    try {
      return br.readLine();
    } catch (Exception e) {e.printStackTrace(); return "";}
  }
  double readDouble(String s) {
    return Double.parseDouble(read(s));
  }
  boolean readBoolean(String s, String yes, String no) {
    return read(s).equalsIgnoreCase(yes);
  }
  
  boolean checkInRange(double expected, double actual, double epsilon) {
    return expected<=actual+epsilon && expected>=actual-epsilon;
  }
  
  void println(String s) {
    if (skip==null) System.out.println(s);
  }
  
  Hashtable<String,String> createDefaultOptions() {
    Hashtable<String,String> value=new Hashtable<String,String>(); 
    value.put("maxTries","1"); 
    value.put("revealAnswer","false");
    return value;
  }
  
  double eval(String s) {
    ScriptEngineManager manager = new ScriptEngineManager(); //Source: http://stackoverflow.com/questions/2605032/is-there-an-eval-function-in-java
    ScriptEngine engine = manager.getEngineByName("js");
    try {
      return (Double)engine.eval(s);
    } catch (Exception e) {e.printStackTrace(); return 0;}
  }
}

// parser

qaTest: 'Title: ' string (qaContainerOptions)? (qaPart)*;

qaContainerOptions returns[Hashtable<String,String> value]:
  { value=createDefaultOptions(); }
  (qaRevealOption { value.put("revealAnswer","true"); })?
  (maxTries=qaMaxTriesOption { value.put("maxTries",""+maxTries); });

qaRevealOption: '[' 'reveal' 'correct' 'answer' ']';

qaMaxTriesOption returns[int maxTries]: 
  '[' 'max' val=INT 'tries' ']' 
  { maxTries=Integer.parseInt($val.getText()); };

qaPart: question[createDefaultOptions()] | qaSection;

qaSection: 
  'Section' (name=ID)? ':' title=string 
  '{'
    { 
    if (skip!=null && skip.equals(title)) skip=null;
    println("Section "+title); 
    Hashtable<String,String> value = createDefaultOptions();
    }
    (containerOptions=qaContainerOptions {value = containerOptions;})?
    (q=question[value])*
  '}';

question[Hashtable<String,String> value]:
  'Question' (name=ID)? ':' text=string '->' correct=answer '!'
  (candidates=candidateAnswers)?
  (nextRules=jumpRules)? 
  { 
  boolean isCorrect=false; // at the beginning it should be false, otherwise it would skip the question
  int count=0;
  if (skip!=null && $name!=null && skip.equals($name.getText())) skip=null;
  if (skip==null) {
    while (!isCorrect && count < Integer.parseInt(value.get("maxTries"))) {
      println(text);
      if (candidates!=null && candidates.size()>0) {
        for (int i=0; i<candidates.size(); i++) {
          println((i+1)+") "+candidates.get(i).get("value"));
        } 
      }
      String type=correct.get("answerType");
      if (type.equals("option")) isCorrect = Integer.parseInt(correct.get("value"))==Integer.parseInt((read("Select option (1 - "+candidates.size()+"): ")));
      else if (type.equals("text")) isCorrect = correct.get("value").equalsIgnoreCase(read("Your answer"));
	    else if (type.equals("number")) isCorrect = checkInRange(Double.parseDouble(correct.get("value")), readDouble("Your answer"), correct.containsKey("epsilon") ? Double.parseDouble(correct.get("epsilon")) : 0);
	    else if (type.equals("yesno")) isCorrect = (readBoolean("Your answer","yes","no")==Boolean.parseBoolean(correct.get("value")));
      println(isCorrect ? "Correct!" : "Wrong!"); 
      count++;
    }
    if (nextRules!=null && nextRules.size()>0 && isCorrect) {
      for (Hashtable<String,String> rule : nextRules) {
        if (count < Integer.parseInt(rule.get("tries"))) {
          skip = rule.get("next");
        }
      }
    }
    if (!isCorrect) {
      println("No more tries available for this question.");
      if (Boolean.parseBoolean(value.get("revealAnswer"))) {
        println("The correct answer is " + correct.get("value"));
      }
    }
  }
  };
  
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
  (epsilon=range { value.put("range", ""+epsilon); })? ;

range returns[double value]:
  '+-' epsilon=DOUBLE { value=Double.parseDouble($epsilon.getText()); };

expressionAnswer returns[double value]: 
  'eval' expression=string { 
    value = eval(expression);
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
  

// lexer

ID : '^'? ('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'_'|'0'..'9')*;

INT : ('0'..'9')+;

DOUBLE: '-'? INT ('.' INT (('E'|'e') '-'? INT)?)? ;

STRING : ('"' ('\\' .|~(('\\'|'"')))* '"'|'\'' ('\\' .|~(('\\'|'\'')))* '\'');

ML_COMMENT : '/*' ( options {greedy=false;} : . )*'*/';

SL_COMMENT : '//' ~(('\n'|'\r'))* ('\r'? '\n')?;

WS: (' '| '\t' | '\r' | '\n')+{skip();};

SCAN_ERROR: . {System.out.println("Trovato errore");} ;
