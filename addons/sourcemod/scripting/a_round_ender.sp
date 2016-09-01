// Includes
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <spawntools>
#include <timer-mapzones>

// Compiler Settings
#pragma newdecls required
#pragma semicolon 1

// ConVars
ConVar gcv_bPluginEnabled;

int g_iTSpawns;
int g_iCTSpawns;

public Plugin myinfo =
{
	name = "[CS:GO] Round Ender",
	author = "Prefix",
	description = "A plugin designed to end rounds when they are supposed to.",
	version = "1.0",
	url = ""
};

public void OnClientPutInServer(int client) {
	if (client && !IsFakeClient(client)) 
	CreateTimer(3.0, Timer_JoinGame, client);
}

public Action Timer_JoinGame(Handle timer, any client)
{
	if (!IsClientInGame(client)) return;

	FakeClientCommand(client, "joingame");
	SwitchToTeam(client, CS_TEAM_CT);
}

public void OnPluginStart()
{
	// Command Listeners
	AddCommandListener(JoinTeam, "jointeam");
	//AddCommandListener(JoinGame, "joingame");
	AddCommandListener(TeamMenu, "teammenu");

	// Hooks
	HookEvent("player_death", Event_PlayerDeath);
	
	RegConsoleCmd("sm_spawntest", Command_Test);
}


public Action Command_Test(int client, int args) {
	char full[256];
	GetCmdArgString(full, sizeof(full));
	int ff = StringToInt(full);
	PrintToChat(client, "Yra spawnu: %d", spawntools_spawncount(ff));
	return Plugin_Handled;
}

public void OnMapStart()
{
	g_iTSpawns=-1;
	g_iCTSpawns=-1;

	// Give plugins a chance to create new spawns
	CreateTimer(0.1, Timer_OnMapStart);
}

public Action Timer_OnMapStart(Handle timer, any data)
{
	g_iTSpawns = spawntools_spawncount(CS_TEAM_T);
	g_iCTSpawns = spawntools_spawncount(CS_TEAM_T);
	
	return Plugin_Stop;
}

public int GetOtherTeam(int team) {
	if(team == CS_TEAM_CT) {
		return CS_TEAM_T;
	} else {
		return CS_TEAM_CT;
	}
}

public int GetSpawnPoints(int team) {
	return spawntools_spawncount(team);
}

public Action JoinGame(int client, char[] command, int args)  {
	return Plugin_Handled;
}

public void SwitchToTeam(int client, int iTeam) {
	int oTeam = GetOtherTeam(iTeam);
	if(GetSpawnPoints(iTeam) > 0) {
		if (FindConVar("mp_limitteams").IntValue == 0) {
			ChangeClientTeam(client, iTeam);
			if(Timer_GetMapzoneCount(ZtStart) > 0 && Timer_GetMapzoneCount(ZtEnd) > 0) {
				CS_RespawnPlayer(client);
			}
		} else {
			if (GetClientTeamCount(iTeam) <= GetClientTeamCount(oTeam)) {
				ChangeClientTeam(client, iTeam);
			} else {
				ChangeClientTeam(client, oTeam);
			}
		}
	} else {
		ChangeClientTeam(client, oTeam);
	}
	
	if (FindConVar("mp_ignore_round_win_conditions").IntValue == 0) {
		if (iTeam == CS_TEAM_CT || iTeam == CS_TEAM_T)
		{
			if (GetClientTeamCount(iTeam) == 0 && GetSpawnPoints(iTeam) > GetClientTeamCount(iTeam))
			{
				CS_TerminateRound(5.0, CSRoundEnd_Draw, true);
			}
		}
	}
}

