/*  <DR.API RADIO MESSAGE> (c) by <De Battista Clint - (http://doyou.watch)  */
/*                                                                           */
/*                 <DR.API RADIO MESSAGE> is licensed under a                */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//***************************DR.API RADIO MESSAGE****************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[RADIO MESSAGE] -"

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <autoexec>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_radio_message_dev;

UserMsg RadioText;
UserMsg TextMsg;
UserMsg SayText;
UserMsg SayText2;

//Bool
bool B_active_radio_message_dev					= false;

//Strings
char S_Name[MAXPLAYERS+1][32];
//Informations plugin
public Plugin myinfo =
{
	name = "[TIMER] DR.API RADIO MESSAGE",
	author = "Dr. Api",
	description = "DR.API RADIO MESSAGE by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://zombie4ever.eu"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_radio_message", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_radio_message_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_radio_message_dev			= AutoExecConfig_CreateConVar("drapi_active_radio_message_dev", 			"0", 					"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	HookEventsCvars();
	
	AutoExecConfig_ExecuteFile();
	
	TextMsg  					= GetUserMessageId("TextMsg");
	SayText  					= GetUserMessageId("SayText");
	SayText2 					= GetUserMessageId("SayText2");
	RadioText 					= GetUserMessageId("RadioText");
	
	HookUserMessage(TextMsg,  	UserMessagesHook, true);
	HookUserMessage(SayText,  	UserMessagesHook, true);
	HookUserMessage(SayText2, 	UserMessagesHook, true);
	HookUserMessage(RadioText, 	UserMessagesHook, true);
	
	HookEvent("player_changename", Event_OnNameChange);
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEventsCvars()
{
	HookConVarChange(cvar_active_radio_message_dev, 				Event_CvarChange);
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
	B_active_radio_message_dev 					= GetConVarBool(cvar_active_radio_message_dev);
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	UpdateState();
}

/***********************************************************/
/****************** ON CLIENT CONNECTED ********************/
/***********************************************************/
public void OnClientConnected(int client)
{
	if(client)
	{
		GetClientName(client, S_Name[client], sizeof(S_Name[]));
	}
}

/***********************************************************/
/********************* PLAYER CHANGE NAME ******************/
/***********************************************************/
public Action Event_OnNameChange(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetEventString(event, "newname", S_Name[client], 32);
	return Plugin_Continue;
}

/***********************************************************/
/******************* WHEN PLAYER MESSAGE *******************/
/***********************************************************/
public Action UserMessagesHook(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init)
{	
	if(msg_id == SayText2)
	{
		char _sMessage[96];
		PbReadString(msg, "params", _sMessage, sizeof(_sMessage), 0);
		PbReadString(msg, "params", _sMessage, sizeof(_sMessage), 0);

		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && StrEqual(_sMessage, S_Name[i], false))
			{
				return Plugin_Handled;
			}
		}
	}
	
	if(msg_id == RadioText)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}