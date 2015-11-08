/*<DR.API JOIN TEAM MESSAGE> (c) by <De Battista Clint - (http://doyou.watch)*/
/*                                                                           */
/*               <DR.API JOIN TEAM MESSAGE> is licensed under a              */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//**************************DR.API JOIN TEAM MESSAGE*************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[JOIN TEAM MESSAGE] -"

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <cstrike>
#include <autoexec>
#include <csgocolors>
#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_join_team_message_dev;

//Bool
bool B_active_join_team_message_dev					= false;

//Informations plugin
public Plugin myinfo =
{
	name = "[TIMER] DR.API JOIN TEAM MESSAGE",
	author = "Dr. Api",
	description = "DR.API JOIN TEAM MESSAGE by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://zombie4ever.eu"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	LoadTranslations("drapi/drapi_join_team_message.phrases");
	AutoExecConfig_SetFile("drapi_join_team_message", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_join_team_message_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_join_team_message_dev			= AutoExecConfig_CreateConVar("drapi_active_join_team_message_dev", 			"0", 					"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	HookEventsCvars();
	
	AutoExecConfig_ExecuteFile();
	
	HookEvent("player_team", Event_PlayerTeam_Pre, EventHookMode_Pre);
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEventsCvars()
{
	HookConVarChange(cvar_active_join_team_message_dev, 				Event_CvarChange);
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
	B_active_join_team_message_dev 					= GetConVarBool(cvar_active_join_team_message_dev);
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	UpdateState();
}

/***********************************************************/
/*********************** PLAYER TEAM PRE *******************/
/***********************************************************/
public Action Event_PlayerTeam_Pre(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int team = GetEventInt(event, "team");
	
	char S_name[64];
	GetClientName(client, S_name, sizeof(S_name));
	
	if(!dontBroadcast)
	{
		Handle new_event = CreateEvent("player_team", true);
		
		SetEventInt(new_event, "userid", GetEventInt(event, "userid"));
		SetEventInt(new_event, "team", GetEventInt(event, "team"));
		SetEventInt(new_event, "oldteam", GetEventInt(event, "oldteam"));
		SetEventBool(new_event, "disconnect", GetEventBool(event, "disconnect"));
		
		FireEvent(new_event, true);
		
		return Plugin_Handled;
	}
	
	if(!IsFakeClient(client))
	{
		if(team == CS_TEAM_CT)
		{
			CPrintToChatAll("%t", "CT", S_name);
		}
		else if(team == CS_TEAM_T)
		{
			CPrintToChatAll("%t", "T", S_name);
		}
		else if(team == CS_TEAM_SPECTATOR)
		{
			CPrintToChatAll("%t", "SPEC", S_name);
		}
	}
	
	return Plugin_Continue;
}