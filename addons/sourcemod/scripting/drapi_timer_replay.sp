/*   <DR.API TIMER REPLAY> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                  <DR.API TIMER REPLAY> is licensed under a                */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//****************************DR.API TIMER REPLAY****************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[TIMER REPLAY] -"
#define MAX_BOTS						4
#define MAX_WAYS						10000

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <autoexec>
#include <timer>
#include <timer-config_loader>
#include <timer-mysql>
#include <timer-stocks>
#include <timer-physics>
#include <timer-mapzones>
#include <botmimic>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_timer_replay_dev;
Handle cvar_timer_os;
Handle cvar_timer_wr_holder_name;

Handle g_hSQL 									= INVALID_HANDLE;

//Bool
bool B_active_timer_replay_dev					= false;

bool B_timer_wr_holder_name					= false;

bool B_IsJump[MAXPLAYERS + 1];
bool B_IsWR[MAXPLAYERS + 1];

//Strings
char Sql_UpdateReplayPath[] 					= "UPDATE round SET replaypath = '%s' WHERE auth LIKE \"%%%s%%\" AND map = '%s' AND style = '%d' AND track = '0' AND rank = '1'";
char Sql_SelectWrReplay[] 						= "SELECT replaypath, style, time, name, jumps, avgspeed, maxspeed FROM round WHERE map = '%s' AND style = '%d' AND track = '0' ORDER BY time ASC LIMIT %d";

char S_FileReplay[MAX_STYLES][PLATFORM_MAX_PATH];
char S_FileReplayTime[MAX_STYLES][16];
char S_FileReplayName[MAX_STYLES][64];
char S_FileReplayJump[MAX_STYLES][16];
char S_FileReplayAvgspeed[MAX_STYLES][16];
char S_FileReplayMaxspeed[MAX_STYLES][16];

//Floats
float F_Timer[MAXPLAYERS + 1];


//Customs
int C_timer_os;
int C_FileReplayStyle;
int C_StyleTarget[MAXPLAYERS + 1];
int C_BotStyle[MAXPLAYERS + 1];



