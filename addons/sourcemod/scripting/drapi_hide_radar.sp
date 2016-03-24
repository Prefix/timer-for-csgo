/*   <DR.API HIDE RADAR> (c) by <De Battista Clint - (http://doyou.watch)    */
/*                                                                           */
/*                <DR.API HIDE RADAR> is licensed under a                    */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//****************************DR.API HIDE RADAR******************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[HIDE RADAR]-"

#define HIDE_RADAR_CSGO 				1<<12

//***********************************//
//*************INCLUDE***************//
//***********************************//

//Include native
#include <sourcemod>
#include <timer>
#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//


//Informations plugin
public Plugin myinfo =
{
	name = "DR.API HIDE RADAR",
	author = "Dr. Api",
	description = "DR.API HIDE RADAR by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	CreateConVar("drapi_hide_radar_version", PLUGIN_VERSION, "Version", CVARS);
	
	HookEvent("player_spawn", PlayerSpawn_Event);
}

/***********************************************************/
/******************** WHEN ROUND START *********************/
/***********************************************************/
public void PlayerSpawn_Event(Handle event, const char[] name, bool dB)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.0, Timer_RemoveRadar, client);
}

public Action Timer_RemoveRadar(Handle timer, any client) 
{
	if(!Timer_IsEnabled()) return;
	if(IsValidEntity(client))
	{
		SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_RADAR_CSGO);
	}
}