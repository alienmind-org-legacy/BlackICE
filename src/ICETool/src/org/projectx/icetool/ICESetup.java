package org.projectx.icetool;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.Hashtable;

public class ICESetup {	
	static final String CMD_SU     = "/system/xbin/su";
	static final String CMD_SH = "sh";
	static final String CMD_SETUP = "/system/bin/icetool setup";

	private      String rawData = "";
	private 	 String capabilities[];
	private      Hashtable<String, String[]> capOptions = 
			new Hashtable<String,String[]>();
    private      Hashtable<String, String[]> capDescriptions = 
    		new Hashtable<String,String[]>();
  
	String readCapabilities() throws Exception {
		String      inputLine = null;
		
		Process p = Runtime.getRuntime().exec(CMD_SU);		
	    DataOutputStream os=new DataOutputStream(p.getOutputStream());
	    os.writeBytes(CMD_SH + " " + CMD_SETUP + "\n" + "; exit\n"); 
	    os.flush();
		BufferedReader br = new BufferedReader(new InputStreamReader(p.getInputStream()));
		while ((inputLine = br.readLine()) != null) { 
			String line = inputLine + "\n";
			if (line.startsWith("CAPABILITIES:")) {
				String cap = line.substring(13); // remove header
				capabilities = cap.split("@");			  			  
			} else {
				String str[]  = line.split(":");
				String opt    = str[0];
				String opts[] = str[1].split("@");
				if (!capOptions.containsKey(opt)) {
					for (int i=0;i<opts.length;i++) {
					   opts[i] = opt+" "+opts[i]; // the command should be in the option too 	
					}
					capOptions.put(opt, opts);
				} else
					capDescriptions.put(opt, opts);
			}			
			rawData += line;
		}
		p.waitFor();		
		return rawData;
	}

	
	public String getRawData() {
		return rawData;
	}

	public boolean hasCapability(String cap) {
		return capOptions.containsKey(cap);
	}

	public String[] getCapabilityOptions(String cap) {		
		return capOptions.get(cap);		
	}
	public String[] getCapabilityDescriptions(String cap) {
		return capDescriptions.get(cap);
	}
	
}
