package it.unibg.qatest.environment;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.Hashtable;

import javax.script.ScriptEngine;
import javax.script.ScriptEngineManager;

import org.antlr.runtime.Token;

public class ParserEnvironment {
	public String skip = null;
	public int totalScore;
	public int maxScore;

	/** reads the user's answer to a question
	 * @param s the question to be printed out
	 * @return the user's input, as String, or an empty string if an Exception occurred
	 */
	String read(String s) {
		if (skip != null) return null;
		System.out.print(s + "? ");
		BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
		try { return br.readLine(); } catch (Exception e) { e.printStackTrace(); return ""; }
	}

	/** @return the user's answer, as Double value */
	double readDouble(String s) {
		return Double.parseDouble(read(s));
	}

	/** @return the user's answer as Int value */
	boolean readBoolean(String s, String yes, String no) {
		return read(s).equalsIgnoreCase(yes);
	}

	/** @return if a value is contained between the expected value, +- epsilon */
	boolean checkInRange(double expected, double actual, double epsilon) {
		return expected <= actual + epsilon && expected >= actual - epsilon;
	}

	/** Prints a string to the console, if we are not in a skipping section */
	void println(String s) {
		if (skip == null) System.out.println(s);
	}

	/** Creates the Hashtable of the default options */
	public Hashtable<String, String> createDefaultOptions() {
		Hashtable<String, String> value = new Hashtable<String, String>();
		value.put("maxTries", "1");
		value.put("revealAnswer", "false");
		return value;
	}

	/** Evaluates the expression with the JavaScript engine
	 * @return the Double value resulting from the evaluation of the expression */
	public double eval(String s) {
		ScriptEngineManager manager = new ScriptEngineManager(); // Source: http://stackoverflow.com/questions/2605032/is-there-an-eval-function-in-java
		ScriptEngine engine = manager.getEngineByName("js");
		try {
			return (Double) engine.eval(s);
		} catch (Exception e) {
			e.printStackTrace();
			return 0;
		}
	}
	
	/** Method responsible for the action associated to the production rule QASection */
	public void doSection(String title) {
		if (skip!=null && skip.equals(title)) skip=null;
		println("Section "+title); 
	}

	/** Method responsible for the action associated to the production rule QAQuestion */
	public void doQuestion(Token name, String text, Hashtable<String,String> value, ArrayList<Hashtable<String,String>> candidates, ArrayList<Hashtable<String,String>> correctAns, ArrayList<Hashtable<String,String>> nextRules, int score) {
		boolean isCorrect=false; // at the beginning it should be false, otherwise it would env.skip the question
		int count=0;
		if (skip!=null && name!=null && skip.equals(name.getText())) skip=null;
		if (skip==null) {
			while (!isCorrect && count < Integer.parseInt(value.get("maxTries"))) {	
				println(text);
				if (candidates!=null && candidates.size()>0) {
					for (int i=0; i<candidates.size(); i++) {
						println((i+1)+") "+candidates.get(i).get("value"));
					} 
				}
				for (Hashtable<String,String> correct : correctAns) {
					String type=correct.get("answerType");
					if (type.equals("option")) isCorrect = Integer.parseInt(correct.get("value"))==Integer.parseInt((read("Select option (1 - "+candidates.size()+")")));
					else if (type.equals("text")) isCorrect = (value.containsKey("caseSensitive") && Boolean.parseBoolean(value.get("caseSensitive"))) ? correct.get("value").equals(read("Your answer")) : correct.get("value").equalsIgnoreCase(read("Your answer"));
					else if (type.equals("number")) isCorrect = checkInRange(Double.parseDouble(correct.get("value")), readDouble("Your answer"), correct.containsKey("epsilon") ? Double.parseDouble(correct.get("epsilon")) : 0);
					else if (type.equals("yesno")) isCorrect = (readBoolean("Your answer","yes","no")==Boolean.parseBoolean(correct.get("value")));
					if (isCorrect) break; // if one correct answer is found, then break the cycle.
				}
				println(isCorrect ? "Correct!" : "Wrong!"); 
				count++;
			}
			maxScore+=score;
			if (isCorrect) totalScore+=score;
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
					println("The correct answer is " + correctAns.get(0).get("value"));
				}
			}
		}
	}
}