//Informations plugin
public Plugin myinfo =
{
	name = "[TIMER] DR.API TIMER REPLAY",
	author = "Dr. Api",
	description = "DR.API TIMER REPLAY by Dr. Api",
	version = PL_VERSION,
	url = "http://zombie4ever.eu"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	LoadTranslations("drapi/drapi_timer_replay.phrases");
	AutoExecConfig_SetFile("drapi_timer_replay", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_timer_replay_version", PL_VERSION, "Version", CVARS);
	
	cvar_active_timer_replay_dev			= AutoExecConfig_CreateConVar("drapi_active_timer_replay_dev", 			"0", 					"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	cvar_timer_os							= AutoExecConfig_CreateConVar("drapi_timer_os", 						"0", 					"OS System, 0 = linux, 1 = windows", 	DEFAULT_FLAGS);
	cvar_timer_wr_holder_name				= AutoExecConfig_CreateConVar("drapi_timer_wr_holder_name", 			"0", 					"Enable/Disable WR Holder name", 		DEFAULT_FLAGS);
	
	HookEventsCvars();
	
	AutoExecConfig_ExecuteFile();

}

/***********************************************************/
/************************ PLUGIN END ***********************/
/***********************************************************/
public void OnPluginEnd()
{
	int i = 1;
	while(i <= MaxClients)
	{
		if(IsClientInGame(i))
		{
			if(BotMimic_IsPlayerRecording(i))
			{
				BotMimic_StopRecording(i, false);
			}
		}
		i++;
	}
}

/***********************************************************/
/******************** ON TERMINATE ROUND *******************/
/***********************************************************/
public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason) 
{
   return Plugin_Handled;
}  

/***********************************************************/
/**************** WHEN CLIENT PUT IN SERVER ****************/
/***********************************************************/
public void OnClientPutInServer(int client)
{
	if(IsFakeClient(client))
	{	
		Handle dataPackHandle;
		CreateDataTimer(2.0, TimerData_OnBotJoin, dataPackHandle);
		WritePackCell(dataPackHandle, GetClientUserId(client));
		WritePackString(dataPackHandle, S_FileReplay[C_FileReplayStyle]);
		
		C_BotStyle[client] = C_FileReplayStyle;
		
		SetClientName(client, g_Physics[C_FileReplayStyle][StyleName]);
		CS_SetClientClanTag(client, "WR Replay");
		
		if(B_active_timer_replay_dev)
		{
			LogMessage("%N: %s", client, S_FileReplay[C_FileReplayStyle]);
		}
	}
	else
	{
		if(IsClientInGame(client) && BotMimic_IsPlayerRecording(client))
		{
			BotMimic_StopRecording(client, false);
		}
	}
		
}

/***********************************************************/
/***************** TIMER DATA ON BOT JOIN ******************/
/***********************************************************/
public Action TimerData_OnBotJoin(Handle timer, Handle dataPackHandle)
{
	ResetPack(dataPackHandle);
	int client 		= GetClientOfUserId(ReadPackCell(dataPackHandle));
	char S_file[PLATFORM_MAX_PATH];
	ReadPackString(dataPackHandle, S_file, PLATFORM_MAX_PATH);
	
	if(client > 0 && IsClientInGame(client) && !IsPlayerAlive(client))
	{
		CS_SwitchTeam(client, CS_TEAM_T);
		CS_SwitchTeam(client, CS_TEAM_CT);
		CS_RespawnPlayer(client);
	}
	
	if(FileExists(S_file))
	{
		BotMimic_PlayRecordFromFile(client, S_file);
	}
}

/***********************************************************/
/***************** WHEN CLIENT DISCONNECT ******************/
/***********************************************************/
public void OnClientDisconnect(int client)
{
	if(IsClientInGame(client))
	{
		if(BotMimic_IsPlayerRecording(client))
		{
			BotMimic_StopRecording(client, false);
		}
	}
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEventsCvars()
{
	HookConVarChange(cvar_active_timer_replay_dev, 				Event_CvarChange);
	
	HookConVarChange(cvar_timer_os, 							Event_CvarChange);
	HookConVarChange(cvar_timer_wr_holder_name, 				Event_CvarChange);
}

/***********************************************************/
/******************** WHEN CVARS CHANGE ********************/
/***********************************************************/
public void Event_CvarChange(Handle cvar, const char[] oldValue, const char[] newValue)
{
	UpdateState();
}

/***********************************************************/
/*********************** UPDATE STATE **********************/
/***********************************************************/
void UpdateState()
{
	B_active_timer_replay_dev 					= GetConVarBool(cvar_active_timer_replay_dev);
	
	C_timer_os 									= GetConVarInt(cvar_timer_os);
	B_timer_wr_holder_name 						= GetConVarBool(cvar_timer_wr_holder_name);
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	LoadPhysics();
	
	ServerCommand("bot_knives_only");
	SetConVarInt(FindConVar("bot_join_after_player"), 0);
	SetConVarString(FindConVar("bot_quota_mode"), "normal");
	
	//SetConVarInt(FindConVar("sm_reserved_slots"), 4);
	//SetConVarInt(FindConVar("sm_hide_slots"), 1);
	//SetConVarInt(FindConVar("sm_reserve_type"), 2);
	//SetConVarInt(FindConVar("sm_reserve_maxadmins"), 0);

	char S_pathsm[PLATFORM_MAX_PATH], S_pathsmbackup[PLATFORM_MAX_PATH], S_pathsmbackupmap[PLATFORM_MAX_PATH], S_mapname[64];
	
	GetCurrentMap(S_mapname, sizeof(S_mapname));
	
	if(C_timer_os == 0)
	{
		BuildPath(Path_SM, S_pathsm, sizeof(S_pathsm), "data/botmimic/bhop/wr/%s", S_mapname);
	}
	else if(C_timer_os == 1)
	{
		BuildPath(Path_SM, S_pathsm, sizeof(S_pathsm), "data\\botmimic\\bhop\\wr\\%s", S_mapname);
	}
	
	if(!DirExists(S_pathsm))
	{
		CreateDirectory(S_pathsm, 511);
	}
	
	if(C_timer_os == 0)
	{
		BuildPath(Path_SM, S_pathsmbackup, sizeof(S_pathsmbackup), "data/botmimic/bhop/wr/backup");
	}
	else if(C_timer_os == 1)
	{
		BuildPath(Path_SM, S_pathsmbackup, sizeof(S_pathsmbackup), "data\\botmimic\\bhop\\wr\\backup");
	}
	if(!DirExists(S_pathsmbackup))
	{
		CreateDirectory(S_pathsmbackup, 511);
	}
	
	if(C_timer_os == 0)
	{
		BuildPath(Path_SM, S_pathsmbackupmap, sizeof(S_pathsmbackupmap), "data/botmimic/bhop/wr/backup/%s", S_mapname);
	}
	else if(C_timer_os == 1)
	{
		BuildPath(Path_SM, S_pathsmbackupmap, sizeof(S_pathsmbackupmap), "data\\botmimic\\bhop\\wr\\backup\\%s", S_mapname);
	}
	if(!DirExists(S_pathsmbackupmap))
	{
		CreateDirectory(S_pathsmbackupmap, 511);
	}
		
	if (g_hSQL == INVALID_HANDLE)
	{
		ConnectSQL();
	}
	
	CreateTimer(0.1, Timer_HUDTimer_CSGO, 	_, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	CreateTimer(10.0, Timer_ReplayWR, _, TIMER_FLAG_NO_MAPCHANGE);
	
	UpdateState();
}

/***********************************************************/
/**************** WHEN MAP START REPLAY WR *****************/
/***********************************************************/
public Action Timer_ReplayWR(Handle timer)
{
	for(int i = 0; i < MAX_STYLES-1; i++)
	{
		if(g_Physics[i][StyleReplay])
		{
			ReplayWR(i);
		}
	}
}


/***********************************************************/
/********************** WHEN MAP END ***********************/
/***********************************************************/
public void OnMapEnd()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(BotMimic_IsPlayerRecording(i))
			{
				BotMimic_StopRecording(i, false);
			}
		}
	}
}
/***********************************************************/
/***************** ON TIMER SQL CONNECTED ******************/
/***********************************************************/
public int OnTimerSqlConnected(Handle sql)
{
	g_hSQL = sql;
	g_hSQL = INVALID_HANDLE;
	CreateTimer(0.1, Timer_SQLReconnect, _ , TIMER_FLAG_NO_MAPCHANGE);
}

