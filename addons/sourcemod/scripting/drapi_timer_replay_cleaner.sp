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
	DeleteFileRec();
}

/***********************************************************/
/********************** WHEN MAP END ***********************/
/***********************************************************/
public void OnMapEnd()
{
	DeleteFileRec();
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
	
	char S_file[PLATFORM_MAX_PATH];
	
	if(SQL_HasResultSet(hQuery))
	{
		while(SQL_FetchRow(hQuery))
		{
			SQL_FetchString(hQuery, 0, S_file, PLATFORM_MAX_PATH);
			
			if(!S_file[0]) return;
			
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
					if(B_active_timer_replay_cleaner_dev)
					{
						PrintToChatAll("Keep record: %s", S_file);
					}
				}
				else
				{
					if(type == FileType_File)
					{
						Handle Array_File = CreateArray(PLATFORM_MAX_PATH);
						PushArrayString(Array_File, S_pathDir);
						
						int arraySizeFile = GetArraySize(Array_File);
						
						if(arraySizeFile)
						{
							char S_FileToDelete[PLATFORM_MAX_PATH], S_pathToDelete[PLATFORM_MAX_PATH];
							for(int i = 0; i < arraySizeFile; i++)
							{
								GetArrayString(Array_File, i, S_FileToDelete, PLATFORM_MAX_PATH);
								
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
									PrintToChatAll("Delete record: %s", S_FileToDelete);
								}
							}
						}
						
						ClearArray(Array_File);
					}
				}
			}
			
		}
	}
}