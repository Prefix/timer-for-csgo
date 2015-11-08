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

#define MAX_WEAPON_NAME 80
#define NUM_WEAPONS 27

new g_WeaponParent = -1;
new g_Collision = -1;
new g_iAccount = -1;

new bool:g_MapEntity[2048] = {false, ...};

new const String:g_sWeaponNames[NUM_WEAPONS][32] = {

	"weapon_ak47", "weapon_m4a1", "weapon_sg552",
	"weapon_aug", "weapon_galil", "weapon_famas",
	"weapon_scout", "weapon_m249", "weapon_mp5navy",
	"weapon_p90", "weapon_ump45", "weapon_mac10",
	"weapon_tmp", "weapon_m3", "weapon_xm1014",
	"weapon_glock", "weapon_usp", "weapon_p228",
	"weapon_deagle", "weapon_elite", "weapon_fiveseven",
	"weapon_awp", "weapon_g3sg1", "weapon_sg550",
	"weapon_hpk2000", "weapon_ssg08", "weapon_usp_silencer"
};

new const g_AmmoData[NUM_WEAPONS][2] = {

	{2, 90}, {3, 90}, {3, 90},
	{2, 90}, {3, 90}, {3, 90},
	{2, 90}, {4, 200}, {6, 120},
	{10, 100}, {8, 100}, {8, 100},
	{6, 120}, {7, 32}, {7, 32},
	{6, 120}, {8, 100}, {9, 52},
	{1, 35}, {6, 120}, {10, 100},
	{5, 30}, {2, 90}, {3, 90},
	{12, 24}, {2, 90}, {8, 100}
};

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
	
	RegisterHacks();
	AddCommandListener(Command_Drop, "drop");
	
	RegConsoleCmd("sm_k", Command_Knife, "Give player a knife");
	RegConsoleCmd("sm_scout", Command_Scout, "Give player a scout");
	RegConsoleCmd("sm_usp", Command_Usp, "Give player a usp");
	RegConsoleCmd("sm_glock", Command_Glock, "Give player a glock");
	
	AutoExecConfig(true, "timer-weapons");
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	LoadPhysics();
	LoadTimerSettings();
}

public OnClientPostAdminCheck(client)
{
    SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
	{
		SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	}
}

public Action:OnWeaponCanUse(client, weapon)
{
	if(!g_Settings[AllowWeapons])
	{
		AcceptEntityInput(weapon,"kill");
		return Plugin_Handled;
	}
	
	decl String:sWeapon[MAX_WEAPON_NAME];
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));

	if(StrEqual(sWeapon, "weapon_smokegrenade", false))
	{
		if(IsValidEntity(weapon)) AcceptEntityInput(weapon,"kill");
		return Plugin_Handled;
	}
	if(StrEqual(sWeapon, "weapon_flashbang", false))
	{
		if(IsValidEntity(weapon)) AcceptEntityInput(weapon,"kill");
		return Plugin_Handled;
	}
	if(StrEqual(sWeapon, "weapon_hegrenade", false))
	{
		//if(IsValidEntity(weapon)) AcceptEntityInput(weapon,"kill");
		//return Plugin_Handled;
	}
	
	CreateTimer(0.1, Timer_RestockClientAmmo, client, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}  