/***********************************************************/
/******************** ON TIMER SQL STOP ********************/
/***********************************************************/
public int OnTimerSqlStop()
{
	g_hSQL = INVALID_HANDLE;
	CreateTimer(0.1, Timer_SQLReconnect, _ , TIMER_FLAG_NO_MAPCHANGE);
}

/***********************************************************/
/*********************** SQL CONNECT ***********************/
/***********************************************************/
void ConnectSQL()
{
	g_hSQL = view_as<Handle>(Timer_SqlGetConnection());
	
	if (g_hSQL == INVALID_HANDLE)
	{
		CreateTimer(0.1, Timer_SQLReconnect, _ , TIMER_FLAG_NO_MAPCHANGE);
	}
}

/***********************************************************/
/****************** TIMER SQL RECONNECTED ******************/
/***********************************************************/
public Action Timer_SQLReconnect(Handle timer, any data)
{
	ConnectSQL();
	return Plugin_Stop;
}

/***********************************************************/
/********************** TIMER STARTED **********************/
/***********************************************************/
public int OnTimerStarted(int client)
{
	if(IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client) && !BotMimic_IsPlayerMimicing(client))
	{
	
		if(BotMimic_IsPlayerRecording(client))
		{
			BotMimic_StopRecording(client, false);
		}
			
		int style = Timer_GetStyle(client);
		
		
		if(g_Physics[style][StyleReplay] && Timer_GetTrack(client) == 0)
		{
			char S_name[MAX_RECORD_NAME_LENGTH];
			Format(S_name, MAX_RECORD_NAME_LENGTH, "%N_%d", client, GetTime());

			B_IsWR[client] = false;
			if(C_timer_os == 0)
			{
				BotMimic_StartRecording(client, S_name, "bhop/wr");
			}
			else if(C_timer_os == 1)
			{
				BotMimic_StartRecording(client, S_name, "bhop\\wr");
			}
		}
		
		if(B_active_timer_replay_dev)
		{
			PrintToChat(client, "OnTimerStarted: %i", Timer_GetStyle(client));
		}
	}
}

