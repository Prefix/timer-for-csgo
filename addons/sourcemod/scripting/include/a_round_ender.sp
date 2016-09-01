// Includes
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <spawntools>

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

public void OnPluginStart()
{
	// ConVars
	gcv_bPluginEnabled = FindConVar("mp_ignore_round_win_conditions");

	// Command Listeners
	AddCommandListener(JoinTeam, "jointeam");

	// Hooks
	HookEvent("player_death", Event_PlayerDeath);
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

public Action JoinTeam(int client, char[] command, int args)  
{
	if (!IsValidClient(client)) { return Plugin_Continue; }
	
	char sTeamName[4];
	GetCmdArg(1, sTeamName, sizeof(sTeamName)) ;
	
	int iTeam = StringToInt(sTeamName);
	int cTeam = GetClientTeam(client);
	
	if (iTeam == cTeam) { return Plugin_Continue; }
	
	if(iTeam == CS_TEAM_SPECTATOR) {
		ChangeClientTeam(client, iTeam);
		return Plugin_Handled;
	} else if (iTeam != CS_TEAM_SPECTATOR && GetSpawnPoints(iTeam) > 0) {
		int oTeam = GetOtherTeam(iTeam);
		if (GetClientTeamCount(iTeam) <= GetClientTeamCount(oTeam)) {
			ChangeClientTeam(client, GetOtherTeam(iTeam));
		}
		return Plugin_Handled;
	} else if (cTeam == CS_TEAM_SPECTATOR && (iTeam == CS_TEAM_CT || iTeam == CS_TEAM_T)) {
		if (GetSpawnPoints(iTeam) > GetClientTeamCount(iTeam)) {
			int oTeam = GetOtherTeam(iTeam);
			if (GetClientTeamCount(iTeam) <= GetClientTeamCount(oTeam)) {
				ChangeClientTeam(client, iTeam);
				return Plugin_Handled;
			}
		}
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
	return Plugin_Continue;
}

public Action Event_PlayerDeath(Handle hEvent, const char[] sName, bool bDontBroadcast)
{
	if (FindConVar("mp_ignore_round_win_conditions").IntValue == 1) return Plugin_Continue;
	
	if (GetClientAliveCount() == 0)
	{
		CS_TerminateRound(5.0, CSRoundEnd_Draw, true);
	}
	else if ((GetClientAliveTeamCount(CS_TEAM_T) == 0 && GetClientAliveTeamCount(CS_TEAM_CT) > 0) && g_iTSpawns > 0)
	{
		CS_TerminateRound(5.0, CSRoundEnd_CTWin, true);
	}
	else if ((GetClientAliveTeamCount(CS_TEAM_CT) == 0 && GetClientAliveTeamCount(CS_TEAM_T) > 0) && g_iCTSpawns > 0)
	{
		CS_TerminateRound(5.0, CSRoundEnd_TerroristWin, true);
	}
	return Plugin_Continue;
}

/**************************************************************
************************* STOCKS ******************************
***************************************************************/

stock int GetClientAliveCount()
{
	int iAmmount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
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
		if (IsValidClient(i) && GetClientTeam(i) == iTeam)
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
		if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == iTeam)
		{
			iAmmount++;
		}
	}
	return iAmmount;
}

stock bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}