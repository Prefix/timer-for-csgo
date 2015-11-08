#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <timer>
#include <timer-teams>
#include <timer-config_loader>

#undef REQUIRE_PLUGIN
#include <timer-mapzones>

new bool:g_timerMapzones = false;
new bool:g_timerTeams = false;

public Plugin:myinfo =
{
	name        = "[TIMER] TeleMe",
	author      = "Zipcore, DR. API Improvements",
	description = "[Timer] Player 2 player teleporting",
	version     = PL_VERSION,
	url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
	LoadTranslations("drapi/drapi_timer-teleme.phrases");
	
	LoadPhysics();
	LoadTimerSettings();
	
	g_timerMapzones = LibraryExists("timer-mapzones");
	g_timerTeams = LibraryExists("timer-teams");
	
	RegConsoleCmd("sm_teleme", Command_TeleMe);
	RegConsoleCmd("sm_tpto", Command_TeleMe);
	RegConsoleCmd("sm_teleport", Command_TeleMe);
	RegConsoleCmd("sm_teleportto", Command_TeleMe);
	RegConsoleCmd("sm_teleportme", Command_TeleMe);
}

public OnLibraryAdded(const String:name[])
{
	if(StrEqual(name, "timer-mapzones"))
	{
		g_timerMapzones = true;
	}
	else if (StrEqual(name, "timer-teams"))
	{
		g_timerTeams = true;
	}
}

public OnLibraryRemoved(const String:name[])
{	
	if(StrEqual(name, "timer-mapzones"))
	{
		g_timerMapzones = false;
	}
	else if (StrEqual(name, "timer-teams"))
	{
		g_timerTeams = false;
	}
}

public OnMapStart()
{
	LoadPhysics();
	LoadTimerSettings();
}

public Action:Command_TeleMe(client, args)
{
	if(IsPlayerAlive(client) && g_Settings[PlayerTeleportEnable])
	{
	
		if(g_timerTeams)
		{
			if(Timer_GetChallengeStatus(client) == 1 || Timer_GetCoopStatus(client) == 1)
			{
				ConfirmAbortMenu(client, -1);
				return Plugin_Handled;
			}
		}
		
		if(!g_Settings[PlayerTeleportEnable]) 
		{
			CPrintToChat(client, "%t", "Teleport disabled by server");
			return Plugin_Handled;
		}
		
		new Handle:menu = CreateMenu(MenuHandlerTeleMe);
		char title[40];
		Format(title, sizeof(title), "%T", "TeleMenuTitle", client);
		SetMenuTitle(menu, title);
		//new bool:isadmin = Client_IsAdmin(client);
		
		new iCount = 0;
		
		//show rest
		for (new i = 1; i <= MaxClients; i++)
		{
			if(client == i || !IsClientInGame(i) || IsFakeClient(i) || !IsPlayerAlive(i))
			{
				continue;
			}
			
			decl String:name2[32];
			if(g_timerMapzones) 
				FormatEx(name2, sizeof(name2), "%N Stage: %d", i, Timer_GetClientLevel(i));
			else 
				FormatEx(name2, sizeof(name2), "%N", i);
				
			decl String:zone2[32];
			FormatEx(zone2,sizeof(zone2),"%d", i);
			AddMenuItem(menu, zone2, name2);
			iCount++;
		}
		
		if(iCount > 0)
		{
			SetMenuExitButton(menu, true);
			DisplayMenu(menu, client, 20);
		}
		else CPrintToChat(client, "%t", "No Target found");
	}
	else
	{
		CPrintToChat(client, "%t", "You have to be alive");
	}
	
	return Plugin_Handled;
}

public MenuHandlerTeleMe(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info), _, info2, sizeof(info2));
		new target = StringToInt(info);
		if(found)
		{
			if(IsClientInGame(client) && IsClientInGame(target))
			{
				if(IsPlayerAlive(client) && IsPlayerAlive(target))
				{
					new Float:origin[3], Float:angles[3];
					GetClientAbsOrigin(target, origin);
					GetClientAbsAngles(target, angles);
					
					//Do not reset his pretty timer if it can be paused
					if (g_Settings[PauseEnable])
					{
						FakeClientCommand(client, "sm_pause");
					}
					else
					{
						Timer_Reset(client);
					}		
					
					TeleportEntity(client, origin, angles, NULL_VECTOR);
				}
			}
		}
	}
}

ConfirmAbortMenu(client, track)
{
	if (0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(Handle_ConfirmAbortMenu);
		
		new mate;
		if(g_timerTeams) mate = Timer_GetClientTeammate(client);
		
		if(mate > 0)
		{
			if(Timer_GetChallengeStatus(client) == 1)
			{
				char title[256];
				Format(title, sizeof(title), "%T", "Are you sure to quit the Challenge", client);
				SetMenuTitle(menu, title);
			}
			else if(Timer_GetCoopStatus(client) == 1)
			{
				char title[256];
				Format(title, sizeof(title), "%T", "Are you sure to quit the Coop", client);
				SetMenuTitle(menu, title);
			}
		}else 
		{
			char title[256];
			Format(title, sizeof(title), "%T", "Are you sure to quit", client);
			SetMenuTitle(menu, title);
		}
		
		decl String:info[8];
		IntToString(track, info, sizeof(info));
		
		char yes[256];
		Format(yes, sizeof(yes), "%T", "Yes", client);
		AddMenuItem(menu, info, yes);
		
		char no[256];
		Format(no, sizeof(no), "%T", "No", client);
		AddMenuItem(menu, "no", no);
		
		DisplayMenu(menu, client, 5);
	}
}

public Handle_ConfirmAbortMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select )
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		
		if(found)
		{
			if(!StrEqual(info, "no", false))
			{
				if(StrEqual(info, "-1", false))
				{
					Timer_ClientStart(client);
					
				}
				else if(StrEqual(info, "0", false))
				{
					Timer_ClientRestart(client);
				}
				else
				{	
					new track = StringToInt(info);
					Timer_ClientBonusRestart(client, track);
				}
			}
		}
	}
}