/***********************************************************/
/******************* TIMER WORLD RECORD ********************/
/***********************************************************/
public int OnTimerWorldRecord(int client, int track, int style, float time, float lasttime, int currentrank, int newrank)
{
	if(BotMimic_IsPlayerRecording(client))
	{
		//char Query[2048], S_mapname[64];
		
		//GetCurrentMap(S_mapname, 64);
		//Format(Query, sizeof(Query), Sql_SelectWrReplay, S_mapname, style, 1);
		//SQL_TQuery(g_hSQL, Sql_BackupWrReplayCallback, Query, _, DBPrio_High);
	
		Handle dataPackHandle;
		CreateDataTimer(0.5, TimerData_OnTimerWorldRecord, dataPackHandle);
		WritePackCell(dataPackHandle, GetClientUserId(client));
		WritePackCell(dataPackHandle, Timer_GetStyle(client));
		
		if(B_active_timer_replay_dev)
		{
			PrintToChat(client, "OnTimerWorldRecord");
		}
	}
}

/***********************************************************/
/************ TIMER DATA ON POST WEAPON EQUIP **************/
/***********************************************************/
public Action TimerData_OnTimerWorldRecord(Handle timer, Handle dataPackHandle)
{	
	ResetPack(dataPackHandle);
	int client 		= GetClientOfUserId(ReadPackCell(dataPackHandle));
	int style 		= ReadPackCell(dataPackHandle);
	
	B_IsWR[client] = true;
	BotMimic_StopRecording(client, true);
	ReplayWR(style);
}

/***********************************************************/
/************** TIMER WORLD RECORD SAVE REPLAY *************/
/***********************************************************/
public int BotMimic_OnRecordSaved(int client, char[] name, char[] category, char[] subdir, char[] file)
{
	if(B_active_timer_replay_dev)
	{
		PrintToChatAll("%i - %s", C_timer_os, file);
	}
	
	if(B_IsWR[client])
	{
		char Query[2048], S_mapname[64], S_steamid[64];
		GetCurrentMap(S_mapname, 64);
		
		GetClientAuthId(client, AuthId_Steam2, S_steamid, sizeof(S_steamid));
		if(C_timer_os == 0)
		{
			if(B_active_timer_replay_dev)
			{
				PrintToChatAll("linux detect");
			}
			ReplaceString(file, PLATFORM_MAX_PATH, "addons/sourcemod/data/botmimic/bhop/wr/", "");
		}
		else if(C_timer_os == 1)
		{
			if(B_active_timer_replay_dev)
			{
				PrintToChatAll("windows detect");
			}
			ReplaceString(file, PLATFORM_MAX_PATH, "\\", "/");
			ReplaceString(file, PLATFORM_MAX_PATH, "addons/sourcemod/data/botmimic/bhop/wr/", "");
		}
		Format(Query, sizeof(Query), Sql_UpdateReplayPath, file, S_steamid[8], S_mapname, Timer_GetStyle(client));
		SQL_TQuery(g_hSQL, SQL_UpdateReplayPathCallback, Query, _, DBPrio_Low);
	}
	
	if(B_active_timer_replay_dev)
	{
		PrintToChatAll("%i - %s", C_timer_os, file);
	}
}

/***********************************************************/
/********************** BOT START MIMIC ********************/
/***********************************************************/
public Action BotMimic_OnPlayerStartsMimicing(int client, char[] name, char[] category, char[] path)
{
	F_Timer[client] = GetGameTime();

}

