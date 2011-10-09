package org.projectx.icemarket;

import android.app.ListActivity;
import org.projectx.icemarket.R;
import android.os.Bundle;
import android.view.View;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ArrayAdapter;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

public abstract class ScriptedActivity extends ListActivity {

	// These members must be initialited on children onCreate() methods
	String[]       actions = null;
	String[]       descriptions = null;
	TextView       consoleView = null;
	
	// Execution environment
	ScriptExecuter sce = null;

	public ScriptedActivity() {
		super();
	}
	
	public boolean onItemSelected(String itemAction, String itemDescription) {
		// Override on children
		// Return false is action aborted
		return true;
	}
	
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
	
		setListAdapter(new ArrayAdapter<String>(this, R.layout.list_item, descriptions));
	
		ListView lv = getListView();
		lv.setTextFilterEnabled(true);
	
		lv.setOnItemClickListener(new OnItemClickListener() {
			public void onItemClick(AdapterView<?> parent, View view,
					int position, long id) {
				
				String action      = actions[position];
				String description = ((TextView) view).getText().toString();
				
				// Allow children to inhibit execution / switch to console / whatever
				if (!onItemSelected(action, description)) {
			      return;
				}
				
				// Special activity
				if (isSpecialActivity(action)) {
				  runSpecialActivity(action);
				  return;
				}
				
				// When clicked, show a toast with the TextView text
				Toast.makeText(getApplicationContext(), ((TextView) view).getText(),
						Toast.LENGTH_SHORT).show();				
				try {
					sce = new ScriptExecuter();					
					sce.setScript(action);
					sce.run();
					//sce.wait();
				} catch (Exception e) {
					ICEMarket.getInstance().getConsoleView().append(e.getStackTrace().toString() + "\n");
				}								
			}

			// Dirty hack
			private void runSpecialActivity(String action) {
				if (action.equals("clearconsole")) {
					ICEMarket.getInstance().getConsoleView().setText("");
				}				
			}

			private boolean isSpecialActivity(String action) {
				if (action.equals("clearconsole")) {
					return true;
				}
				return false;
			}
		});
	}

}
