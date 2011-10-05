package org.projectx.icetool;

import org.projectx.icetool.R;

import android.app.TabActivity;
import android.content.Intent;
import android.content.res.Resources;
import android.os.Bundle;
import android.widget.TabHost;
import android.widget.TextView;

public class ICETool extends TabActivity {
	TextView   consoleView = null;
	
	public static final int TAB_ACTIONS = 0;
	public static final int TAB_UV = 1;
	public static final int TAB_EXTRA = 2;
	public static final int TAB_GPS = 3;	
	public static final int TAB_DSP = 4;
	public static final int TAB_RIL = 5;		
	public static final int TAB_CONSOLE = 6;	
		
	/// Singleton //////////////////////////////////////////
    private static ICETool INSTANCE = null;     

    private synchronized static void setInstance(ICETool theInstance) {
        if (INSTANCE == null) { 
            INSTANCE = theInstance;
        }
    }
    public static ICETool getInstance() {
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
	    ICETool.setInstance(this);
	    
	    Resources res = getResources(); // Resource object to get Drawables
	    TabHost tabHost = getTabHost();  // The activity TabHost
	    TabHost.TabSpec spec;  // Resusable TabSpec for each tab
	    Intent intent;  // Reusable Intent for each tab

	    // Create an Intent to launch an Activity for the tab (to be reused)
	    // Actions tab
	    intent = new Intent().setClass(this, ActionsActivity.class);	    
	    spec = tabHost.newTabSpec("actions").setIndicator("Actions",
	                      res.getDrawable(R.drawable.ic_tab_actions))
	                  .setContent(intent);
	    tabHost.addTab(spec);

	    // UV tab
	    intent = new Intent().setClass(this, UVActivity.class);
	    spec = tabHost.newTabSpec("uv").setIndicator("UV Settings",
	                      res.getDrawable(R.drawable.ic_tab_uv))
	                  .setContent(intent);
	    tabHost.addTab(spec);

	    // Extras tab
	    intent = new Intent().setClass(this, ExtrasActivity.class);
	    spec = tabHost.newTabSpec("extras").setIndicator("Extras",
	                      res.getDrawable(R.drawable.ic_tab_extras))
	                  .setContent(intent);
	    tabHost.addTab(spec);

	    // GPS tab
	    intent = new Intent().setClass(this, GPSActivity.class);
	    spec = tabHost.newTabSpec("gps").setIndicator("GPS",
	                      res.getDrawable(R.drawable.ic_tab_gps))
	                  .setContent(intent);
	    tabHost.addTab(spec);
	    
	    //DSP chooser tab
	    intent = new Intent().setClass(this, DSPActivity.class);
	    spec = tabHost.newTabSpec("dsp").setIndicator("DSP chooser",
	    				  res.getDrawable(R.drawable.ic_tab_dsp))
	    			  .setContent(intent);
	    tabHost.addTab(spec);

	    //RIL chooser tab
	    intent = new Intent().setClass(this, RILActivity.class);
	    spec = tabHost.newTabSpec("dsp").setIndicator("RIL",
	    				  res.getDrawable(R.drawable.ic_tab_ril))
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
