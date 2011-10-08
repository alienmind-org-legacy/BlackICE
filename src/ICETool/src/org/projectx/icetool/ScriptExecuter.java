package org.projectx.icetool;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.InputStreamReader;

import android.widget.TextView;


public class ScriptExecuter extends Thread {
	static final String CMD_SU     = "/system/xbin/su";
	static final String CMD_C      = "-c";
	static final String CMD_ICETOOL = "icetool";
	String script      = null;
		
	public void setScript(String script) {
		this.script = script;
	}
	
	 
	public void run() {
		String      inputLine = null; 
		// FIXME - the app will always ask for root as su checks for 
		// the full command plus its arguments
		TextView consoleView  = ICETool.getInstance().getConsoleView();		
		
		if (script == null || consoleView == null)
			return;
				
		try {
			consoleView.append("==== Starting execution: " + script + " ====\n");			
			Process p = Runtime.getRuntime().exec(CMD_SU);
		    DataOutputStream os=new DataOutputStream(p.getOutputStream());
		    os.writeBytes(CMD_ICETOOL + " " + script + "\n" + "; exit\n"); 
		    os.flush();
			BufferedReader br = new BufferedReader(new InputStreamReader(p.getInputStream()));
			while ((inputLine = br.readLine()) != null) 
				consoleView.append(inputLine + "\n");
			int ret = p.waitFor();
			consoleView.append("== Finished, return value is " + ret + " ==\n");
		} catch (Exception e) {			
			consoleView.append(e.toString() + "\n");
		}
	}
}
