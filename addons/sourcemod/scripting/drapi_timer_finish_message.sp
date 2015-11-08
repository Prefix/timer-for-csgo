/* <DR.API TIMER FINISH MSG> (c) by <De Battista Clint - (http://doyou.watch)*/
/*                                                                           */
/*                <DR.API TIMER FINISH MSG> is licensed under a              */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//**************************DR.API TIMER FINISH MSG**************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[TIMER FINISH MSG] -"

//***********************************//
//*************INCLUDE***************//
//***********************************//
#include <sourcemod>
#include <cstrike>
#include <timer>
#include <timer-stocks>
#include <timer-config_loader>
#include <autoexec>

#undef REQUIRE_PLUGIN
#include <timer-physics>
#include <timer-worldrecord>
#include <timer-strafes>


#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_timer_finish_message_dev;

//Bool
bool B_active_timer_finish_message_dev					= false;

bool B_timerPhysics 									= false;
bool B_timerWorldRecord 								= false;

//Informations plugin
public Plugin myinfo =
{
	name = "[TIMER] DR.API TIMER FINISH MSG",
	author = "Dr. Api",
	description = "DR.API TIMER FINISH MSG by Dr. Api",
	version = PL_VERSION,
	url = "http://zombie4ever.eu"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	LoadTranslations("drapi/drapi_timer_finish_message.phrases");
	AutoExecConfig_SetFile("drapi_timer_finish_message", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_timer_finish_message_version", PL_VERSION, "Version", CVARS);
	
	cvar_active_timer_finish_message_dev			= AutoExecConfig_CreateConVar("drapi_active_timer_finish_message_dev", 			"0", 					"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	HookEventsCvars();
	
	AutoExecConfig_ExecuteFile();
	
	if(GetEngineVersion() != Engine_CSGO)
	{
		Timer_LogError("Don't use this plugin for other games than CS:GO.");
		SetFailState("Check timer error logs.");
		return;
	}

	B_timerPhysics 			= LibraryExists("timer-physics");
	B_timerWorldRecord 		= LibraryExists("timer-worldrecord");

	LoadPhysics();
	LoadTimerSettings();
}

/***********************************************************/
/******************** ON LIBRARY ADDED *********************/
/***********************************************************/
public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "timer-physics"))
	{
		B_timerPhysics = true;
	}
	else if (StrEqual(name, "timer-worldrecord"))
	{
		B_timerWorldRecord = true;
	}
}

/***********************************************************/
/******************* ON LIBRARY REMOVED ********************/
/***********************************************************/
public void OnLibraryRemoved(const char[] name)
{	
	if (StrEqual(name, "timer-physics"))
	{
		B_timerPhysics = false;
	}	
	else if (StrEqual(name, "timer-worldrecord"))
	{
		B_timerWorldRecord = false;
	}
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEventsCvars()
{
	HookConVarChange(cvar_active_timer_finish_message_dev, 				Event_CvarChange);
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
	B_active_timer_finish_message_dev 					= GetConVarBool(cvar_active_timer_finish_message_dev);
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
	LoadPhysics();
	LoadTimerSettings();
	
	UpdateState();
}

/***********************************************************/
/******************** ON TIMER RECORD **********************/
/***********************************************************/
public int OnTimerRecord(int client, int track, int style, float time, float lasttime, int currentrank, int newrank)
{
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	int RecordId, RankTotal, LastJumps;
	float RecordTime, LastTime, LastTimeStatic, jumpacc;
	
	LastTime = 0.0;
	bool NewPersonalRecord 	= false;
	bool NewWorldRecord 	= false;
	bool FirstRecord 		= true;
	bool ranked;
	
	if(B_timerPhysics) 
	{
		ranked = view_as<bool>(Timer_IsStyleRanked(style));
		Timer_GetJumpAccuracy(client, jumpacc);
	}

	
	bool enabled = false;
	int jumps = 0;
	int fpsmax;

	Timer_GetClientTimer(client, enabled, time, jumps, fpsmax);
	
	if(Timer_GetBestRound(client, style, track, LastTime, LastJumps))
	{
		LastTimeStatic = LastTime;
		FirstRecord = false;
	}

	//GET CURRENT TIME
	char TimeString[32];
	Timer_SecondsToTime(time, TimeString, sizeof(TimeString), 2);
	
	//GET LAST TIME
	char LastTimeString[32];
	Timer_SecondsToTime(LastTime, LastTimeString, sizeof(LastTimeString), 2);
	
	//GET WR TIME
	char WrTime[32];
	float wrtime;
	if(B_timerWorldRecord) 
	{
		Timer_GetRecordTimeInfo(style, track, newrank, wrtime, WrTime, 32);
		Timer_GetStyleRecordWRStats(style, track, RecordId, RecordTime, RankTotal);
	}
	
	if(RecordTime == 0.0 || time < RecordTime)
	{
		NewWorldRecord = true;
	}
	
	if(LastTimeStatic == 0.0 || time < LastTimeStatic)
	{
		NewPersonalRecord = true;
	}
	
	char BonusString[32];
	
	if(track == TRACK_BONUS)
	{
		FormatEx(BonusString, sizeof(BonusString), " | BONUS");
	}
	else if(track == TRACK_BONUS2)
	{
		FormatEx(BonusString, sizeof(BonusString), " | BONUS2");
	}
	else if(track == TRACK_BONUS3)
	{
		FormatEx(BonusString, sizeof(BonusString), " | BONUS3");
	}
	else if(track == TRACK_BONUS4)
	{
		FormatEx(BonusString, sizeof(BonusString), " | BONUS4");
	}
	else if(track == TRACK_BONUS5)
	{
		FormatEx(BonusString, sizeof(BonusString), " | BONUS5");
	}
	
	char StyleString[128];
	
	if(g_Settings[MultimodeEnable])
	{
		FormatEx(StyleString, sizeof(StyleString), "%s", g_Physics[style][StyleName]);
	}
	
	if(NewWorldRecord)
	{
		CPrintToChatAll("");
		CPrintToChatAll("%t", "Header", BonusString);
		CPrintToChatAll("%t", "Name", name);
		CPrintToChatAll("%t", "Style", StyleString);
		CPrintToChatAll("%t", "Time", TimeString);
		if(wrtime > 0.0)
		{
			CPrintToChatAll("%t", "OldTime", WrTime);
		}
		CPrintToChatAll("%t", "Header", BonusString);
		CPrintToChatAll("");
	}
	else
	{
		if(ranked)
		{
			if(NewPersonalRecord && !FirstRecord)
			{
				CPrintToChatAll("");
				CPrintToChatAll("%t", "Header2", name, BonusString);
				CPrintToChatAll("%t", "Style", StyleString);
				CPrintToChatAll("%t", "Time", TimeString);
				CPrintToChatAll("%t", "OldTime", LastTimeString);
				CPrintToChatAll("");
				
			}
			else
			{
				CPrintToChatAll("");
				CPrintToChatAll("%t", "Header2", name, BonusString);
				CPrintToChatAll("%t", "Style", StyleString);
				CPrintToChatAll("%t", "Time", TimeString);
				CPrintToChatAll("");
			}
		}
		else
		{
			CPrintToChatAll("");
			CPrintToChatAll("%t", "Header3", name, BonusString);
			CPrintToChatAll("%t", "Style", StyleString);
			CPrintToChatAll("%t", "Time", TimeString);
			CPrintToChatAll("");
		}
	}
}