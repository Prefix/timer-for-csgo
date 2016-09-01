#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <timer>
#include <timer-mysql>
#include <timer-stocks>
#include <timer-config_loader>
#include <timer-mapzones>

#define RECORD_ANY 0
#define RECORD_TOP 1
#define RECORD_WORLD 2

#define LATEST_LIMIT 100

enum Record
{
	String:RecordMap[64],
	RecordTrack,
	RecordStyle,
	String:RecordAuth[32],
	String:RecordName[64],
	Float:RecordTime,
	RecordRank,
	String:RecordDate[32],
}

new Handle:g_hSQL = INVALID_HANDLE;

new g_latestRecords[3][LATEST_LIMIT][Record];
new g_RecordCount[3];



public Plugin:myinfo = 
{
	name = "[TIMER] Worldrecord - Latest WRs",
	author = "Zipcore, DR. API Improvements",
	description = "[Timer] Show latest records done.",
	version = PL_VERSION,
	url = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
	LoadTranslations("drapi/drapi_timer-worldrecord_latest.phrases");
	RegConsoleCmd("sm_latest", Cmd_LatestChoose);
	RegConsoleCmd("sm_rr", Cmd_LatestChoose);
	RegConsoleCmd("sm_recent", Cmd_LatestChoose);
	
	if (g_hSQL == INVALID_HANDLE)
	{
		ConnectSQL();
	}
	
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
	if (g_hSQL == INVALID_HANDLE)
	{
		ConnectSQL();
	}
	else LoadLatestRecords();
	
	LoadPhysics();
	LoadTimerSettings();
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
	else LoadLatestRecords();
}

public Action:Timer_SQLReconnect(Handle:timer, any:data)
{
	if(!Timer_IsEnabled()) return Plugin_Continue;
	ConnectSQL();
	return Plugin_Stop;
}

public OnTimerRecord(client, track, mode, Float:time, Float:lasttime, currentrank, newrank)
{
	if(!Timer_IsEnabled()) return;
	if(lasttime == 0.0 || time < lasttime) LoadLatestRecords();
}

LoadLatestRecords()
{
	if(!Timer_IsEnabled()) return;
	decl String:sQuery[1024];
	
	FormatEx(sQuery, sizeof(sQuery), "SELECT `map`, `track`, `style`, `auth`, `name`, `time`, `rank`, `date` FROM `round` ORDER BY `date` DESC LIMIT %d", LATEST_LIMIT);
	SQL_TQuery(g_hSQL, LoadLatestRecordsCallback, sQuery, RECORD_ANY, DBPrio_Low);
	
	FormatEx(sQuery, sizeof(sQuery), "SELECT `map`, `track`, `style`, `auth`, `name`, `time`, `rank`, `date` FROM `round` WHERE `rank` <= 10 ORDER BY `date` DESC LIMIT %d", LATEST_LIMIT);
	SQL_TQuery(g_hSQL, LoadLatestRecordsCallback, sQuery, RECORD_TOP, DBPrio_Low);
	
	FormatEx(sQuery, sizeof(sQuery), "SELECT `map`, `track`, `style`, `auth`, `name`, `time`, `rank`, `date` FROM `round` WHERE `rank` = 1 ORDER BY `date` DESC LIMIT %d", LATEST_LIMIT);
	SQL_TQuery(g_hSQL, LoadLatestRecordsCallback, sQuery, RECORD_WORLD, DBPrio_Low);
}

public LoadLatestRecordsCallback(Handle:owner, Handle:hndl, const String:error[], any:recordtype)
{
	if(!Timer_IsEnabled()) return;
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("SQL Error on LoadMap: %s", error);
		return;
	}

	new recordCounter = 0;
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, g_latestRecords[recordtype][recordCounter][RecordMap], 64);
		g_latestRecords[recordtype][recordCounter][RecordTrack] = SQL_FetchInt(hndl, 1);
		g_latestRecords[recordtype][recordCounter][RecordStyle] = SQL_FetchInt(hndl, 2);
		SQL_FetchString(hndl, 3, g_latestRecords[recordtype][recordCounter][RecordAuth], 32);
		SQL_FetchString(hndl, 4, g_latestRecords[recordtype][recordCounter][RecordName], 64);
		g_latestRecords[recordtype][recordCounter][RecordTime] = SQL_FetchFloat(hndl, 5);
		g_latestRecords[recordtype][recordCounter][RecordRank] = SQL_FetchInt(hndl, 6);
		SQL_FetchString(hndl, 7, g_latestRecords[recordtype][recordCounter][RecordDate], 32);
		
		recordCounter++;
		if (recordCounter == LATEST_LIMIT)
		{
			break;
		}
	}
	
	g_RecordCount[recordtype] = recordCounter;
}

