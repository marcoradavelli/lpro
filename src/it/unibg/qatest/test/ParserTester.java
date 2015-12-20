package it.unibg.qatest.test;

import java.io.FileReader;

import org.antlr.runtime.*;

import it.unibg.qatest.QatestLexer;
import it.unibg.qatest.QatestParser;

public class ParserTester {
	static QatestParser parser;

	public static void main(String[] args) {
		CommonTokenStream tokens;
		String fileIn = args.length>0 ? args[0] : "Resources/input.qa";

		try {
			QatestLexer lexer = new QatestLexer(new ANTLRReaderStream(new FileReader(fileIn)));
			tokens = new CommonTokenStream(lexer);
			parser = new QatestParser(tokens);
			parser.qaTest();
			System.out.println("Congratulations! You're done! (Total score: "+parser.env.totalScore+"/"+parser.env.maxScore+")\n\n");
		} catch (Exception e) {
			System.out.println("Parsing aborted\n\n");
			e.printStackTrace();
		}
		
	}
}

