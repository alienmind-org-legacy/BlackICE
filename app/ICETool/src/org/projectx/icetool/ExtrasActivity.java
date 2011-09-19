package org.projectx.icetool;

import android.os.Bundle;
import org.projectx.icetool.R;

public class ExtrasActivity extends ScriptedActivity {
	public boolean onItemSelected(String itemAction, String itemDescription) {
		ICETool.getInstance().getTabHost().setCurrentTab(ICETool.TAB_CONSOLE);
		return true;
	}
	
	public void onCreate(Bundle savedInstanceState) {		
		this.actions      = getResources().getStringArray(R.array.extra_actions_array);
		this.descriptions = getResources().getStringArray(R.array.extra_descriptions_array);
		super.onCreate(savedInstanceState);		
	}	
}