public Action:Cmd_LatestChoose(client, args)
{
	if(!Timer_IsEnabled()) return Plugin_Continue;
	if (client)
	{
		new Handle:menu = CreateMenu(Handle_LatestChoose);
			
		char title[256];
		Format(title, sizeof(title), "%T", "LatestMenuTitle", client);
		SetMenuTitle(menu, title);
		
		char anys[256];
		Format(anys, sizeof(anys), "%T", "LatestMenuTitle", client);		
		AddMenuItem(menu, "any", anys);
		
		char top[256];
		Format(top, sizeof(top), "%T", "LatestMenuTitle", client);
		AddMenuItem(menu, "top", top);
		
		char world[256];
		Format(world, sizeof(world), "%T", "LatestMenuTitle", client);
		AddMenuItem(menu, "world", world);
			
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}

	return Plugin_Handled;
}

public Handle_LatestChoose(Handle:menu, MenuAction:action, client, itemNum)
{
	if(!Timer_IsEnabled()) return;
	if (action == MenuAction_Select)
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		if(found)
		{
			if(StrEqual(info, "any"))
			{
				Menu_Latest(client, RECORD_ANY);
			}
			else if(StrEqual(info, "top"))
			{
				Menu_Latest(client, RECORD_TOP);
			}
			else if(StrEqual(info, "world"))
			{
				Menu_Latest(client, RECORD_WORLD);
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

Menu_Latest(client, type)
{
	if(!Timer_IsEnabled()) return;
	new Handle:menu = INVALID_HANDLE;
	
	if(type == RECORD_TOP)
	{
		menu = CreateMenu(Handle_LatestTop);
		char title[256];
		Format(title, sizeof(title), "%T", "Latest Top 10 Records", client);
		SetMenuTitle(menu, title);
	}
	else if(type == RECORD_WORLD)
	{
		menu = CreateMenu(Handle_LatestWorld);
		char title[256];
		Format(title, sizeof(title), "%T", "Latest World Records", client);
		SetMenuTitle(menu, title);
	}
	else if(type == RECORD_ANY)
	{
		menu = CreateMenu(Handle_Latest);
		char title[256];
		Format(title, sizeof(title), "%T", "Latest Records", client);
		SetMenuTitle(menu, title);
	}

	if(menu != INVALID_HANDLE)
	{
		for (new i = 0; i < g_RecordCount[type]; i++)
		{
			decl String:sTime[128];
			Timer_SecondsToTime(g_latestRecords[type][i][RecordTime], sTime, sizeof(sTime), 2);

			decl String:buffer[512];
			Format(buffer, sizeof(buffer), "[#%d] %s", i+1, sTime);
			
			if(g_latestRecords[type][i][RecordTrack] == TRACK_BONUS)
				Format(buffer, sizeof(buffer), "%s [B]", buffer);
			
			Format(buffer, sizeof(buffer), "%s - %s", buffer, g_latestRecords[type][i][RecordName]);
			
			decl String:sInfo[3];
			Format(sInfo, sizeof(sInfo), "%d", i);
			AddMenuItem(menu, sInfo, buffer);
		}
		
		if (g_RecordCount[type] == 0)
		{
			decl String:buffer[512];
			Format(buffer, sizeof(buffer), "%T", "No records available", client);
			AddMenuItem(menu, "", buffer, ITEMDRAW_DISABLED);
		}
		
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 20);
	}
}

public Handle_Latest(Handle:menu, MenuAction:action, client, itemNum)
{
	if(!Timer_IsEnabled()) return;
	if (action == MenuAction_Select)
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		new id = StringToInt(info);
		if(found)
		{
			new Handle:menu2 = CreateMenu(Handle_LatestChoose);
			
			char title[256];
			Format(title, sizeof(title), "%T", "Details", client);
			SetMenuTitle(menu2, title);
			
			new String:buffer[512];
			
			Format(buffer, sizeof(buffer), "%T", "Map", client, g_latestRecords[RECORD_ANY][id][RecordMap]);
			if(g_latestRecords[RECORD_ANY][id][RecordTrack] == TRACK_BONUS) Format(buffer, sizeof(buffer), "%s [Bonus]", buffer);
			AddMenuItem(menu2, "any", buffer);
			
			if(g_Settings[MultimodeEnable])
			{
				Format(buffer, sizeof(buffer), "%T", "Style", client, g_Physics[g_latestRecords[RECORD_ANY][id][RecordStyle]][StyleName]);
				AddMenuItem(menu2, "any", buffer);
			}
			
			Format(buffer, sizeof(buffer), "%T", "Name", client, g_latestRecords[RECORD_ANY][id][RecordName], g_latestRecords[RECORD_ANY][id][RecordAuth]);
			AddMenuItem(menu2, "any", buffer);
			
			decl String:sTime[128];
			Timer_SecondsToTime(g_latestRecords[RECORD_ANY][id][RecordTime], sTime, sizeof(sTime), 2);
			Format(buffer, sizeof(buffer), "%T", "Time", client, sTime, g_latestRecords[RECORD_ANY][id][RecordRank]);
			AddMenuItem(menu2, "any", buffer);
			
			Format(buffer, sizeof(buffer), "%T", "Date", client, g_latestRecords[RECORD_ANY][id][RecordDate]);
			AddMenuItem(menu2, "any", buffer);
			
			DisplayMenu(menu2, client, MENU_TIME_FOREVER);
		}
	}
}

public Handle_LatestTop(Handle:menu, MenuAction:action, client, itemNum)
{
	if(!Timer_IsEnabled()) return;
	if (action == MenuAction_Select)
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		new id = StringToInt(info);
		if(found)
		{
			new Handle:menu2 = CreateMenu(Handle_LatestChoose);
			
			char title[256];
			Format(title, sizeof(title), "%T", "Details", client);
			SetMenuTitle(menu2, title);
			
			new String:buffer[512];
			
			Format(buffer, sizeof(buffer), "%T", "Map", client, g_latestRecords[RECORD_TOP][id][RecordMap]);
			if(g_latestRecords[RECORD_TOP][id][RecordTrack] == TRACK_BONUS) Format(buffer, sizeof(buffer), "%s [Bonus]", buffer);
			AddMenuItem(menu2, "top", buffer);
			
			if(g_Settings[MultimodeEnable])
			{
				Format(buffer, sizeof(buffer), "%T", "Style", client, g_Physics[g_latestRecords[RECORD_TOP][id][RecordStyle]][StyleName]);
				AddMenuItem(menu2, "top", buffer);
			}
			
			Format(buffer, sizeof(buffer), "%T", "Name", client, g_latestRecords[RECORD_TOP][id][RecordName], g_latestRecords[RECORD_TOP][id][RecordAuth]);
			AddMenuItem(menu2, "top", buffer);
			
			decl String:sTime[128];
			Timer_SecondsToTime(g_latestRecords[RECORD_TOP][id][RecordTime], sTime, sizeof(sTime), 2);
			Format(buffer, sizeof(buffer), "%T", "Time", client, sTime, g_latestRecords[RECORD_TOP][id][RecordRank]);
			AddMenuItem(menu2, "top", buffer);
			
			Format(buffer, sizeof(buffer), "%T", "Date", client, g_latestRecords[RECORD_TOP][id][RecordDate]);
			AddMenuItem(menu2, "top", buffer);
			
			DisplayMenu(menu2, client, MENU_TIME_FOREVER);
		}
	}
}