/***********************************************************/
/********************** BOT LOOP MIMIC *********************/
/***********************************************************/
public int BotMimic_OnPlayerMimicLoops(int client)
{
	F_Timer[client] = GetGameTime();
}

/***********************************************************/
/******************* SQL QUERY BACKUP **********************/
/***********************************************************/
public void Sql_BackupWrReplayCallback(Handle hOwner, Handle hQuery, const char[] strError, any data)
{
	if(hQuery == INVALID_HANDLE)
	{
		LogError("%s SQL Error: %s", TAG_CHAT, strError);
	}
	
	char S_file[PLATFORM_MAX_PATH], S_path[PLATFORM_MAX_PATH], S_newpath[PLATFORM_MAX_PATH];
	
	if(SQL_HasResultSet(hQuery))
	{
		while(SQL_FetchRow(hQuery))
		{
			SQL_FetchString(hQuery, 0, S_file, PLATFORM_MAX_PATH);
			
			if(!S_file[0]) return;
			
			if(C_timer_os == 0)
			{
				Format(S_path, PLATFORM_MAX_PATH, "addons/sourcemod/data/botmimic/bhop/wr/%s", S_file);
				Format(S_newpath, PLATFORM_MAX_PATH, "addons/sourcemod/data/botmimic/bhop/wr/backup/%s", S_file);
			}
			else if(C_timer_os == 1)
			{
				Format(S_path, PLATFORM_MAX_PATH, "addons\\sourcemod\\data\\botmimic\\bhop\\wr\\%s", S_file);
				Format(S_newpath, PLATFORM_MAX_PATH, "addons\\sourcemod\\data\\botmimic\\bhop\\wr\\backup\\%s", S_file);
			}
			RenameFile(S_newpath ,S_path);
			
			if(B_active_timer_replay_dev)
			{
				PrintToChatAll("Sql_BackupWrReplayCallback: %s", S_path);
				PrintToChatAll("Sql_BackupWrReplayCallback: %s", S_newpath);
			}	
		}
	}
}

/***********************************************************/
/******************* SQL QUERY UPDATE **********************/
/***********************************************************/
public void SQL_UpdateReplayPathCallback(Handle hOwner, Handle hQuery, const char[] strError, any data)
{
	if(hQuery == INVALID_HANDLE)
	{
		LogError("%s SQL Error: %s", TAG_CHAT, strError);
	}
}

/***********************************************************/
/*********************** REPLAY WR *************************/
/***********************************************************/
void ReplayWR(int style)
{
	char Query[2048], S_mapname[64];
	
	GetCurrentMap(S_mapname, 64);
	Format(Query, sizeof(Query), Sql_SelectWrReplay, S_mapname, style, 1);
	
	SQL_TQuery(g_hSQL, Sql_SelectWrReplayCallback, Query, _, DBPrio_Low);
}

