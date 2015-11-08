/*           <DR.API TIMER REPLAY CLEANER> (c) by <De Battista Clint         */
/*                                                                           */
/*              <DR.API TIMER REPLAY CLEANER> is licensed under a            */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//************************DR.API TIMER REPLAY CLEANER************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[TIMER REPLAY CLEANER] -"

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>

#include <autoexec>
#include <timer-config_loader>
#include <timer-mysql>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_timer_replay_cleaner_dev;
Handle cvar_timer_replay_cleaner_os;

Handle g_hSQL 									= INVALID_HANDLE;
Handle Array_FileToKeep							= INVALID_HANDLE;
Handle Array_FileToRemove						= INVALID_HANDLE;

//Bool
bool B_active_timer_replay_cleaner_dev			= false;

//Strings
char Sql_SelectWrReplay[] 						= "SELECT replaypath, style, time, name, jumps, avgspeed, maxspeed FROM round WHERE map = '%s' AND style = '%d' AND track = '0' ORDER BY time ASC LIMIT %d";

//Customs
int C_timer_replay_cleaner_os;

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API TIMER REPLAY CLEANER",
	author = "Dr. Api",
	description = "DR.API TIMER REPLAY CLEANER by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://zombie4ever.eu"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_timer_replay_cleaner", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_timer_replay_cleaner_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_timer_replay_cleaner_dev			= AutoExecConfig_CreateConVar("drapi_active_timer_replay_cleaner_dev", 			"0", 					"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_timer_replay_cleaner_os					= AutoExecConfig_CreateConVar("drapi_timer_replay_cleaner_os", 					"0", 					"OS System, 0 = linux, 1 = windows", 	DEFAULT_FLAGS);
	HookEventsCvars();
	
	AutoExecConfig_ExecuteFile();
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEventsCvars()
{
	HookConVarChange(cvar_active_timer_replay_cleaner_dev, 				Event_CvarChange);
	HookConVarChange(cvar_timer_replay_cleaner_os, 						Event_CvarChange);
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
	B_active_timer_replay_cleaner_dev 					= GetConVarBool(cvar_active_timer_replay_cleaner_dev);
	C_timer_replay_cleaner_os 							= GetConVarInt(cvar_timer_replay_cleaner_os);
}

