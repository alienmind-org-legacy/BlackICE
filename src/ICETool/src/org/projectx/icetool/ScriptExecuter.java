package org.projectx.icetool;

import java.io.BufferedReader;
import java.io.InputStreamReader;

import android.os.AsyncTask;
import android.widget.TextView;


public class ScriptExecuter extends AsyncTask<String, String, Integer> {
	static final String CMD_SU="/system/xbin/su";
	static final String CMD_C="-c";
	private TextView       consoleView  = null;
			
    protected Integer doInBackground(String...cmds) {
        int count = cmds.length;
        for (int i = 0; i < count; i++) {
            executeCommand(cmds[i]);
        }
        return Integer.valueOf(count);
    }

    protected void onProgressUpdate(String... inputLines) {
        for (String line : inputLines) {
           consoleView.append(line+ "\n");
        }
    }

    protected void onPostExecute(Long result) {
    	consoleView.append("== Finished, return value is " + result.toString() + " ==\n");
    }	

	private void executeCommand(String cmd) {
		String[] str={CMD_SU,CMD_C,cmd};
		consoleView = ICETool.getInstance().getConsoleView();
		
		if (consoleView == null)
			return;
		
		try {
			publishProgress("==== Starting execution: " + cmd + " ====\n");			
			Process p = Runtime.getRuntime().exec(str);
			BufferedReader br = new BufferedReader(new InputStreamReader(p.getInputStream()));
			try {
			  String   inputLine = br.readLine();
			  while ((inputLine = br.readLine()) != null)				 
				publishProgress(inputLine + "\n");
			} catch (Exception e) {
				return;
			}
			
		} catch (Exception e) {			
			publishProgress(e.toString() + "\n");
		}
	}    
}
