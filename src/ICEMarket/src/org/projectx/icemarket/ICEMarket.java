package org.projectx.icemarket;

import org.projectx.icemarket.R;

import android.app.TabActivity;
import android.content.Intent;
import android.content.res.Resources;
import android.os.Bundle;
import android.widget.TabHost;
import android.widget.TextView;

public class ICEMarket extends TabActivity {
	TextView   consoleView = null;
	
	public static final int TAB_APPS = 0;			
	public static final int TAB_CONSOLE = 1;	
		
	/// Singleton //////////////////////////////////////////
    private static ICEMarket INSTANCE = null;     

    private synchronized static void setInstance(ICEMarket theInstance) {
        if (INSTANCE == null) { 
            INSTANCE = theInstance;
        }
    }
    public static ICEMarket getInstance() {
        return INSTANCE;
    }	
	public Object clone() throws CloneNotSupportedException {
        throw new CloneNotSupportedException(); 
	}
	////////////////////////////////////////////////////////
		
	public void onCreate(Bundle savedInstanceState) {
	    super.onCreate(savedInstanceState);
	    setContentView(R.layout.main);
	    
	    // So we an get it later
	    ICEMarket.setInstance(this);
	    
	    Resources res = getResources(); // Resource object to get Drawables
	    TabHost tabHost = getTabHost();  // The activity TabHost
	    TabHost.TabSpec spec;  // Resusable TabSpec for each tab
	    Intent intent;  // Reusable Intent for each tab

	    // Create an Intent to launch an Activity for the tab (to be reused)
	    // Actions tab
	    intent = new Intent().setClass(this, AppsActivity.class);	    
	    spec = tabHost.newTabSpec("actions").setIndicator("Apps",
	                      res.getDrawable(R.drawable.ic_tab_apps))
	                  .setContent(intent);
	    tabHost.addTab(spec);
	    
	    // Console tab
	    intent = new Intent().setClass(this, ConsoleActivity.class);
	    spec = tabHost.newTabSpec("console").setIndicator("Console",
	                      res.getDrawable(R.drawable.ic_tab_console))
	                  .setContent(intent);
	    tabHost.addTab(spec);
	    
	    	    
	    // In order to get a consoleView, as ConsoleActivity will
	    // invoke this.setConsoleView()
	    tabHost.setCurrentTab(TAB_CONSOLE);
	}

	public void setConsoleView(TextView textView) {
		consoleView = textView;		
	}

	public TextView getConsoleView() {
		return consoleView;
	}
	
}
