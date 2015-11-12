#pragma semicolon 1

#define PLUGIN_NAME "[TIMER] Trigger_push fix"
#define PLUGIN_AUTHOR ""
#define PLUGIN_DESCRIPTION "[TIMER] Trigger_push fix"
#define PLUGIN_URL "http://www.houseofclimb.com"

#define CHAT_TAG ""

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <timer>

new Float:g_flVecPushDir[2048][3];
new Float:g_flPushSpeed[2048];
new g_nFilterEntity[2048];
new bool:g_bEnableTrigger[MAXPLAYERS+1][2048];

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PL_VERSION,
	url = PLUGIN_URL
};

public OnMapStart()
{
	new String:m_szClassname[64];
	for(new i=MaxClients+1;i<2048;++i)
	{
		if(IsValidEdict(i))
		{
			GetEdictClassname(i, m_szClassname, sizeof(m_szClassname));
			if(StrContains(m_szClassname, "trigger_push")!=-1)
			{
				CreateTrigger(i);
			}
		}
	}
}

public CreateTrigger(src)
{
	new Float:m_flPosition[3];
	new Float:m_flDirection[3];
	new Float:m_flAngles[3];
	new Float:m_flMins[3];
	new Float:m_flMaxs[3];

	GetEntPropVector(src, Prop_Data, "m_vecPushDir", m_flDirection);
	if(m_flDirection[2]<0.5)
		return -1;

	new ent = CreateEntityByName("trigger_multiple");
	if (ent == -1) return -1;

	GetEntPropVector(src, Prop_Send, "m_vecOrigin", m_flPosition);
	GetEntPropVector(src, Prop_Data, "m_angAbsRotation", m_flAngles);
	GetEntPropVector(src, Prop_Send, "m_vecMins", m_flMins);
	GetEntPropVector(src, Prop_Send, "m_vecMaxs", m_flMaxs);

	GetEntPropVector(src, Prop_Data, "m_vecPushDir", g_flVecPushDir[ent]);
	g_flPushSpeed[ent] = GetEntPropFloat(src, Prop_Data, "m_flSpeed");
	g_nFilterEntity[ent] = GetEntPropEnt(src, Prop_Data, "m_hFilter");

	DispatchKeyValue(ent, "StartDisabled", "1");
	DispatchKeyValue(ent, "spawnflags", "1");

	TeleportEntity(ent, m_flPosition, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(ent);

	SetEntityModel(ent, "models/chicken/chicken.mdl");
	SetEntPropVector(ent, Prop_Send, "m_vecMins", m_flMins);
	SetEntPropVector(ent, Prop_Send, "m_vecMaxs", m_flMaxs);
	SetEntProp(ent, Prop_Send, "m_nSolidType", 2);
	SetEntProp(ent, Prop_Send, "m_fEffects", GetEntProp(ent, Prop_Send, "m_fEffects") | 32);


	if(g_nFilterEntity[ent] != -1)
	{
		HookSingleEntityOutput(g_nFilterEntity[ent], "OnPass", OnFilterPass);
		HookSingleEntityOutput(g_nFilterEntity[ent], "OnFail", OnFilterFail);
	}

	AcceptEntityInput(ent, "Enable");
	AcceptEntityInput(src, "Disable");

	SDKHook(ent, SDKHook_Touch, Touching);

	return ent;
}

public OnFilterPass(const String:output[], caller, activator, Float:delay)
{
	for(new i=0;i<2048;++i)
		if(g_nFilterEntity[i]==caller)
			g_bEnableTrigger[activator][i] = true;
}

public OnFilterFail(const String:output[], caller, activator, Float:delay)
{
	for(new i=0;i<2048;++i)
		if(g_nFilterEntity[i]==caller)
			g_bEnableTrigger[activator][i] = false;
}

public Touching(ent, other)
{
	new MoveType:m_MoveType = GetEntityMoveType(other);
	switch(m_MoveType)
	{
		case MOVETYPE_NONE,
			 MOVETYPE_PUSH,
			 MOVETYPE_NOCLIP,
			 MOVETYPE_LADDER:
		{

		}

		case MOVETYPE_VPHYSICS:
		{
			// Not implemented
		}

		default:
		{
			if(g_nFilterEntity[ent] != -1)
				AcceptEntityInput(g_nFilterEntity[ent], "TestActivator", other);
			else
				g_bEnableTrigger[other][ent]=true;

			if(g_bEnableTrigger[other][ent])
			{
				new Float:m_vecPush[3];
				new Float:m_vecAbs[3];
				GetEntPropVector(other, Prop_Data, "m_vecAbsVelocity", m_vecAbs);

				m_vecPush[0]=g_flVecPushDir[ent][0]*0.0075;
				m_vecPush[1]=g_flVecPushDir[ent][1]*0.0075;
				m_vecPush[2]=g_flVecPushDir[ent][2]*0.0075;
				ScaleVector(m_vecPush, g_flPushSpeed[ent]);

				if(GetEdictFlags(other) & FL_BASEVELOCITY)
				{
					new Float:m_vecBaseVel[3];
					GetEntPropVector(other, Prop_Data, "m_vecBaseVelocity", m_vecBaseVel);
					AddVectors(m_vecPush, m_vecBaseVel, m_vecPush);
				}

				SetEntPropVector(other, Prop_Data, "m_vecBaseVelocity", m_vecPush);
				SetEdictFlags(other, (GetEdictFlags(other) | FL_BASEVELOCITY) &~ FL_ONGROUND);
			}
		}
	}
}