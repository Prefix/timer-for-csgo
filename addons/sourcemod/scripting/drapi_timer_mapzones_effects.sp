/*         <DR.API TIMER MAPZONES EFFECTS> (c) by <De Battista Clint -       */
/*                                                                           */
/*            <DR.API TIMER MAPZONES EFFECTS> is licensed under a            */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//**********************DR.API TIMER MAPZONES EFFECTS************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[TIMER MAPZONES EFFECTS] -"
#define MAX_ZONES						10000

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <autoexec>
#include <timer>
#include <timer-mapzones>
#include <timer-mysql>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_timer_mapzones_effects_dev;

Handle cvar_timer_mapzones_effects_laser;
Handle cvar_timer_mapzones_effects_laser_start;
Handle cvar_timer_mapzones_effects_laser_end;
Handle cvar_timer_mapzones_effects_laser_stage;

Handle H_TimerDrawBox[MAX_ZONES];

//Floats
float F_high												= 0.0;
//Bool
bool B_active_timer_mapzones_effects_dev					= false;

//Strings
char S_timer_mapzones_effects_laser[PLATFORM_MAX_PATH];
char S_timer_mapzones_effects_laser_start[PLATFORM_MAX_PATH];
char S_timer_mapzones_effects_laser_end[PLATFORM_MAX_PATH];
char S_timer_mapzones_effects_laser_stage[PLATFORM_MAX_PATH];

//Customs
int BeamSpriteFollow;
int BeamSpriteFollowStart;
int BeamSpriteFollowEnd;
int BeamSpriteFollowStage;

