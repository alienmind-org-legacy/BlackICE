package org.projectx.icetool;

import android.os.Bundle;

public class AppsActivity extends ScriptedActivity {
	public boolean onItemSelected(String itemAction, String itemDescription) {
		ICETool.getInstance().getTabHost().setCurrentTab(ICETool.TAB_CONSOLE);
		return true;
	}
	
	public void onCreate(Bundle savedInstanceState) {
		initList("apps");
		super.onCreate(savedInstanceState);		
	}	
}
