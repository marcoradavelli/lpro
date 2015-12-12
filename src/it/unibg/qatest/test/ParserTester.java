package it.unibg.qatest.test;

import java.io.FileReader;
import java.util.Hashtable;

import org.antlr.runtime.*;

import it.unibg.qatest.QatestLexer;
import it.unibg.qatest.QatestParser;

public class ParserTester {
	static QatestParser parser;

	public static void main(String[] args) {
		CommonTokenStream tokens;
		String fileIn = "Resources/input.qa";

		try {
			System.out.println("Parsing iniziato");
			QatestLexer lexer = new QatestLexer(new ANTLRReaderStream(new FileReader(fileIn)));
			tokens = new CommonTokenStream(lexer);
			parser = new QatestParser(tokens);
			parser.qaTest();
			System.out.println("Parsing terminato con successo\n\n");
		} catch (Exception e) {
			System.out.println("Parsing abortito\n\n");
			e.printStackTrace();
			
			Hashtable<String,String> h = new Hashtable<String,String>();
		}
		
	}
}