public Handle_LatestWorld(Handle:menu, MenuAction:action, client, itemNum)
{
	if(!Timer_IsEnabled()) return;
	if (action == MenuAction_Select)
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		new id = StringToInt(info);
		if(found)
		{
			new Handle:menu2 = CreateMenu(Handle_LatestChoose);
			
			char title[256];
			Format(title, sizeof(title), "%T", "Details", client);
			SetMenuTitle(menu2, title);
			
			new String:buffer[512];
			
			Format(buffer, sizeof(buffer), "%T", "Map", client, g_latestRecords[RECORD_WORLD][id][RecordMap]);
			if(g_latestRecords[RECORD_WORLD][id][RecordTrack] == TRACK_BONUS) Format(buffer, sizeof(buffer), "%s [Bonus]", buffer);
			AddMenuItem(menu2, "world", buffer);
			
			if(g_Settings[MultimodeEnable])
			{
				Format(buffer, sizeof(buffer), "%T", "Style", client, g_Physics[g_latestRecords[RECORD_WORLD][id][RecordStyle]][StyleName]);
				AddMenuItem(menu2, "world", buffer);
			}
			
			Format(buffer, sizeof(buffer), "%T", "Name", client, g_latestRecords[RECORD_WORLD][id][RecordName], g_latestRecords[RECORD_WORLD][id][RecordAuth]);
			AddMenuItem(menu2, "world", buffer);
			
			decl String:sTime[128];
			Timer_SecondsToTime(g_latestRecords[RECORD_ANY][id][RecordTime], sTime, sizeof(sTime), 2);
			Format(buffer, sizeof(buffer), "%T", "Time", client, sTime, g_latestRecords[RECORD_WORLD][id][RecordRank]);
			AddMenuItem(menu2, "world", buffer);
			
			Format(buffer, sizeof(buffer), "%T", "Date", client, g_latestRecords[RECORD_WORLD][id][RecordDate]);
			AddMenuItem(menu2, "world", buffer);
			
			DisplayMenu(menu2, client, MENU_TIME_FOREVER);
		}
	}
}