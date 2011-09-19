package org.projectx.icetool;

import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;
import org.projectx.icetool.R;

public class ConsoleActivity extends Activity {
	TextView consoleTextView = null;
    public void onCreate(Bundle savedInstanceState) {
    	ICETool ap = null;
        super.onCreate(savedInstanceState);
        consoleTextView = new TextView(this);
        consoleTextView.setText("");
        setContentView(consoleTextView);        
        ap = ICETool.getInstance();
        ap.setConsoleView(consoleTextView);
        /*
        ap.getTabHost().setCurrentTab(ICETool.TAB_ACTIONS);
        ap.getTabWidget().getChildAt(ICETool.TAB_CONSOLE).setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {*/
            	if (consoleTextView.getText().equals("")) {
                	consoleTextView.setText(getResources().getText(R.string.app_name) + " " +
                	        getResources().getText(R.string.app_version) +
                	        " by " +
                	        getResources().getText(R.string.app_author) + "\n"                                
                			);	
            	}/*            	
            }
    });
                */


    }
}