public Action:Timer_RestockClientAmmo(Handle:timer, any:client)
{
	if(!IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Stop;
	
	new weaponIndex, dataIndex, ammoOffset;
	decl String:sClassName[32];
	for (new i = CS_SLOT_PRIMARY; i <= CS_SLOT_SECONDARY; i++) 
	{
		if (((weaponIndex = GetPlayerWeaponSlot(client, i)) != -1) && 
		GetEdictClassname(weaponIndex, sClassName, 32) &&
		((dataIndex = GetAmmoDataIndex(sClassName)) != -1) &&
		((ammoOffset = FindDataMapOffs(client, "m_iAmmo")+(g_AmmoData[dataIndex][0]*4)) != -1)) 
		{
			if(GetEngineVersion() == Engine_CSS)
				SetEntData(client, ammoOffset, 999);
			else if(GetEngineVersion() == Engine_CSGO)
				CSGO_SetWeaponAmmo(weaponIndex, 10, 999);
		}
	}
	
	return Plugin_Stop;
}

GetAmmoDataIndex(const String:weapon[]) {

	for (new i = 0; i < NUM_WEAPONS; i++)
		if (StrEqual(weapon, g_sWeaponNames[i]))
			return i;
	return -1;
}

RegisterHacks()
{
	g_WeaponParent = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
	g_Collision = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
}

public OnMapStart()
{
	ValidateMapWeapons();
	
	if(g_Settings[RemoveWeapons]) CreateTimer(3.0, Timer_CleanUp, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	LoadPhysics();
	LoadTimerSettings();
	
	if(g_Settings[BuyzoneEverywhere]) SetConVarInt(FindConVar("mp_buytime"), 9999);
}

public OnClientPutInServer(client) 
{
	if(g_Settings[BuyzoneEverywhere]) SDKHook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
}

public Hook_PostThinkPost(entity)
{
	if(g_Settings[BuyzoneEverywhere]) SetEntProp(entity, Prop_Send, "m_bInBuyZone", 1);
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
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
			CreateTimer(0.1, Timer_RestockClientAmmo, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:Command_Drop(client, const String:command[], argc)
{
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
	if (IsValidEntity(weaponIndex) && IsValidEdict(weaponIndex))
	{
		SetEntData(weaponIndex, g_Collision, 1, 4, true);
		if(0 < client && IsClientInGame(client)) Weapon_SetOwner(weaponIndex, client);
	}
}

public Action:Command_Knife(client, args) 
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		RemovePlayerKnife(client);
		Client_GiveWeapon(client, "weapon_knife", true);
		CreateTimer(0.1, Timer_RestockClientAmmo, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}

public Action:Command_Scout(client, args) 
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		RemovePlayerPrimary(client);
		
		if(GetEngineVersion() == Engine_CSS)
			Client_GiveWeapon(client, "weapon_scout", true);
		else if(GetEngineVersion() == Engine_CSGO)
			CSGO_GiveWeapon(client, "weapon_ssg08", true);
		
		CreateTimer(0.1, Timer_RestockClientAmmo, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}

public Action:Command_Usp(client, args) 
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		RemovePlayerSecondary(client);
		
		if(GetEngineVersion() == Engine_CSS)
			Client_GiveWeapon(client, "weapon_usp", true);
		else if(GetEngineVersion() == Engine_CSGO)
			CSGO_GiveWeapon(client, "weapon_usp_silencer", true);
		
		CreateTimer(0.1, Timer_RestockClientAmmo, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}

public Action:Command_Glock(client, args) 
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		RemovePlayerSecondary(client);
		
		if(GetEngineVersion() == Engine_CSS)
			Client_GiveWeapon(client, "weapon_glock", true);
		else if (GetEngineVersion() == Engine_CSGO)
			CSGO_GiveWeapon(client, "weapon_glock", true);
		
		CreateTimer(0.1, Timer_RestockClientAmmo, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}

stock RemovePlayerWeapons(client)
{
	new iWeapon = -1;
	for(new i=CS_SLOT_PRIMARY;i<=CS_SLOT_C4;i++)
	{
		while((iWeapon = GetPlayerWeaponSlot(client, i)) != INVALID_ENT_REFERENCE)
		{
			RemovePlayerItem(client, iWeapon);
			AcceptEntityInput(iWeapon, "kill");
		}
	}
}

stock RemovePlayerKnife(client)
{
	new iWeapon = -1;
	while((iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE)) != INVALID_ENT_REFERENCE)
	{
		RemovePlayerItem(client, iWeapon);
		AcceptEntityInput(iWeapon, "kill");
	}
}

stock RemovePlayerPrimary(client)
{
	new iWeapon = -1;
	while((iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY)) != INVALID_ENT_REFERENCE)
	{
		RemovePlayerItem(client, iWeapon);
		AcceptEntityInput(iWeapon, "kill");
	}
}

stock RemovePlayerSecondary(client)
{
	new iWeapon = -1;
	while((iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY)) != INVALID_ENT_REFERENCE)
	{
		RemovePlayerItem(client, iWeapon);
		AcceptEntityInput(iWeapon, "kill");
	}
}

public Action:Timer_CleanUp(Handle:timer)
{
	new maxent = GetMaxEntities(), String:weapon[64];
	
	for (new i=1;i<MaxClients;i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i)) continue;

		SetEntData( i, g_iAccount, MAX_CASH );
	}
	
	for (new i=MaxClients;i<maxent;i++)
	{
		if (g_MapEntity[i] || !IsValidEdict(i) || !IsValidEntity(i)) continue;
		
		GetEdictClassname(i, weapon, sizeof(weapon));
		if (( StrContains(weapon, "weapon_") != -1 || StrContains(weapon, "item_") != -1 ) && GetEntDataEnt2(i, g_WeaponParent) == -1)
			AcceptEntityInput(i, "kill");
	}
	
	return Plugin_Continue;
}