//Informations plugin
public Plugin myinfo =
{
	name = "[TIMER] DR.API TIMER MAPZONES EFFECTS",
	author = "Dr. Api",
	description = "DR.API TIMER MAPZONES EFFECTS by Dr. Api",
	version = PL_VERSION,
	url = "http://zombie4ever.eu"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_timer_mapzones_effects", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_timer_mapzones_effects_version", PL_VERSION, "Version", CVARS);
	
	cvar_active_timer_mapzones_effects_dev			= AutoExecConfig_CreateConVar("drapi_active_timer_mapzones_effects_dev", 			"0", 					"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	cvar_timer_mapzones_effects_laser				= AutoExecConfig_CreateConVar("drapi_timer_mapzones_effects_laser", 				"materials/sprites/laserbeam", 					"Laser path");
	cvar_timer_mapzones_effects_laser_start			= AutoExecConfig_CreateConVar("drapi_timer_mapzones_effects_laser_start", 			"materials/sprites/drapi_start", 				"Laser Start path");
	cvar_timer_mapzones_effects_laser_end			= AutoExecConfig_CreateConVar("drapi_timer_mapzones_effects_laser_end", 			"materials/sprites/drapi_end", 					"Laser End path");
	cvar_timer_mapzones_effects_laser_stage			= AutoExecConfig_CreateConVar("drapi_timer_mapzones_effects_laser_stage", 			"materials/sprites/drapi_stage", 				"Laser Stage path");
	
	HookEventsCvars();
	
	AutoExecConfig_ExecuteFile();
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEventsCvars()
{
	HookConVarChange(cvar_active_timer_mapzones_effects_dev, 				Event_CvarChange);
	
	HookConVarChange(cvar_timer_mapzones_effects_laser, 					Event_CvarChange);
	HookConVarChange(cvar_timer_mapzones_effects_laser_start, 				Event_CvarChange);
	HookConVarChange(cvar_timer_mapzones_effects_laser_end, 				Event_CvarChange);
	HookConVarChange(cvar_timer_mapzones_effects_laser_stage, 				Event_CvarChange);
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
	B_active_timer_mapzones_effects_dev 						= GetConVarBool(cvar_active_timer_mapzones_effects_dev);
	
	GetConVarString(cvar_timer_mapzones_effects_laser, 			S_timer_mapzones_effects_laser, 			sizeof(S_timer_mapzones_effects_laser));
	GetConVarString(cvar_timer_mapzones_effects_laser_start, 	S_timer_mapzones_effects_laser_start, 		sizeof(S_timer_mapzones_effects_laser_start));
	GetConVarString(cvar_timer_mapzones_effects_laser_end, 		S_timer_mapzones_effects_laser_end, 		sizeof(S_timer_mapzones_effects_laser_end));
	GetConVarString(cvar_timer_mapzones_effects_laser_stage, 	S_timer_mapzones_effects_laser_stage, 		sizeof(S_timer_mapzones_effects_laser_stage));
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	UpdateState();

	char spritebuffer[PLATFORM_MAX_PATH];
	
	Format(spritebuffer, sizeof(spritebuffer), "%s.vmt", S_timer_mapzones_effects_laser);
	BeamSpriteFollow = PrecacheModel(spritebuffer);
	AddFileToDownloadsTable(spritebuffer);
	Format(spritebuffer, sizeof(spritebuffer), "%s.vtf", S_timer_mapzones_effects_laser);
	AddFileToDownloadsTable(spritebuffer);
	
	Format(spritebuffer, sizeof(spritebuffer), "%s.vmt", S_timer_mapzones_effects_laser_start);
	BeamSpriteFollowStart = PrecacheModel(spritebuffer);
	AddFileToDownloadsTable(spritebuffer);
	Format(spritebuffer, sizeof(spritebuffer), "%s.vtf", S_timer_mapzones_effects_laser_start);
	AddFileToDownloadsTable(spritebuffer);
	
	Format(spritebuffer, sizeof(spritebuffer), "%s.vmt", S_timer_mapzones_effects_laser_end);
	BeamSpriteFollowEnd = PrecacheModel(spritebuffer);
	AddFileToDownloadsTable(spritebuffer);
	Format(spritebuffer, sizeof(spritebuffer), "%s.vtf", S_timer_mapzones_effects_laser_end);
	AddFileToDownloadsTable(spritebuffer);
	
	Format(spritebuffer, sizeof(spritebuffer), "%s.vmt", S_timer_mapzones_effects_laser_stage);
	BeamSpriteFollowStage = PrecacheModel(spritebuffer);
	AddFileToDownloadsTable(spritebuffer);
	Format(spritebuffer, sizeof(spritebuffer), "%s.vtf", S_timer_mapzones_effects_laser_stage);
	AddFileToDownloadsTable(spritebuffer);
	
	PrintToChatAll("%s", S_timer_mapzones_effects_laser_start);
	for(int levelid = 0; levelid < MAX_ZONES; levelid++)
	{
		H_TimerDrawBox[levelid] = INVALID_HANDLE;
	}
}

/***********************************************************/
/****************** ON MAP ZONE LOADED *********************/
/***********************************************************/
public int OnMapZoneLoaded(int type, int levelid, float point1_x, float point1_y, float point1_z, float point2_x, float point2_y, float point2_z)
{
	//LogMessage("type: %i - %f - %f", levelid, point1_x, point2_x);
	
	if(H_TimerDrawBox[levelid] != INVALID_HANDLE)
	{
		ClearTimer(H_TimerDrawBox[levelid] );
	}
	if(H_TimerDrawBox[levelid] == INVALID_HANDLE)
	{
		Handle dataPackHandle;
		H_TimerDrawBox[levelid] = CreateDataTimer(1.0, TimerData_DrawBox, dataPackHandle, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(dataPackHandle, type);
		WritePackFloat(dataPackHandle, point1_x);
		WritePackFloat(dataPackHandle, point1_y);
		WritePackFloat(dataPackHandle, point1_z);
		WritePackFloat(dataPackHandle, point2_x);
		WritePackFloat(dataPackHandle, point2_y);
		WritePackFloat(dataPackHandle, point2_z);
	}
}

/***********************************************************/
/****************** TIMER DATA DRAW BOX ********************/
/***********************************************************/
public Action TimerData_DrawBox(Handle timer, Handle dataPackHandle)
{	
	ResetPack(dataPackHandle);
	
	int type 		= ReadPackCell(dataPackHandle);
	
	float point1[3], point2[3];
	
	point1[0] = ReadPackFloat(dataPackHandle);
	point1[1] = ReadPackFloat(dataPackHandle);
	point1[2] = ReadPackFloat(dataPackHandle);
	
	point2[0] = ReadPackFloat(dataPackHandle);
	point2[1] = ReadPackFloat(dataPackHandle);
	point2[2] = ReadPackFloat(dataPackHandle);
	
	float maxheight = 150.0;
	
	F_high += 1.0;
	if(F_high > maxheight)
	{
		F_high = 15.0;
	}
	
	//START
	if(type == 0)
	{
		DrawBox(BeamSpriteFollow, point1, point2, 1.0, 1.0, {0,255,0,200}, true, F_high);
		DrawBox(BeamSpriteFollowStart, point1, point2, 1.0, 6.0, {0,255,0,200}, true, 10.0);
	}
	//END
	else if(type == 1)
	{
		DrawBox(BeamSpriteFollow, point1, point2, 1.0, 1.0, {255,0,0,200}, true, F_high);
		DrawBox(BeamSpriteFollowEnd, point1, point2, 1.0, 6.0, {255,0,0,200}, true, 10.0);
	}
	//CP
	else if(type == 6 || type == 41)
	{
		//DrawBox(BeamSpriteFollow, point1, point2, 1.0, 1.0, {153,76,0,200}, true, F_high);
		DrawBox(BeamSpriteFollowStage, point1, point2, 1.0, 6.0, {153,76,0,200}, true, 10.0);
	}
	//BONUS START
	else if(type == 7 || type == 44 || type == 48 || type == 52 || type == 56)
	{
		DrawBox(BeamSpriteFollow, point1, point2, 1.0, 1.0, {153,255,51,200}, true, F_high);
		DrawBox(BeamSpriteFollowStart, point1, point2, 1.0, 6.0, {153,255,51,200}, true, 10.0);	
	}
	//BONUS END
	else if(type == 8 || type == 45 || type == 49 || type == 53 || type == 57)
	{
		DrawBox(BeamSpriteFollow, point1, point2, 1.0, 1.0, {255,102,102,200}, true, F_high);
		DrawBox(BeamSpriteFollowEnd, point1, point2, 1.0, 6.0, {255,102,102,200}, true, 10.0);	
	}
	//BONUS CP
	else if(type == 9 || type == 46 || type == 50 || type == 54 || type == 58 || type == 42 || type == 47 || type == 51 || type == 55 || type == 59)
	{
		//DrawBox(BeamSpriteFollow, point1, point2, 1.0, 1.0, {255,153,51,200}, true, F_high);
		DrawBox(BeamSpriteFollowStage, point1, point2, 1.0, 6.0, {255,153,51,200}, true, 10.0);	
	}
}

void DrawBox(int precacheLaser, float fFrom[3], float fTo[3], float fLife, float width, int color[4], bool flat, float high = 0.0)
{
	if(precacheLaser == 0)
	{
		precacheLaser = BeamSpriteFollow;
	}
		
	//initialize tempoary variables bottom front
	float fLeftBottomFront[3];
	fLeftBottomFront[0] = fFrom[0];
	fLeftBottomFront[1] = fFrom[1];
	if(flat)
	{
		fLeftBottomFront[2] = fTo[2]-2;
	}
	else
	{
		fLeftBottomFront[2] = fTo[2];
	}
	
	float fRightBottomFront[3];
	fRightBottomFront[0] = fTo[0];
	fRightBottomFront[1] = fFrom[1];
	if(flat)
	{
		fRightBottomFront[2] = fTo[2]-2;
	}
	else
	{
		fRightBottomFront[2] = fTo[2];
	}
	
	//initialize tempoary variables bottom back
	float fLeftBottomBack[3];
	fLeftBottomBack[0] = fFrom[0];
	fLeftBottomBack[1] = fTo[1];
	if(flat)
	{
		fLeftBottomBack[2] = fTo[2]-2;
	}
	else
	{
		fLeftBottomBack[2] = fTo[2];
	}
	
	float fRightBottomBack[3];
	fRightBottomBack[0] = fTo[0];
	fRightBottomBack[1] = fTo[1];
	if(flat)
	{
		fRightBottomBack[2] = fTo[2]-2;
	}
	else
	{
		fRightBottomBack[2] = fTo[2];
	}
	
	//initialize tempoary variables top front
	float lefttopfront[3];
	lefttopfront[0] = fFrom[0];
	lefttopfront[1] = fFrom[1];
	if(flat)
	{
		lefttopfront[2] = fFrom[2]+high;
	}
	else
	{
		lefttopfront[2] = fFrom[2]+high;
	}
	
	float righttopfront[3];
	righttopfront[0] = fTo[0];
	righttopfront[1] = fFrom[1];
	if(flat)
	{
		righttopfront[2] = fFrom[2]+high;
	}
	else
	{
		righttopfront[2] = fFrom[2]+high;
	}
	
	//initialize tempoary variables top back
	float fLeftTopBack[3];
	fLeftTopBack[0] = fFrom[0];
	fLeftTopBack[1] = fTo[1];
	if(flat)
	{
		fLeftTopBack[2] = fFrom[2]+high;
	}
	else
	{
		fLeftTopBack[2] = fFrom[2]+high;
	}
	
	float fRightTopBack[3];
	fRightTopBack[0] = fTo[0];
	fRightTopBack[1] = fTo[1];
	if(flat)
	{
		fRightTopBack[2] = fFrom[2]+high;
	}
	else
	{
		fRightTopBack[2] = fFrom[2]+high;
	}
	
	//create the box
	TE_SetupBeamPoints(lefttopfront,righttopfront,precacheLaser,0,0,0,fLife,width,width,10,0.0,color,10);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
	
	TE_SetupBeamPoints(fLeftTopBack,lefttopfront,precacheLaser,0,0,0,fLife,width,width,10,0.0,color,10);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
	
	TE_SetupBeamPoints(fRightTopBack,fLeftTopBack,precacheLaser,0,0,0,fLife,width,width,10,0.0,color,10);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
	
	TE_SetupBeamPoints(righttopfront,fRightTopBack,precacheLaser,0,0,0,fLife,width,width,10,0.0,color,10);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);

	if(!flat)
	{
		TE_SetupBeamPoints(fLeftBottomFront,fRightBottomFront,precacheLaser,0,0,0,fLife,width,width,10,0.0,color,10);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
		TE_SetupBeamPoints(fLeftBottomFront,fLeftBottomBack,precacheLaser,0,0,0,fLife,width,width,10,0.0,color,10);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
		TE_SetupBeamPoints(fLeftBottomFront,lefttopfront,precacheLaser,0,0,0,fLife,width,width,10,0.0,color,10);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);

		
		TE_SetupBeamPoints(fRightBottomBack,fLeftBottomBack,precacheLaser,0,0,0,fLife,width,width,10,0.0,color,10);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
		TE_SetupBeamPoints(fRightBottomBack,fRightBottomFront,precacheLaser,0,0,0,fLife,width,width,10,0.0,color,10);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
		TE_SetupBeamPoints(fRightBottomBack,fRightTopBack,precacheLaser,0,0,0,fLife,width,width,10,0.0,color,10);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
		
		TE_SetupBeamPoints(fRightBottomFront,righttopfront,precacheLaser,0,0,0,fLife,width,width,10,0.0,color,10);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
		TE_SetupBeamPoints(fLeftBottomBack,fLeftTopBack,precacheLaser,0,0,0,fLife,width,width,10,0.0,color,10);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
	}
}

/***********************************************************/
/********************** CLEAR TIMER ************************/
/***********************************************************/
stock void ClearTimer(Handle &timer)
{
    if (timer != INVALID_HANDLE)
    {
        KillTimer(timer);
        timer = INVALID_HANDLE;
    }     
}