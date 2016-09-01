#include <sourcemod>
#include <timer>
#include <timer-mapzones>

new bool:enabled = true;
 
public Plugin:myinfo =
{
	name = "[TIMER] Hide Commands",
	author = "Rop, DR. API Improvements",
	description = "hides chat commands",
	version = PL_VERSION,
	url = "https://github.com/Zipcore/Timer"
}
 
public OnPluginStart()
{
	AddCommandListener(HideCommands,"say");
	AddCommandListener(HideCommands,"say_team");
}

public OnMapZonesLoaded()
{
	// If map has start and end.
	if(Timer_GetMapzoneCount(ZtStart) == 0 || Timer_GetMapzoneCount(ZtEnd) == 0) {
		//SetFailState("MapZones start and end points not found! Disabling!");
		enabled = false;
	}
}
 
public Action:HideCommands(client, const String:command[], argc)
{
	if(!enabled) return Plugin_Continue;
	if(IsChatTrigger())
		return Plugin_Handled;
   
	return Plugin_Continue;
}