stock ValidateMapWeapons()
{
	new maxent = GetMaxEntities();
	for (new i = MaxClients; i < maxent; i++)
	{
		g_MapEntity[i] = false;
		
		if (!g_Settings[KeepMapWeapons] || !IsValidEdict(i) || !IsValidEntity(i)) continue;
		
		g_MapEntity[i] = true;
	}
}

/*
 * Gets the primary clip count of a weapon.
 * 
 * @param weapon        Weapon Entity.
 * @return                Primary Clip count.
 */
stock CSGO_GetPrimaryAmmo(weapon)
{
	return GetEntProp(weapon, Prop_Data, "m_iClip1");
}
/*
 * Sets the primary ammo count of a weapon.
 * 
 * @param weapon        Weapon Entity.
 * @param value            Clip Count value.
 */
stock CSGO_SetPrimaryAmmo(weapon,ammo)
{
	SetEntProp(weapon, Prop_Data, "m_iClip1", ammo);
}
/*
 * Gets the secondary clip count of a weapon.
 * 
 * @param weapon        Weapon Entity.
 * @return                Primary Clip count.
 */
stock CSGO_GetSecondaryAmmo(weapon)
{
	return GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount");
}
/*
 * Sets the secondary ammo count of a weapon.
 * 
 * @param weapon        Weapon Entity.
 * @param value            Clip Count value.
 */
stock CSGO_SetSecondaryAmmo(weapon,ammo)
{
	SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo);
}
/*
 * Sets the primarty and secondary ammo count of a weapon.
 * 
 * @param weapon        Weapon Entity.
 * @param value            Primary ammo Count value.
 * @param value            Primary ammo Count value.
 */
stock CSGO_SetWeaponAmmo(weapon,primaryammo,secondaryammo)
{
	CSGO_SetPrimaryAmmo(weapon, primaryammo);
	CSGO_SetSecondaryAmmo(weapon, secondaryammo);
}
/*
 * Gets the primary and secondary clip count of a weapon.
 * 
 * @param weapon                     Weapon Entity.
 * @param primaryammo                Primary Clip count.
 * @param secondaryammo                Secondary Clip count.
 */
stock CSGO_GetWeaponAmmo(weapon,&primaryammo,&secondaryammo)
{
	primaryammo = CSGO_GetPrimaryAmmo(weapon);
	secondaryammo = CSGO_GetSecondaryAmmo(weapon);
}  

stock CSGO_SetActiveWeapon(client, weapon)
{
	SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", weapon);
	ChangeEdictState(client, FindDataMapOffs(client, "m_hActiveWeapon"));
}

stock CSGO_GiveWeapon(client, const String:sWeapon[32], bool:switchTo)
{
	new iItem = GivePlayerItem(client, sWeapon);
	EquipPlayerWeapon(client, iItem);
}