/***********************************************************/
/******************* WHEN CONFIG EXECUTED ******************/
/***********************************************************/
public void OnConfigsExecuted()
{
	//UpdateState();
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	if (g_hSQL == INVALID_HANDLE)
	{
		ConnectSQL();
	}
	
	UpdateState();
	Array_FileToKeep 	= CreateArray(PLATFORM_MAX_PATH);
	Array_FileToRemove 	= CreateArray(PLATFORM_MAX_PATH);
	
	CreateTimer(10.0, Timer_DeleteFileRec, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_DeleteFileRec(Handle time)
{
	DeleteFileRec();
}
/***********************************************************/
/********************** WHEN MAP END ***********************/
/***********************************************************/
public void OnMapEnd()
{
	ClearArray(Array_FileToKeep);
	ClearArray(Array_FileToRemove);
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
/******************** DELETE FILE RECORD *******************/
/***********************************************************/
void DeleteFileRec()
{
	for(int style = 0; style < MAX_STYLES-1; style++)
	{
		char Query[2048], S_mapname[64];
			
		GetCurrentMap(S_mapname, 64);
		Format(Query, sizeof(Query), Sql_SelectWrReplay, S_mapname, style, 1);
		SQL_TQuery(g_hSQL, Sql_DeleteFileRecCallback, Query, _, DBPrio_High);
	}
	
	CreateTimer(2.0, Timer_RemoveFileRecordChecking, _, TIMER_FLAG_NO_MAPCHANGE);
}

/***********************************************************/
/****************** SQL DELETE FILE RECORD *****************/
/***********************************************************/
public void Sql_DeleteFileRecCallback(Handle hOwner, Handle hQuery, const char[] strError, any data)
{
	if(hQuery == INVALID_HANDLE)
	{
		LogError("%s SQL Error: %s", TAG_CHAT, strError);
	}
	
	if(SQL_HasResultSet(hQuery))
	{
		int count = SQL_GetRowCount(hQuery);
		if(count > 0)
		{
			while(SQL_FetchRow(hQuery))
			{
				char S_file[PLATFORM_MAX_PATH];
				
				SQL_FetchString(hQuery, 0, S_file, PLATFORM_MAX_PATH);
				
				char S_mapname[64], S_path[PLATFORM_MAX_PATH];
				GetCurrentMap(S_mapname, 64);
				ReplaceString(S_file, PLATFORM_MAX_PATH, S_mapname, "");
				
				if(C_timer_replay_cleaner_os == 0)
				{
					Format(S_path, PLATFORM_MAX_PATH, "addons/sourcemod/data/botmimic/bhop/wr/%s", S_mapname);
				}
				else if(C_timer_replay_cleaner_os == 1)
				{
					Format(S_path, PLATFORM_MAX_PATH, "addons\\sourcemod\\data\\botmimic\\bhop\\wr\\%s", S_mapname);
				
				}
				
				Handle dir = OpenDirectory(S_path);
				if (dir == INVALID_HANDLE)
				{
					return;
				}
				
				char S_pathDir[PLATFORM_MAX_PATH];
				FileType type;
				
				while (ReadDirEntry(dir, S_pathDir, sizeof(S_pathDir), type))
				{
					if(StrEqual(S_file[1], S_pathDir))
					{
						if(type == FileType_File)
						{
							PushArrayString(Array_FileToKeep, S_pathDir);
							
							if(B_active_timer_replay_cleaner_dev)
							{
								PrintToChatAll("Keep record: %s", S_pathDir);
							}
						}
					}
					else
					{
						if(type == FileType_File)
						{
							PushArrayString(Array_FileToRemove, S_pathDir);
							if(B_active_timer_replay_cleaner_dev)
							{
								PrintToChatAll("Delete record: %s", S_pathDir);
							}
						}
					}
				}
			}
		}
		else
		{
			char S_file[PLATFORM_MAX_PATH];
			char S_mapname[64], S_path[PLATFORM_MAX_PATH];
			GetCurrentMap(S_mapname, 64);
			ReplaceString(S_file, PLATFORM_MAX_PATH, S_mapname, "");
			
			if(C_timer_replay_cleaner_os == 0)
			{
				Format(S_path, PLATFORM_MAX_PATH, "addons/sourcemod/data/botmimic/bhop/wr/%s", S_mapname);
			}
			else if(C_timer_replay_cleaner_os == 1)
			{
				Format(S_path, PLATFORM_MAX_PATH, "addons\\sourcemod\\data\\botmimic\\bhop\\wr\\%s", S_mapname);
			
			}
			
			Handle dir = OpenDirectory(S_path);
			if (dir == INVALID_HANDLE)
			{
				return;
			}	
			
			char S_pathDir[PLATFORM_MAX_PATH];
			FileType type;
			
			while (ReadDirEntry(dir, S_pathDir, sizeof(S_pathDir), type))
			{
				if(type == FileType_File)
				{
					PushArrayString(Array_FileToRemove, S_pathDir);
					if(B_active_timer_replay_cleaner_dev)
					{
						PrintToChatAll("Delete record: %s", S_pathDir);
					}
				}
			}		
		}
	}
}

public Action Timer_RemoveFileRecordChecking(Handle timer)
{

	int arraySizeFileToKeep = GetArraySize(Array_FileToKeep);
	int arraySizeFileToRemove = GetArraySize(Array_FileToRemove);
	
	if(arraySizeFileToKeep && arraySizeFileToRemove)
	{
		char S_FileToKeep[PLATFORM_MAX_PATH], S_FileToRemove[PLATFORM_MAX_PATH];
		
		for(int itokeep = 0; itokeep < arraySizeFileToKeep; itokeep++)
		{
			GetArrayString(Array_FileToKeep, itokeep, S_FileToKeep, PLATFORM_MAX_PATH);
			
			for(int itoremove = 0; itoremove < arraySizeFileToRemove; itoremove++)
			{
				GetArrayString(Array_FileToRemove, itoremove, S_FileToRemove, PLATFORM_MAX_PATH);
				
				if(StrEqual(S_FileToKeep, S_FileToRemove))
				{
					SetArrayString(Array_FileToRemove, itoremove, "");
					
					if(B_active_timer_replay_cleaner_dev)
					{
						PrintToChatAll("Remove array: [%i] - %s", itoremove, S_FileToRemove);
					}
				}
			}
		}
	}
	
	CreateTimer(2.0, Timer_RemoveFileRecord, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_RemoveFileRecord(Handle timer)
{
	char S_mapname[64];
	GetCurrentMap(S_mapname, 64);
	
	int arraySizeFileToRemove = GetArraySize(Array_FileToRemove);
	
	if(arraySizeFileToRemove)
	{
		char S_FileToDelete[PLATFORM_MAX_PATH], S_pathToDelete[PLATFORM_MAX_PATH];
		
		for(int itoremove = 0; itoremove < arraySizeFileToRemove; itoremove++)
		{
			GetArrayString(Array_FileToRemove, itoremove, S_FileToDelete, PLATFORM_MAX_PATH);
			
			if(C_timer_replay_cleaner_os == 0)
			{
				Format(S_pathToDelete, PLATFORM_MAX_PATH, "addons/sourcemod/data/botmimic/bhop/wr/%s/%s", S_mapname, S_FileToDelete);
			}
			else if(C_timer_replay_cleaner_os == 1)
			{
				Format(S_pathToDelete, PLATFORM_MAX_PATH, "addons\\sourcemod\\data\\botmimic\\bhop\\wr\\%s\\%s", S_mapname, S_FileToDelete);
			}
			
			DeleteFile(S_pathToDelete);
			
			if(B_active_timer_replay_cleaner_dev)
			{
				PrintToChatAll("Remove RECORDS: [%i] - %s", itoremove, S_FileToDelete);
			}
		}
	}
}