/***********************************************************/
/******************* SQL QUERY SELECT **********************/
/***********************************************************/
public void Sql_SelectWrReplayCallback(Handle hOwner, Handle hQuery, const char[] strError, any data)
{
	if(hQuery == INVALID_HANDLE)
	{
		LogError("%s SQL Error: %s", TAG_CHAT, strError);
	}
	char S_file[PLATFORM_MAX_PATH], S_path[PLATFORM_MAX_PATH], S_time[16], S_name[64], S_jump[16], S_avgspeed[16], S_maxspeed[16];
	int style;
	
	if(SQL_HasResultSet(hQuery))
	{
		while(SQL_FetchRow(hQuery))
		{
			SQL_FetchString(hQuery, 0, S_file, PLATFORM_MAX_PATH);
			style = SQL_FetchInt(hQuery, 1);
			SQL_FetchString(hQuery, 2, S_time, 16);
			SQL_FetchString(hQuery, 3, S_name, 64);
			SQL_FetchString(hQuery, 4, S_jump, 16);
			SQL_FetchString(hQuery, 5, S_avgspeed, 16);
			SQL_FetchString(hQuery, 6, S_maxspeed, 16);
			
			
			if(!S_file[0]) return;
			
			if(C_timer_os == 0)
			{
				Format(S_path, PLATFORM_MAX_PATH, "addons/sourcemod/data/botmimic/bhop/wr/%s", S_file);
			}
			else if(C_timer_os == 1)
			{
				Format(S_path, PLATFORM_MAX_PATH, "addons\\sourcemod\\data\\botmimic\\bhop\\wr\\%s", S_file);
			}
			strcopy(S_FileReplay[style], PLATFORM_MAX_PATH, S_path);
			
			if(!FileExists(S_FileReplay[style])) return;
			
			strcopy(S_FileReplayTime[style], 16, S_time);
			strcopy(S_FileReplayName[style], 64, S_name);
			strcopy(S_FileReplayJump[style], 16, S_jump);
			strcopy(S_FileReplayAvgspeed[style], 16, S_avgspeed);
			strcopy(S_FileReplayMaxspeed[style], 16, S_maxspeed);
			
			
			if(GetBotReplayed(style) == 0)
			{
				ServerCommand("bot_add");
				C_FileReplayStyle = style;
			}
			else
			{
				int bot = GetBotReplayed(style);
				if(BotMimic_IsPlayerMimicing(bot))
				{
					BotMimic_StopPlayerMimic(bot);
				}
				if(!IsPlayerAlive(bot))
				{
					CS_SwitchTeam(bot, CS_TEAM_T);
					CS_SwitchTeam(bot, CS_TEAM_CT);
					CS_RespawnPlayer(bot);
				}
				
				C_BotStyle[bot] = style;
				BotMimic_PlayRecordFromFile(bot, S_FileReplay[style]);
				
			}
			
			if(B_active_timer_replay_dev)
			{
				LogMessage("%s", S_path);
			}
			
		}
	}
}

/***********************************************************/
/******************** TIMER HUD BOT MIMIC ******************/
/***********************************************************/
public Action Timer_HUDTimer_CSGO(Handle timer)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			UpdateHUD_CSGO(client);
		}
	}

	return Plugin_Continue;
}

