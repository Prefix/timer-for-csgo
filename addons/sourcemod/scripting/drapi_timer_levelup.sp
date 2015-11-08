/*    <DR.API LEVEL UP> (c) by <De Battista Clint - (http://doyou.watch)     */
/*                                                                           */
/*                    <DR.API LEVEL UP> is licensed under a                  */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//******************************DR.API LEVEL UP******************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1

//***********************************//
//*************DEFINE****************//
//***********************************//
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[LEVEL UP] -"

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <autoexec>
#include <csgocolors>
#include <timer>
#include <timer-rankings>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_levelup_dev;

//Bool
bool B_active_levelup_dev					= false;

//Strings
char SND_LVLUP[1][PLATFORM_MAX_PATH] 					= {"ui/xp_levelup.wav"};

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API LEVEL UP",
	author = "Dr. Api",
	description = "DR.API LEVEL UP by Dr. Api",
	version = PL_VERSION,
	url = "http://zombie4ever.eu"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{

	LoadTranslations("drapi/drapi_timer_levelup.phrases");
	AutoExecConfig_SetFile("drapi_levelup", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_levelup_version", PL_VERSION, "Version", CVARS);
	
	cvar_active_levelup_dev			= AutoExecConfig_CreateConVar("drapi_active_levelup_dev", 			"0", 					"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	HookEventsCvars();
	
	AutoExecConfig_ExecuteFile();
	
	RegAdminCmd("sm_setpoints", 						Command_SetPoints, 			ADMFLAG_CHANGEMAP, "");
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEventsCvars()
{
	HookConVarChange(cvar_active_levelup_dev, 				Event_CvarChange);
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
	B_active_levelup_dev 					= GetConVarBool(cvar_active_levelup_dev);
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	FakeAndDownloadSound(false, SND_LVLUP, 1);
	UpdateState();
}

/***********************************************************/
/******************* COMMAND SET POINTS ********************/
/***********************************************************/
public Action Command_SetPoints(int client, int args)
{
	char S_args1[256];
	GetCmdArg(1, S_args1, sizeof(S_args1));
	
	Timer_SetPoints(client, StringToInt(S_args1));
	Timer_SavePoints(client);
	PrintToChat(client, "%N set points to: %i", client, StringToInt(S_args1));
}

/***********************************************************/
/***************** ON PLAYER RANK LOADED *******************/
/***********************************************************/
public int OnPlayerRankLoaded(int client, int rank, int currentrank, int lastrank)
{
	if(IsClientInGame(client) && !IsFakeClient(client))
	{
		if(currentrank != -1)
		{
			int points = Timer_GetPoints(client);
			if(points <= 0)
			{
				//CPrintToChat(client, "%t", "New player");
				//PrintToAllExcludeNewPlayer(client, 0, "");
			}
			else
			{
				if(currentrank < lastrank || (lastrank == 0 && currentrank > lastrank))
				{
					char S_Rank[32];
					Timer_GetTag(S_Rank, sizeof(S_Rank), client);
					CPrintToChat(client, "%t","Level up player", S_Rank);
					PrintToAllExcludeNewPlayer(client, 1, S_Rank);
					
					char S_sound_to_play[PLATFORM_MAX_PATH];
					Format(S_sound_to_play, PLATFORM_MAX_PATH, "*%s", SND_LVLUP[0]);
					EmitSoundToClient(client, S_sound_to_play, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, _, _, _, _, _);
				}
			}
		}
		if(B_active_levelup_dev)
		{
			PrintToChatAll("current:%i, last:%i", currentrank, lastrank);
		}
	}
}


/***********************************************************/
/************* PRINT FOR ALL EXCLUDE THE TARGET ************/
/***********************************************************/
void PrintToAllExcludeNewPlayer(int client, int sentence, char[] rank)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) > 1 && client != i)
		{
			if(sentence == 0)
			{
				CPrintToChat(i, "%t", "New player2", client);
			}
			else if(sentence == 1)
			{
				CPrintToChat(i, "%t","Level up player2", client, rank);
			}
		}
	}
}

/***********************************************************/
/******************** ADD SOUND TO CACHE *******************/
/***********************************************************/
stock void FakePrecacheSound(const char[] szPath)
{
	AddToStringTable( FindStringTable( "soundprecache" ), szPath );
}

/***********************************************************/
/****************** FAKE AND DOWNLOAD SOUND ****************/
/***********************************************************/
stock void FakeAndDownloadSound(bool log, const char[][] stocksound, int num)
{
	for (int i = 0; i < num; i++)
	{
		char FULL_SOUND_PATH[PLATFORM_MAX_PATH];
		Format(FULL_SOUND_PATH, PLATFORM_MAX_PATH, "sound/%s", stocksound[i]);
		AddFileToDownloadsTable(FULL_SOUND_PATH);
		
		char RELATIVE_SOUND_PATH[PLATFORM_MAX_PATH];
		Format(RELATIVE_SOUND_PATH, PLATFORM_MAX_PATH, "*%s", stocksound[i]);
		FakePrecacheSound(RELATIVE_SOUND_PATH);
		
		if(log)
		{
			LogMessage("AddFileToDownloadsTable: %s, FakePrecacheSound: %s", FULL_SOUND_PATH, RELATIVE_SOUND_PATH);
		}
	}
}
