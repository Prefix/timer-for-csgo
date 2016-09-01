#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

#include <timer>
#include <timer-logging>
#include <timer-stocks>
#include <timer-config_loader>
#include <timer-mapzones>

#define MAX_WEAPON_NAME 80
#define NUM_WEAPONS 27

new g_Collision = -1;



public Plugin:myinfo =
{
	name        = "[TIMER] Weapons",
	author      = "Zipcore & Bara",
	description = "[TIMER] Weapons manager",
	version     = PL_VERSION,
	url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSS && GetEngineVersion() != Engine_CSGO)
	{
		Timer_LogError("Don't use this plugin for other games than CS:S or CS:GO.");
		SetFailState("Check timer error logs.");
		return;
	}
	
	AddCommandListener(Command_Drop, "drop");
	
	//RegConsoleCmd("sm_k", Command_Knife, "Give player a knife");
	//RegConsoleCmd("sm_scout", Command_Scout, "Give player a scout");
	//RegConsoleCmd("sm_usp", Command_Usp, "Give player a usp");
	//RegConsoleCmd("sm_glock", Command_Glock, "Give player a glock");
	
	AutoExecConfig(true, "timer-weapons");
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	LoadPhysics();
	LoadTimerSettings();
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
	
	if(g_Settings[BuyzoneEverywhere]) SetConVarInt(FindConVar("mp_buytime"), 9999);
}

public OnClientPutInServer(client) 
{
	if(!Timer_IsEnabled()) return;
	if(!Timer_IsEnabled()) return;
	if(g_Settings[BuyzoneEverywhere]) SDKHook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
}

public Hook_PostThinkPost(entity)
{
	if(!Timer_IsEnabled()) return;
	if(g_Settings[BuyzoneEverywhere]) SetEntProp(entity, Prop_Send, "m_bInBuyZone", 1);
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!Timer_IsEnabled()) return;
	if(!Timer_IsEnabled()) return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetClientTeam(client) > CS_TEAM_SPECTATOR && !IsFakeClient(client))
	{
		
		int knife 	= GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
		if(knife == -1)
		{
			if(g_Settings[GiveKnifeOnSpawn])
			{
				FakeClientCommand(client, "sm_k");
			}		
		}
		
		int primary 	= GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
		if(primary == -1)
		{
			if(g_Settings[GiveScoutOnSpawn])
			{
				FakeClientCommand(client, "sm_scout");
			}		
		}
		
		int secondary 	= GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
		if(secondary == -1)
		{
			if(g_Settings[GivePistolOnSpawn])
			{
				if(GetClientTeam(client) == CS_TEAM_CT)
				{
					FakeClientCommand(client, "sm_usp");
				}
				else if(GetClientTeam(client) == CS_TEAM_CT)
				{
					FakeClientCommand(client, "sm_glock");
				}
			}		
		}
		
		if(g_Settings[GiveScoutOnSpawn] || g_Settings[GivePistolOnSpawn])
		{
			//CreateTimer(0.1, Timer_RestockClientAmmo, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:Command_Drop(client, const String:command[], argc)
{
	if(!Timer_IsEnabled()) return Plugin_Continue;
	if(!Timer_IsEnabled()) return Plugin_Continue;
	if(g_Settings[AllowKnifeDrop])
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			new String:playerWeapon[32];
			GetClientWeapon(client, playerWeapon, sizeof(playerWeapon));

			if(StrEqual("weapon_knife", playerWeapon))
			{
				new weapon = Client_GetActiveWeapon(client);
				
				if(weapon > 0)
				{
					RemovePlayerItem(client, weapon);
					AcceptEntityInput(weapon, "kill");
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:CS_OnCSWeaponDrop(client, weaponIndex)
{
	if (IsValidEntity(weaponIndex) && IsValidEdict(weaponIndex) && Timer_IsEnabled())
	{
		SetEntData(weaponIndex, g_Collision, 1, 4, true);
		if(0 < client && IsClientInGame(client)) Weapon_SetOwner(weaponIndex, client);
	}
}

public Action:Command_Knife(client, args) 
{
	if(!Timer_IsEnabled()) return Plugin_Handled;
	if(!Timer_IsEnabled()) return Plugin_Handled;
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		//RemovePlayerKnife(client);
		Client_GiveWeapon(client, "weapon_knife", true);
		//CreateTimer(0.1, Timer_RestockClientAmmo, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}

public Action:Command_Scout(client, args) 
{
	if(!Timer_IsEnabled()) return Plugin_Handled;
	if(!Timer_IsEnabled()) return Plugin_Handled;
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		RemovePlayerPrimary(client);
		
		Client_GiveWeapon(client, "weapon_ssg08", true);
		
		//CreateTimer(0.1, Timer_RestockClientAmmo, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}

public Action:Command_Usp(client, args) 
{
	if(!Timer_IsEnabled()) return Plugin_Handled;
	if(!Timer_IsEnabled()) return Plugin_Handled;
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		RemovePlayerSecondary(client);
		
		//if(GetEngineVersion() == Engine_CSS)
		//Client_GiveWeapon(client, "weapon_usp", true);
		//else if(GetEngineVersion() == Engine_CSGO)
		//CSGO_GiveWeapon(client, "weapon_usp_silencer", true);
		Client_GiveWeapon(client, "weapon_hpk2000", true);
		
		//CreateTimer(0.1, Timer_RestockClientAmmo, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}

public Action:Command_Glock(client, args) 
{
	if(!Timer_IsEnabled()) return Plugin_Handled;
	if(!Timer_IsEnabled()) return Plugin_Handled;
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		RemovePlayerSecondary(client);
		
		Client_GiveWeapon(client, "weapon_glock", true);
		
		//CreateTimer(0.1, Timer_RestockClientAmmo, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}


stock RemovePlayerKnife(client)
{
	if(!Timer_IsEnabled()) return;
	if(!Timer_IsEnabled()) return;
	new iWeapon = -1;
	while((iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE)) != INVALID_ENT_REFERENCE)
	{
		RemovePlayerItem(client, iWeapon);
		AcceptEntityInput(iWeapon, "kill");
	}
}

stock RemovePlayerPrimary(client)
{
	if(!Timer_IsEnabled()) return;
	if(!Timer_IsEnabled()) return;
	new iWeapon = -1;
	while((iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY)) != INVALID_ENT_REFERENCE)
	{
		RemovePlayerItem(client, iWeapon);
		AcceptEntityInput(iWeapon, "kill");
	}
}

stock RemovePlayerSecondary(client)
{
	if(!Timer_IsEnabled()) return;
	if(!Timer_IsEnabled()) return;
	new iWeapon = -1;
	while((iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY)) != INVALID_ENT_REFERENCE)
	{
		RemovePlayerItem(client, iWeapon);
		AcceptEntityInput(iWeapon, "kill");
	}
}