#pragma semicolon 1

#include <sourcemod>

#include <timer>
#include <timer-logging>
#include <timer-stocks>
#include <timer-mapzones>
#include <timer-config_loader>



public Plugin:myinfo =
{
    name        = "[TIMER] Quickstyle Commands",
    author      = "Zipcore, DR. API Improvements",
    description = "[Timer] Change style with quick commands without style selection",
    version     = PL_VERSION,
    url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
	if(!Timer_IsEnabled()) return;
	LoadPhysics();
	LoadTimerSettings();

	if(g_Settings[MultimodeEnable])
	{
		for(new i = 0; i < MAX_STYLES-1; i++) 
		{
			if(StrEqual(g_Physics[i][StyleQuickCommand], ""))
				continue;
			
			RegConsoleCmd(g_Physics[i][StyleQuickCommand], Callback_Empty);
			AddCommandListener(Hook_Command, g_Physics[i][StyleQuickCommand]);
		}
	}
}

public OnMapZonesLoaded()
{
	// If map has start and end.
	if(Timer_GetMapzoneCount(ZtStart) == 0 || Timer_GetMapzoneCount(ZtEnd) == 0) {
		//SetFailState("MapZones start and end points not found! Disabling!");
		
	}
}

public OnMapStart()
{
	if(!Timer_IsEnabled()) return;
	LoadPhysics();
	LoadTimerSettings();
}

public Action:Callback_Empty(client, args)
{
	return Plugin_Handled;
}

public Action:Hook_Command(client, const String:sCommand[], argc)
{
	if(!Timer_IsEnabled()) return Plugin_Continue;
	if (!IsValidClient(client))
	{
		return Plugin_Continue;
	}
	for(new i = 0; i < MAX_STYLES-1; i++) 
	{
		if(!g_Physics[i][StyleEnable])
			continue;
		if(StrEqual(g_Physics[i][StyleQuickCommand], ""))
			continue;
		if(StrEqual(g_Physics[i][StyleQuickCommand], sCommand))
		{
			Timer_SetStyle(client, i);
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}