public Action TeamMenu(int client, char[] command, int args)  
{
	PrintToServer("Teammenu hook");
	if (!IsClientValid(client)) { return Plugin_Continue; }
	
	char sTeamName[4];
	GetCmdArg(1, sTeamName, sizeof(sTeamName)) ;
	
	//int iTeam = StringToInt(sTeamName);
	int iTeam = GetClientTeam(client);
	PrintToChat(client, "Test[1] %d", args);
	//if (iTeam == cTeam) { return Plugin_Continue; }
	
	if(iTeam == CS_TEAM_SPECTATOR) {
		SwitchToTeam(client, CS_TEAM_CT);
		return Plugin_Handled;
	} else if (iTeam == CS_TEAM_CT || iTeam == CS_TEAM_T) {
		ChangeClientTeam(client, CS_TEAM_SPECTATOR);
		return Plugin_Handled;
	}
	
	if (FindConVar("mp_ignore_round_win_conditions").IntValue == 0) {
		if (iTeam == CS_TEAM_CT || iTeam == CS_TEAM_T)
		{
			if (GetClientTeamCount(iTeam) == 0 && GetSpawnPoints(iTeam) > GetClientTeamCount(iTeam))
			{
				CS_TerminateRound(5.0, CSRoundEnd_Draw, true);
			}
		}
	}
	
	CheckToTerminate();
	
	return Plugin_Continue;
}

public Action JoinTeam(int client, char[] command, int args)  
{
	if (!IsClientValid(client)) { return Plugin_Continue; }
	
	char sTeamName[4];
	GetCmdArg(1, sTeamName, sizeof(sTeamName)) ;
	
	int iTeam = StringToInt(sTeamName);
	int cTeam = GetClientTeam(client);
	
	if (iTeam == cTeam) { return Plugin_Continue; }
	
	if(iTeam == CS_TEAM_SPECTATOR) {
		ChangeClientTeam(client, iTeam);
		return Plugin_Handled;
	} else if (iTeam == CS_TEAM_CT || iTeam == CS_TEAM_T) {
		SwitchToTeam(client, iTeam);
		return Plugin_Handled;
	}
	
	if (FindConVar("mp_ignore_round_win_conditions").IntValue == 0) {
		if (iTeam == CS_TEAM_CT || iTeam == CS_TEAM_T)
		{
			if (GetClientTeamCount(iTeam) == 0 && GetSpawnPoints(iTeam) > GetClientTeamCount(iTeam))
			{
				CS_TerminateRound(5.0, CSRoundEnd_Draw, true);
			}
		}
	}
	
	CheckToTerminate();
	
	return Plugin_Continue;
}

public Action Event_PlayerDeath(Handle hEvent, const char[] sName, bool bDontBroadcast)
{
	CheckToTerminate();
	
	return Plugin_Continue;
}

public void CheckToTerminate() {
	
	if (FindConVar("mp_ignore_round_win_conditions").IntValue == 1) return;
	
	if (GetClientAliveCount() == 0)
	{
		CS_TerminateRound(5.0, CSRoundEnd_Draw, true);
	}
	else if ((GetClientAliveTeamCount(CS_TEAM_T) == 0 && GetClientAliveTeamCount(CS_TEAM_CT) > 0) && spawntools_spawncount(CS_TEAM_T) > 0)
	{
		CS_TerminateRound(5.0, CSRoundEnd_CTWin, true);
	}
	else if ((GetClientAliveTeamCount(CS_TEAM_CT) == 0 && GetClientAliveTeamCount(CS_TEAM_T) > 0) && spawntools_spawncount(CS_TEAM_CT) > 0)
	{
		CS_TerminateRound(5.0, CSRoundEnd_TerroristWin, true);
	}
	
}

/**************************************************************
************************* STOCKS ******************************
***************************************************************/

stock int GetClientAliveCount()
{
	int iAmmount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i) && IsPlayerAlive(i))
		{
			iAmmount++;
		}
	}
	return iAmmount;
}

stock int GetClientTeamCount(int iTeam)
{
	int iAmmount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i) && GetClientTeam(i) == iTeam)
		{
			iAmmount++;
		}
	}
	return iAmmount;
}

stock int GetClientAliveTeamCount(int iTeam)
{
	int iAmmount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i) && IsPlayerAlive(i) && GetClientTeam(i) == iTeam)
		{
			iAmmount++;
		}
	}
	return iAmmount;
}
// From TTT plugin
stock bool IsClientValid(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
		return true;
	return false;
}