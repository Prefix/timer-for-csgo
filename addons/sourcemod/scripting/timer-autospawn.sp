#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <timer>
#include <timer-config_loader>

new Handle:Spawn_Timer[MAXPLAYERS+1];
new Handle:Check_Timer[MAXPLAYERS+1];

float F_ZoneStart[100][3];

int ZonePVP;
int C_LastStyle[MAXPLAYERS+1];
new g_SpawnBlocked;

public Plugin:myinfo = 
{

	name = "[TIMER] Autospawn",
	author = "Zipcore, Credits: Das D, DR. API Improvements",
	version = PL_VERSION,
	description = "",
	url = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart() 
{
	LoadTranslations("drapi/drapi_timer-autospawn.phrases");
	LoadPhysics();
	LoadTimerSettings();
	
	HookEvent("player_team", Event_ChangeTeam, EventHookMode_Post);
	HookEventEx("round_start", Event_RoundStart); 
	
	
	RegConsoleCmd("joinclass", Command_JoinClass);
	RegConsoleCmd("sm_t", Command_T);
	RegConsoleCmd("sm_ct", Command_CT);
}

/***********************************************************/
/********************** MAP START **************************/
/***********************************************************/
public OnMapStart()
{
	LoadPhysics();
	LoadTimerSettings();	
	
	CreateTimer(1.0, Timer_Alive, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	
	ZonePVP = 0;
	
	for(int zonepvp = 0; zonepvp < 10; zonepvp++)
	{
		F_ZoneStart[zonepvp][0] = 0.0;
		F_ZoneStart[zonepvp][1] = 0.0;
		F_ZoneStart[zonepvp][2] = 0.0;
	}
	
	int ent = -1; 
	while((ent = FindEntityByClassname(ent, "trigger_teleport")) != -1) 
	{ 
		SDKHookEx(ent, SDKHook_EndTouch, Touch); 
		SDKHookEx(ent, SDKHook_StartTouch,	Touch); 
		SDKHookEx(ent, SDKHook_Touch, Touch); 
	}	
}

/***********************************************************/
/********************* ROUND START *************************/
/***********************************************************/
public Event_RoundStart(Handle event, const char[] name, bool dontBroadcast) 
{ 
	ZonePVP = 0;
	int ent = -1; 
	while((ent = FindEntityByClassname(ent, "trigger_teleport")) != -1) 
	{ 
		SDKHookEx(ent, SDKHook_EndTouch, Touch); 
		SDKHookEx(ent, SDKHook_StartTouch,	Touch); 
		SDKHookEx(ent, SDKHook_Touch, Touch); 
	} 
} 

/***********************************************************/
/***************** TOUCH ZONE TELEPORT *********************/
/***********************************************************/
public Action Touch(int entity, int other) 
{ 
	if(0 < other <= MaxClients && IsClientInGame(other)) 
	{ 
		int style = Timer_GetStyle(other);
		if(g_Physics[style][StylePvP])
		{
			return Plugin_Handled; 
		}
	} 
	return Plugin_Continue; 
} 

/***********************************************************/
/********************** COMMAND T **************************/
/***********************************************************/
public Action Command_T(int client, int args)
{
	CS_SwitchTeam(client, CS_TEAM_T);
	CS_RespawnPlayer(client);
	Timer_SetStyle(client, C_LastStyle[client]);
	
	int style = Timer_GetStyle(client);
	if(g_Physics[style][StylePvP])
	{
		int random = GetRandomInt(0, ZonePVP-1);
		if(F_ZoneStart[random][0] != 0.0 && F_ZoneStart[random][1] != 0.0 && F_ZoneStart[random][2] != 0.0)
		{
			TeleportEntity(client, F_ZoneStart[random], NULL_VECTOR, NULL_VECTOR);
		}
		GivePlayerItem(client, "weapon_ssg08");
		SetEntityRenderColor(client, 255, 0, 0, 255);
	}
}

/***********************************************************/
/********************** COMMAND CT *************************/
/***********************************************************/
public Action Command_CT(int client, int args)
{
	CS_SwitchTeam(client, CS_TEAM_CT);
	CS_RespawnPlayer(client);
	Timer_SetStyle(client, C_LastStyle[client]);
	
	int style = Timer_GetStyle(client);
	if(g_Physics[style][StylePvP])
	{
		int random = GetRandomInt(0, ZonePVP-1);
		if(F_ZoneStart[random][0] != 0.0 && F_ZoneStart[random][1] != 0.0 && F_ZoneStart[random][2] != 0.0)
		{
			TeleportEntity(client, F_ZoneStart[random], NULL_VECTOR, NULL_VECTOR);
		}
		GivePlayerItem(client, "weapon_ssg08");
		SetEntityRenderColor(client, 0, 0, 255, 255);
	}
}


/***********************************************************/
/********************** TIMER ALIVE ************************/
/***********************************************************/
public Action Timer_Alive(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && (GetClientTeam(i) > 1))
		{
			C_LastStyle[i] = Timer_GetStyle(i);
			if(!IsPlayerAlive(i) && g_Settings[RestartEnable])
			{
				CS_RespawnPlayer(i);
				Timer_SetStyle(i, C_LastStyle[i]);
				
				int style = Timer_GetStyle(i);
				if(g_Physics[style][StylePvP])
				{
					int random = GetRandomInt(0, ZonePVP-1);
					if(F_ZoneStart[random][0] != 0.0 && F_ZoneStart[random][1] != 0.0 && F_ZoneStart[random][2] != 0.0)
					{
						TeleportEntity(i, F_ZoneStart[random], NULL_VECTOR, NULL_VECTOR);
					}
					GivePlayerItem(i, "weapon_ssg08");
					
					if(GetClientTeam(i) == CS_TEAM_CT)
					{
						SetEntityRenderColor(i, 0, 0, 255, 255);
					}
					else if(GetClientTeam(i) == CS_TEAM_T)
					{
						SetEntityRenderColor(i, 255, 0, 0, 255);
					}
				}
			}
		}
	}
}

