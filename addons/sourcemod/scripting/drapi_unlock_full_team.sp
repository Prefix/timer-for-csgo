/*<DR.API UNLOCK FULL TEAM> (c) by <De Battista Clint - (http://doyou.watch) */
/*                                                                           */
/*                <DR.API UNLOCK FULL TEAM> is licensed under a              */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//**************************DR.API UNLOCK FULL TEAM**************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[UNLOCK FULL TEAM] -"

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#include <autoexec>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_unlock_full_team_dev;
Handle cvar_unlock_full_team_t_spawns;
Handle cvar_unlock_full_team_ct_spawns;

//Bool
bool B_active_unlock_full_team_dev					= false;

//Customs
int C_unlock_full_team_t_spawns;
int C_unlock_full_team_ct_spawns;

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API UNLOCK FULL TEAM",
	author = "Dr. Api",
	description = "DR.API UNLOCK FULL TEAM by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://zombie4ever.eu"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_unlock_full_team", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_unlock_full_team_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_unlock_full_team_dev			= AutoExecConfig_CreateConVar("drapi_active_unlock_full_team_dev", 			"0", 					"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	cvar_unlock_full_team_t_spawns				= AutoExecConfig_CreateConVar("drapi_unlock_full_team_t_spawns", 			"32", 					"Spawns for T", 						DEFAULT_FLAGS);
	cvar_unlock_full_team_ct_spawns				= AutoExecConfig_CreateConVar("drapi_unlock_full_team_ct_spawns", 			"32", 					"Spawns for CT", 						DEFAULT_FLAGS);
	
	HookEventsCvars();
	
	AutoExecConfig_ExecuteFile();
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEventsCvars()
{
	HookConVarChange(cvar_active_unlock_full_team_dev, 				Event_CvarChange);
	
	HookConVarChange(cvar_unlock_full_team_t_spawns, 				Event_CvarChange);
	HookConVarChange(cvar_unlock_full_team_ct_spawns, 				Event_CvarChange);
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
	B_active_unlock_full_team_dev 					= GetConVarBool(cvar_active_unlock_full_team_dev);
	
	C_unlock_full_team_t_spawns 					= GetConVarInt(cvar_unlock_full_team_t_spawns);
	C_unlock_full_team_ct_spawns 					= GetConVarInt(cvar_unlock_full_team_ct_spawns);
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	UpdateState();
	SetSpawns();
}

/***********************************************************/
/*********************** SET SPAWNS ************************/
/***********************************************************/
void SetSpawns()
{
	int CTspawns = 0;
	int Tspawns = 0;
	
	float fVecCt[3];
	float fVecT[3];
	float angVec[3];
	
	int maxEnt = GetMaxEntities();
	char sClassName[64];
	
	for(int i = MaxClients; i < maxEnt; i++)
	{
		if(IsValidEdict(i) && IsValidEntity(i) && GetEdictClassname(i, sClassName, sizeof(sClassName)))
		{
			if(StrEqual(sClassName, "info_player_terrorist"))
			{
				Tspawns++;
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", fVecT);
			}
			else if(StrEqual(sClassName, "info_player_counterterrorist"))
			{
				CTspawns++;
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", fVecCt);
			}
		}
	}
	
	float fVecSpawn[3];
	if(fVecT[0] != 0.0 && fVecT[1] != 0.0 && fVecT[2] != 0.0)
	{
		fVecSpawn = fVecT;
	}
	else if(fVecCt[0] != 0.0 && fVecCt[1] != 0.0 && fVecCt[2] != 0.0)
	{
		fVecSpawn = fVecCt;
	}
	else
	{
		return;
	}
	
	for(int i = CTspawns; i <= C_unlock_full_team_ct_spawns ;i++)
	{
		int entity = CreateEntityByName("info_player_counterterrorist");
		if(DispatchSpawn(entity))
		{
			TeleportEntity(entity, fVecSpawn, angVec, NULL_VECTOR);
		}
	}
	
	for(int i = Tspawns; i <= C_unlock_full_team_t_spawns ;i++)
	{
		int entity = CreateEntityByName("info_player_terrorist");
		if(DispatchSpawn(entity))
		{
			TeleportEntity(entity, fVecSpawn, angVec, NULL_VECTOR);
		}
	}
}