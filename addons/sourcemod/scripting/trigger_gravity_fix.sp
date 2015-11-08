#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <smlib>
#include <timer>

public Plugin:myinfo =
{
	name = "[TIMER] Trigger_gravity fix",
	author = "",
	description = "[TIMER] Trigger_gravity fix",
	version = PL_VERSION,
	url = ""
};

new Handle:g_hSDK_Touch = INVALID_HANDLE;

new Handle:g_hTimer[MAXPLAYERS + 1][2048];

public OnPluginStart()
{
	new Handle:hGameConf = INVALID_HANDLE;
	hGameConf = LoadGameConfigFile("sdkhooks.games");
	if(hGameConf == INVALID_HANDLE) 
	{
		SetFailState("GameConfigFile sdkhooks.games was not found");
		return;
	}
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf,SDKConf_Virtual,"Touch");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity,SDKPass_Pointer);
	g_hSDK_Touch = EndPrepSDKCall();
	CloseHandle(hGameConf);

	if(g_hSDK_Touch == INVALID_HANDLE) 
	{
		SetFailState("Unable to prepare virtual function CBaseEntity::Touch");
		return;
	}
	
	for (new client = 1; client <= MaxClients; client++)
	{
		for (new entity = MaxClients; entity < 2048; entity++)
		{
			g_hTimer[client][entity] = INVALID_HANDLE;
		}
	}
}

Client_FakeTouchEntity(entity, client)
{
	SDKCall(g_hSDK_Touch, entity, client);
}

public OnMapStart()
{
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "trigger_multiple")) != -1)
	{
		SDKHook(entity, SDKHook_StartTouch,  StartTouchTrigger);
		SDKHook(entity, SDKHook_EndTouch, EndTouchTrigger);
	}
}

public Action:StartTouchTrigger(entity, client)
{
	if (client < 1 || client > MaxClients)
		return;

	if (!IsClientInGame(client))
		return;

	if (!IsPlayerAlive(client))
		return;
		
	StartTimer(client, entity);
		
	Client_FakeTouchEntity(entity, client);
}

public Action:EndTouchTrigger(entity, client)
{
	if (client < 1 || client > MaxClients)
		return;

	if (!IsClientInGame(client))
		return;
	
	StopTimer(client, entity);
}

public Action:Timer_Touch(Handle:timer, any:data)
{	
	ResetPack(data);
	new client = ReadPackCell(data);
	new entity = ReadPackCell(data);
	CloseHandle(data);
	
	if (IsClientInGame(client))
	{
		Client_FakeTouchEntity(entity, client);
		StartTimer(client, entity);
	}
	else ResetTimer(client, entity);
		
	return Plugin_Stop;
}

StartTimer(client, entity)
{
	StopTimer(client, entity);
	
	new Handle:data = CreateDataPack();
	
	g_hTimer[client][entity] = CreateTimer(0.1, Timer_Touch, data);
	
	WritePackCell(data, client);
	WritePackCell(data, entity);
}

ResetTimer(client, entity)
{
	g_hTimer[client][entity] = INVALID_HANDLE;
}

StopTimer(client, entity)
{
	if(g_hTimer[client][entity] == INVALID_HANDLE)
		return;
		
	KillTimer(g_hTimer[client][entity]);
	g_hTimer[client][entity] = INVALID_HANDLE;
}