/***********************************************************/
/**************** ON CLIENT CHANGE STYLE *******************/
/***********************************************************/
public int OnClientChangeStyle(int client, int oldstyle, int newstyle, bool isnewstyle)
{
	if(newstyle == 19 && C_LastStyle[client] != 19)
	{
		if(isnewstyle)
		{
			int random = GetRandomInt(0, ZonePVP-1);
			if(F_ZoneStart[random][0] != 0.0 && F_ZoneStart[random][1] != 0.0 && F_ZoneStart[random][2] != 0.0)
			{
				TeleportEntity(client, F_ZoneStart[random], NULL_VECTOR, NULL_VECTOR);
			}
			GivePlayerItem(client, "weapon_ssg08");	
			BuildMenuTeam(client);
			CPrintToChatAll("%t", "Style PVP", client);
			
			if(GetClientTeam(client) == CS_TEAM_CT)
			{
				SetEntityRenderColor(client, 0, 0, 255, 255);
			}
			else if(GetClientTeam(client) == CS_TEAM_T)
			{
				SetEntityRenderColor(client, 255, 0, 0, 255);
			}
		}
	}
	else
	{
		if(isnewstyle)
		{
			SetEntityRenderColor(client, 255, 255, 255, 255);
		}
	}
}

/***********************************************************/
/*********************** MENU TEAMS ************************/
/***********************************************************/
void BuildMenuTeam(int client)
{
	char title[256], ct[256], t[256];
	Menu menu = CreateMenu(MenuTeamAction);
	
	Format(ct, sizeof(ct), "%T", "Menu_CT_MENU_TITLE", client);
	AddMenuItem(menu, "M_CT", ct);
	
	Format(t, sizeof(t), "%T", "Menu_T_MENU_TITLE", client);
	AddMenuItem(menu, "M_T", t);
	
	Format(title, sizeof(title), "%T", "Menu_TITLE", client);
	menu.SetTitle(title);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/****************** MENU TEAMS ACTIONS *********************/
/***********************************************************/
public int MenuTeamAction(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);	
		}
		case MenuAction_Select:
		{
			char menu1[56];
			menu.GetItem(param2, menu1, sizeof(menu1));
			
			if(StrEqual(menu1, "M_CT"))
			{
				Command_CT(param1, -1);
			}
			else if(StrEqual(menu1, "M_T"))
			{
				Command_T(param1, -1);
			}
		}
	}
}
/***********************************************************/
/****************** ON MAP ZONE LOADED *********************/
/***********************************************************/
public int OnMapZoneLoaded(int type, int levelid, float point1_x, float point1_y, float point1_z, float point2_x, float point2_y, float point2_z)
{
	if(type == 17)
	{
		F_ZoneStart[ZonePVP][0] = (point1_x + point2_x) / 2;
		F_ZoneStart[ZonePVP][1] = (point1_y + point2_y) / 2;
		F_ZoneStart[ZonePVP][2] = point2_z + 10.0;	
		ZonePVP++;
	}
}

public Action:Event_ChangeTeam(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client != 0)
	{
		Check_Timer[client] = CreateTimer( 1.0, TeamAlive_Check, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:TeamAlive_Check(Handle:timer, any:client)
{
	if(IsClientInGame(client) && !IsPlayerAlive(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3))
	{
		Check_Timer[client] = INVALID_HANDLE;
		g_SpawnBlocked = 0;
		Spawn_Timer[client] = CreateTimer( 1.0, Do_Spawn, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		Check_Timer[client] = INVALID_HANDLE;
		g_SpawnBlocked = 0;
	}
}

public Action:Do_Spawn(Handle:timer, any:client)
{
	if(client != 0 && IsClientInGame(client) && !IsPlayerAlive(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3))
	{
		g_SpawnBlocked = 1;
		CS_RespawnPlayer(client);
		Spawn_Timer[client] = INVALID_HANDLE;
	}
	else
	{
		Spawn_Timer[client] = INVALID_HANDLE;
	}
}

public Action:Command_JoinClass(client, args)
{
	if(g_SpawnBlocked == 1)
	{
		FakeClientCommandEx(client, "spec_mode");
		return Plugin_Handled;
	}
	else
	{
		return Plugin_Continue;
	}
}

public OnClientDisconnect(client)
{
	if(Spawn_Timer[client] != INVALID_HANDLE)
	{
		CloseHandle(Spawn_Timer[client]);
		Spawn_Timer[client] = INVALID_HANDLE;
	}
	if(Check_Timer[client] != INVALID_HANDLE)
	{
		CloseHandle(Check_Timer[client]);
		Check_Timer[client] = INVALID_HANDLE;
	}
	
	C_LastStyle[client] = 0;
}