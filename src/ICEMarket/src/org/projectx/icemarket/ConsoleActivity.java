package org.projectx.icemarket;

import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;
import org.projectx.icemarket.R;

public class ConsoleActivity extends Activity {
	TextView consoleTextView = null;
    public void onCreate(Bundle savedInstanceState) {
    	ICEMarket ap = null;
        super.onCreate(savedInstanceState);
        consoleTextView = new TextView(this);
        consoleTextView.setText("");
        setContentView(consoleTextView);        
        ap = ICEMarket.getInstance();
        ap.setConsoleView(consoleTextView);
        /*
        ap.getTabHost().setCurrentTab(ICEMarket.TAB_ACTIONS);
        ap.getTabWidget().getChildAt(ICEMarket.TAB_CONSOLE).setOnClickListener(new View.OnClickListener() {
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
