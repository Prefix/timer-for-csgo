#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <smlib>
#include <timer>
#include <timer-mapzones>



public Plugin:myinfo =
{
	name        = "[TIMER] Slay after completing",
	author      = "iGANGNAM",
	description = "[Timer] Slay after completing",
	version     = PL_VERSION,
	url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public int OnTimerRecord(client, track, style, Float:time, Float:lasttime, currentrank, newrank) {
	if (!Timer_IsEnabled()) return;
	if(Client_IsValid(client)) {
		CreateTimer(0.1, SlayPlayer, client);
	}
}

public void OnPluginStart() {
	if (!Timer_IsEnabled()) return;
	HookEvent("player_death", Event_PlayerDeath);	
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!Timer_IsEnabled()) return;
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(Client_IsValid(client)) {
		int frags = GetClientFrags(client);
		int newfrags = frags + 1;
		SetEntProp(client, Prop_Data, "m_iFrags", newfrags);
	}
}

public OnMapZonesLoaded()
{
	// If map has start and end.
	if(Timer_GetMapzoneCount(ZtStart) == 0 || Timer_GetMapzoneCount(ZtEnd) == 0) {
		//SetFailState("MapZones start and end points not found! Disabling!");
		
	}
}



public Action SlayPlayer(Handle timer, any client)
{
	if(Client_IsValid(client) && Timer_IsEnabled()) {
		ForcePlayerSuicide(client);
		int frags = GetClientFrags(client);
		int newfrags = frags + 1;
		SetEntProp(client, Prop_Data, "m_iFrags", newfrags);
	}
}