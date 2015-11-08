/*  <DR.API TIMER MAYAMODE> (c) by <De Battista Clint - (http://doyou.watch) */
/*                                                                           */
/*                 <DR.API TIMER MAYAMODE> is licensed under a               */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//***************************DR.API TIMER MAYAMODE***************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[TIMER MAYAMODE] -"

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <autoexec>
#include <sdktools>

#include <timer>
#include <timer-config_loader>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_mayamode_dev;

//Bool
bool B_active_mayamode_dev					= false;

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API TIMER MAYAMODE",
	author = "Dr. Api",
	description = "DR.API TIMER MAYAMODE by Dr. Api",
	version = PL_VERSION,
	url = "http://zombie4ever.eu"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	LoadPhysics();	
	
	AutoExecConfig_SetFile("drapi_mayamode", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_mayamode_version", PL_VERSION, "Version", CVARS);
	
	cvar_active_mayamode_dev			= AutoExecConfig_CreateConVar("drapi_active_mayamode_dev", 			"0", 					"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	HookEventsCvars();
	
	AutoExecConfig_ExecuteFile();
	
	SetCommandFlags("thirdperson_mayamode",GetCommandFlags("thirdperson_mayamode")^FCVAR_CHEAT);
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEventsCvars()
{
	HookConVarChange(cvar_active_mayamode_dev, 				Event_CvarChange);
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
	B_active_mayamode_dev 					= GetConVarBool(cvar_active_mayamode_dev);
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{	
	LoadPhysics();	
	UpdateState();
}

/***********************************************************/
/**************** ON CLIENT CHANGE STYLE *******************/
/***********************************************************/
public int OnClientChangeStyle(int client, int oldstyle, int newstyle, bool isnewstyle)
{
	if(newstyle == 20)
	{
		int target = GetRandomPlayer(client);
		if(target > 0)
		{
			SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
			SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", target);
		}
		else
		{
			Timer_SetStyle(client, g_StyleDefault);
		}
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", client);

	}
}

/***********************************************************/
/*********************** RANDOM PLAYER *********************/
/***********************************************************/
stock int GetRandomPlayer(int client) 
{
	int[] clients = new int[MaxClients];
	int clientCount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && client != i)
		{
			clients[clientCount++] = i;
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}