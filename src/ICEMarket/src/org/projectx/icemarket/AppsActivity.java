package org.projectx.icemarket;

import android.os.Bundle;
import org.projectx.icemarket.R;

public class AppsActivity extends ScriptedActivity {
	public boolean onItemSelected(String itemAction, String itemDescription) {
		ICEMarket.getInstance().getTabHost().setCurrentTab(ICEMarket.TAB_CONSOLE);
		return true;
	}
	
	public void onCreate(Bundle savedInstanceState) {		
		this.actions      = getResources().getStringArray(R.array.apps_array);
		this.descriptions = getResources().getStringArray(R.array.descriptions_array);
		super.onCreate(savedInstanceState);		
	}	
}
