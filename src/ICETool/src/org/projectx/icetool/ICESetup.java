package org.projectx.icetool;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.InputStreamReader;
import java.util.Hashtable;

public class ICESetup {	
	static final String CMD_SU     = "/system/xbin/su";
	static final String CMD_SH = "sh";
	static final String CMD_SETUP = "/system/bin/icetool setup";
	
	// Key tokens
	static final String STR_COMMANDS = "COMMANDS:";
	static final String STR_CATEGORIES = "CATEGORIES:";
	static final String STR_CATEGORY_COMMANDS = "CATEGORY_COMMANDS:";
	static final String STR_OPTIONS = "OPTIONS:";
	static final String STR_DESCRIPTIONS = "DESCRIPTIONS:";	
	
	// Parsed data
	private      String rawData = "";
	String allCategories[];	
	String allCommands[];	
	Hashtable<String, String[]> categoryCommands = 
    		new Hashtable<String,String[]>();	
	Hashtable<String, String[]> cmdOptions = 
			new Hashtable<String,String[]>();
    Hashtable<String, String[]> cmdDescriptions = 
    		new Hashtable<String,String[]>();
    		

    private String[] parseSimpleLine(String key, String line) {
    	String l      = line.substring(key.length()).trim();
    	return l.split("@");		    			
    }
    
    private void parseArgsLine(Hashtable<String,String[]> hsh, boolean addKeyToValue, String key,  String line) {
		String l      = line.substring(key.length()).trim(); 
		String str[]  = l.split(":");
		String token    = str[0];
		String tokens[] = str[1].split("@");
		if (!cmdOptions.containsKey(token)) {
			if ( addKeyToValue )
				for (int i=0;i<tokens.length;i++) {
					tokens[i] = token+" "+tokens[i]; // the command should be in the option too 	
				}
			hsh.put(token, tokens);  	
		}
    }
    
	String run() throws Exception {
		String      inputLine = null;
		
		Process p = Runtime.getRuntime().exec(CMD_SU);		
	    DataOutputStream os=new DataOutputStream(p.getOutputStream());
	    os.writeBytes(CMD_SH + " " + CMD_SETUP + "\n" + "; exit\n"); 
	    os.flush();
		BufferedReader br = new BufferedReader(new InputStreamReader(p.getInputStream()));
		while ((inputLine = br.readLine()) != null) { 
			String line = inputLine + "\n";
			if (line.startsWith(STR_COMMANDS)) {
				allCommands = parseSimpleLine(STR_COMMANDS,line);
			} else if (line.startsWith(STR_CATEGORIES))
				allCategories = parseSimpleLine(STR_CATEGORIES,line);
			else if (line.startsWith(STR_CATEGORY_COMMANDS))
				parseArgsLine(categoryCommands, false, STR_CATEGORY_COMMANDS, line);
			else if (line.startsWith(STR_OPTIONS))
				parseArgsLine(cmdOptions, true, STR_OPTIONS, line);
			else if (line.startsWith(STR_DESCRIPTIONS))
				parseArgsLine(cmdDescriptions, false, STR_DESCRIPTIONS, line);
			
			rawData += line;
		}
		p.waitFor();		
		return rawData;
	}

	
	public String getRawData() {
		return rawData;
	}
	public boolean hasCategory(String cat) {
		return categoryCommands.containsKey(cat);
	}
	public String[] getCategoryCommands(String cat) {
		return categoryCommands.get(cat);	
	}	
	public boolean hasCommand(String cmd) {
		return cmdOptions.containsKey(cmd);
	}
	public String[] getCommandOptions(String cmd) {		
		return cmdOptions.get(cmd);		
	}
	public String[] getCommandDescriptions(String cmd) {
		return cmdDescriptions.get(cmd);
	}
	
}