/***********************************************************/
/*********************** HUD BOT MIMIC *********************/
/***********************************************************/
void UpdateHUD_CSGO(int client)
{
	if(!IsClientInGame(client))
	{
		return;
	}
	
	int iClientToShow; 
	int iObserverMode;

	iClientToShow = client;
	
	if(!IsPlayerAlive(client) || IsClientObserver(client))
	{
		iObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
		if(iObserverMode == SPECMODE_FIRSTPERSON || iObserverMode == SPECMODE_3RDPERSON)
		{
			iClientToShow = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			
			if(iClientToShow <= 0 || iClientToShow > MaxClients || !IsFakeClient(iClientToShow))
			{
				return;
			}
		}
		else
		{
			return;
		}
		

		C_StyleTarget[client] = C_BotStyle[iClientToShow];
		
		char centerText[1024], S_record[48];
		
		Timer_SecondsToTime(StringToFloat(S_FileReplayTime[C_StyleTarget[client]]), S_record, sizeof(S_record), 2);
		
		Format(S_record, 48, "%s", S_record);
		
		//1ST LINE
		Format(centerText, sizeof(centerText), "%T", "WR", client, S_record);
		
		if(B_timer_wr_holder_name)
		{
			Format(centerText, sizeof(centerText), "%T", "Holdermame", client, centerText, S_FileReplayName[C_StyleTarget[client]]);
		}
		else
		{
			Format(centerText, sizeof(centerText), "%T", "Botname", client, centerText, iClientToShow);
		}
		Format(centerText, sizeof(centerText), "%T", "Jumps", client, centerText, S_FileReplayJump[C_StyleTarget[client]]);
		
		//2ND LINE
		float currentspeed;
		Timer_GetCurrentSpeed(iClientToShow, currentspeed);
		
		float currenttime;
		
		char S_currenttime[48];
		currenttime = GetGameTime() - F_Timer[iClientToShow];
		Timer_SecondsToTime(currenttime, S_currenttime, sizeof(S_currenttime), 2);
		
		if(currenttime > StringToFloat(S_FileReplayTime[C_StyleTarget[client]]))
		{
			Format(centerText, sizeof(centerText), "%T", "Time", client, centerText, S_record, currentspeed);
		}
		else
		{
			Format(centerText, sizeof(centerText), "%T", "Time", client, centerText, S_currenttime, currentspeed);
		}

		
		//3RD LINE KEYBOARD
		char S_IN_FORWARD[32], S_IN_BACK[32], S_IN_MOVERIGHT[32], S_IN_MOVELEFT[32], S_IN_JUMP[32], S_IN_DUCK[32];
		if(GetClientButtons(iClientToShow) & IN_FORWARD)
		{
			strcopy(S_IN_FORWARD, 16, "↑"); 
		}
		else
		{
			strcopy(S_IN_FORWARD, 16, "_"); 
		}
		
		if(GetClientButtons(iClientToShow) & IN_BACK)
		{
			strcopy(S_IN_BACK, 16, "↓"); 
		}
		else
		{
			strcopy(S_IN_BACK, 16, "_");
		}
		
		if(GetClientButtons(iClientToShow) & IN_MOVERIGHT)
		{
			strcopy(S_IN_MOVERIGHT, 16, "→"); 
		}
		else
		{
			strcopy(S_IN_MOVERIGHT, 16, "_");
		}
		
		if(GetClientButtons(iClientToShow) & IN_MOVELEFT)
		{
			strcopy(S_IN_MOVELEFT, 16, "←"); 
		}
		else
		{
			strcopy(S_IN_MOVELEFT, 16, "_");
		}
		
		if(GetClientButtons(iClientToShow) & IN_JUMP || B_IsJump[iClientToShow])
		{
			strcopy(S_IN_JUMP, 16, "&#x021D7;"); 
		}
		else
		{
			strcopy(S_IN_JUMP, 16, "_");
		}
		
		B_IsJump[iClientToShow] = false;
		
		if(GetClientButtons(iClientToShow) & IN_DUCK)
		{
			strcopy(S_IN_DUCK , 16, "&#x021D8;"); 
		}
		else
		{
			strcopy(S_IN_DUCK, 16, "_");
		}
		
		Format(centerText, sizeof(centerText), "%s\n<font size='29'>%s%s%s%s | %s%s</font>", centerText, S_IN_MOVELEFT, S_IN_FORWARD, S_IN_MOVERIGHT, S_IN_BACK, S_IN_JUMP, S_IN_DUCK);
		
		PrintHintText(client, "<font size='16'>%s</font>", centerText);
	}
}

/***********************************************************/
/****************** WHEN PLAYER HOLD KEYS ******************/
/***********************************************************/
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(IsFakeClient(client))
	{
		if(GetClientButtons(client) & IN_JUMP)
		{
			B_IsJump[client] = true;
		}
	}
}

/***********************************************************/
/******************** GET PLAYER ALIVE *********************/
/***********************************************************/
stock int GetBotReplayed(int style)
{
	char S_botname[64], S_style[64];
	strcopy(S_style, 64, g_Physics[style][StyleName]);
		
	for(int i = 1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i) && IsFakeClient(i))
		{
			GetClientName(i, S_botname, 64);
			if(StrEqual(S_botname, S_style, false))
			{
				if(B_active_timer_replay_dev)
				{
					PrintToChatAll("GetBotReplayed: %N: replayed", i);
				}
				return i;
			}
		}
	}
	return 0; 
}

/***********************************************************/
/******************** GET PLAYER ALIVE *********************/
/***********************************************************/
stock int GetPlayersInGame()
{
	int iCount; iCount = 0; 
	for(int i = 1; i <= MaxClients; i++) 
	{
		if( IsClientInGame(i)) 
		{
			iCount++; 
		}
	}
	
	return iCount; 
}