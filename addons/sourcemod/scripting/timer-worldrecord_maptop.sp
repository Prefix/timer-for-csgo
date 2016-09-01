#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <timer>
#include <timer-mysql>
#include <timer-stocks>
#include <timer-config_loader>
#include <timer-mapzones>

#define MAPTOP_LIMIT 100



public Plugin:myinfo = 
{
	name = "[TIMER] Worldrecord - MapTop",
	author = "Zipcore, Credits: Das D, DR. API Improvements",
	description = "[Timer] Show other maps top records.",
	version = PL_VERSION,
	url = "forums.alliedmods.net/showthread.php?p=2074699"
};

new Handle:g_hSQL = INVALID_HANDLE;

new String:g_SelectedMap[MAXPLAYERS+1][64];

new String:sql_select[] = "SELECT name, time, jumps, map FROM round WHERE map = '%s' AND track = '%d' AND `style` = '%d' ORDER BY time ASC LIMIT %d;";

public OnPluginStart()
{
	LoadTranslations("drapi/drapi_timer-worldrecord_maptop.phrases");
	RegConsoleCmd("sm_mtop", Cmd_MapTop_Record, "Displays Top of a given map");
	RegConsoleCmd("sm_mbtop", Cmd_MapBonusTop_Record, "Displays BonusTop of a given map");

	LoadPhysics();
	LoadTimerSettings();
	
	if (g_hSQL == INVALID_HANDLE)
	{
		ConnectSQL();
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
	
	if (g_hSQL == INVALID_HANDLE)
	{
		ConnectSQL();
	}
}

public OnTimerSqlConnected(Handle:sql)
{
	if(!Timer_IsEnabled()) return;
	g_hSQL = sql;
	g_hSQL = INVALID_HANDLE;
	CreateTimer(0.1, Timer_SQLReconnect, _ , TIMER_FLAG_NO_MAPCHANGE);
}

public OnTimerSqlStop()
{
	if(!Timer_IsEnabled()) return;
	g_hSQL = INVALID_HANDLE;
	CreateTimer(0.1, Timer_SQLReconnect, _ , TIMER_FLAG_NO_MAPCHANGE);
}

ConnectSQL()
{
	if(!Timer_IsEnabled()) return;
	g_hSQL = Handle:Timer_SqlGetConnection();
	
	if (g_hSQL == INVALID_HANDLE)
		CreateTimer(0.1, Timer_SQLReconnect, _ , TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_SQLReconnect(Handle:timer, any:data)
{
	if(!Timer_IsEnabled()) return Plugin_Continue;
	ConnectSQL();
	return Plugin_Stop;
}

/* Map Top */

public Action:Cmd_MapTop_Record(client, args)
{
	if(!Timer_IsEnabled()) return Plugin_Continue;
	if(args < 1)
	{
		if(g_Settings[MultimodeEnable])
		{
			CPrintToChat(client, "%t", "Usage");
		}
		else 
		{
			CPrintToChat(client, "%t", "Usage2");
		}
		return Plugin_Handled;
	}
	else if(args == 1)
	{
		decl String:sMapName[64];
		GetCmdArg(1, sMapName, sizeof(sMapName));
		
		if(g_Settings[MultimodeEnable]) 
		{
			TopStylePanel(client, sMapName);
		}
		else SQL_TopPanel(client, sMapName, g_StyleDefault, TRACK_NORMAL);
	}
	else if(args == 2 && g_Settings[MultimodeEnable])
	{
		decl String:sMapName[64];
		GetCmdArg(1, sMapName, sizeof(sMapName));
		decl String:sStyle[64];
		GetCmdArg(2, sStyle, sizeof(sStyle));
		
		for(new i = 0; i < MAX_STYLES-1; i++) 
		{
			if(!g_Physics[i][StyleEnable])
				continue;
			if(g_Physics[i][StyleCategory] != MCategory_Ranked)
				continue;
			if(StrEqual(g_Physics[i][StyleQuickCommand], ""))
				continue;
			
			if(StrEqual(g_Physics[i][StyleQuickCommand], sStyle))
			{
				SQL_TopPanel(client, sMapName, i, TRACK_NORMAL);
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Handled;
}

TopStylePanel(client, String:sMapName[64])
{
	if(!Timer_IsEnabled()) return;
	if(0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(MenuHandler_TopStylePanel);

		char title[256];
		Format(title, sizeof(title), "%T", "StyleMenuTitle", client);
		SetMenuTitle(menu, title);
		
		SetMenuExitButton(menu, true);

		for(new i = 0; i < MAX_STYLES-1; i++) 
		{
			if(!g_Physics[i][StyleEnable])
				continue;
			if(g_Physics[i][StyleCategory] != MCategory_Ranked)
				continue;
			
			new String:buffer[8];
			IntToString(i, buffer, sizeof(buffer));
				
			AddMenuItem(menu, buffer, g_Physics[i][StyleName]);
		}	

		Format(g_SelectedMap[client], 64, sMapName);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public MenuHandler_TopStylePanel(Handle:menu, MenuAction:action, client, itemNum)
{
	if(!Timer_IsEnabled()) return;
	if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select) 
	{
		decl String:info[8];		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		SQL_TopPanel(client, g_SelectedMap[client], StringToInt(info), TRACK_NORMAL);
	}
}

/* Map Top Bonus */

public Action:Cmd_MapBonusTop_Record(client, args)
{
	if(!Timer_IsEnabled()) return Plugin_Continue;
	if(args < 1)
	{
		if(g_Settings[MultimodeEnable]) CPrintToChat(client, "%t", "Usage");
		else CPrintToChat(client, "%t", "Usage2");
		return Plugin_Handled;
	}
	else if(args == 1)
	{
		decl String:sMapName[64];
		GetCmdArg(1, sMapName, sizeof(sMapName));
		
		if(g_Settings[MultimodeEnable]) BonusTopStylePanel(client, sMapName);
		else SQL_TopPanel(client, sMapName, g_StyleDefault, TRACK_BONUS);
	}
	else if(args == 2 && g_Settings[MultimodeEnable])
	{
		decl String:sMapName[64];
		GetCmdArg(1, sMapName, sizeof(sMapName));
		decl String:sStyle[64];
		GetCmdArg(2, sStyle, sizeof(sStyle));
		
		for(new i = 0; i < MAX_STYLES-1; i++) 
		{
			if(!g_Physics[i][StyleEnable])
				continue;
			if(g_Physics[i][StyleCategory] != MCategory_Ranked)
				continue;
			if(StrEqual(g_Physics[i][StyleQuickCommand], ""))
				continue;
			
			if(StrEqual(g_Physics[i][StyleQuickCommand], sStyle))
			{
				SQL_TopPanel(client, sMapName, i, TRACK_BONUS);
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Handled;
}

BonusTopStylePanel(client, String:sMapName[64])
{
	if(!Timer_IsEnabled()) return;
	if(0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(MenuHandler_BonusTopStylePanel);

		char title[256];
		Format(title, sizeof(title), "%T", "StyleMenuTitle", client);
		SetMenuTitle(menu, title);
		
		SetMenuExitButton(menu, true);

		for(new i = 0; i < MAX_STYLES-1; i++) 
		{
			if(!g_Physics[i][StyleEnable])
				continue;
			if(g_Physics[i][StyleCategory] != MCategory_Ranked)
				continue;
			
			new String:buffer[8];
			IntToString(i, buffer, sizeof(buffer));
				
			AddMenuItem(menu, buffer, g_Physics[i][StyleName]);
		}	

		Format(g_SelectedMap[client], 64, sMapName);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public MenuHandler_BonusTopStylePanel(Handle:menu, MenuAction:action, client, itemNum)
{
	if(!Timer_IsEnabled()) return;
	if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select) 
	{
		decl String:info[8];		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		SQL_TopPanel(client, g_SelectedMap[client], StringToInt(info), TRACK_BONUS);
	}
}

public SQL_TopPanel(client, String:sMapName[64], style, track)
{
	if(!Timer_IsEnabled()) return;
	decl String:sQuery[255];
	
	Format(sQuery, sizeof(sQuery), sql_select, sMapName, track, style, MAPTOP_LIMIT);
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackString(pack, sMapName);
	WritePackCell(pack, TRACK_NORMAL);
	WritePackCell(pack, style);
	
	SQL_TQuery(g_hSQL, SQL_SelectTopCallback, sQuery, pack);
}

public SQL_SelectTopCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!Timer_IsEnabled()) return;
	if(hndl == INVALID_HANDLE)
		LogError("Error loading SQL_SelectTopCallback (%s)", error);
	
	new Handle:pack = data;
	ResetPack(pack);
	new client = ReadPackCell(pack);
	decl String:sMapName[64];
	ReadPackString(pack, sMapName, sizeof(sMapName));
	new track = ReadPackCell(pack);
	new style = ReadPackCell(pack);
	CloseHandle(pack);
	
	decl String:sStyle[64];
	Format(sStyle, sizeof(sStyle), "%s", g_Physics[style][StyleName]);
	decl String:sTopMap[64];
	Format(sTopMap, sizeof(sTopMap), "%T", "Map", client, sMapName);
	
	new Handle:menu = CreateMenu(MenuHandler_Empty);
	
	new jumps;
	decl String:sValue[64];
	decl String:sName[MAX_NAME_LENGTH];
	decl String:sVrTime[16];
	
	if(track == TRACK_BONUS)
	{
		char title[256];
		Format(title, sizeof(title), "%T", "Maptop", client, MAPTOP_LIMIT, sTopMap);
		SetMenuTitle(menu, title);
	}
	else if(track == TRACK_NORMAL)
	{
		char title[256];
		Format(title, sizeof(title), "%T", "Maptopbonus", client, MAPTOP_LIMIT, sTopMap);
		SetMenuTitle(menu, title);
	}
	
	if(SQL_HasResultSet(hndl))
	{
		new iCount = 1;
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, sName, MAX_NAME_LENGTH);
			jumps = SQL_FetchInt(hndl, 2);
			Timer_SecondsToTime(SQL_FetchFloat(hndl, 1), sVrTime, 16, 2);
			Format(sValue, 64, "#%i | %s - %s", iCount, sName, sVrTime, jumps);
			AddMenuItem(menu, sValue, sValue, ITEMDRAW_DISABLED);
			iCount++;
		}
		if(iCount == 1)
		{
			char title[256];
			Format(title, sizeof(title), "%T", "No record found", client);
			AddMenuItem(menu, "No record found", title, ITEMDRAW_DISABLED);
		}
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 30);
}

//Empty menu handler only to close open menu handle
public MenuHandler_Empty(Handle:menu, MenuAction:action, param1, param2)
{
	if(!Timer_IsEnabled()) return;
	if (action == MenuAction_Select)
	{

	}
	else if (action == MenuAction_Cancel)
	{

	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}