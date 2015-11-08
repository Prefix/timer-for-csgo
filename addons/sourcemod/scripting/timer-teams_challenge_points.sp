#include <sourcemod>
#include <timer>
#include <timer-physics>
#include <timer-teams>
#include <timer-rankings>

new g_iBet[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "[TIMER] Challenge Points Lite",
	author = "Zipcore, DR. API Improvements",
	description = "[Timer] Take points from looser on challenge win and give them to winner",
    version     = PL_VERSION,
    url         = "forums.alliedmods.net/showthread.php?p=2074699"
}

/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	LoadTranslations("drapi/drapi_timer-teams_challenge_points.phrases");
}

public OnChallengeConfirm(client, mate, bet)
{
	g_iBet[client] = bet;
	g_iBet[mate] = bet;
	CPrintToChatAll("%t", "Confirmed", client, mate, g_iBet[mate]);
}

public OnChallengeWin(winner, loser)
{
	Timer_AddPoints(winner, g_iBet[winner]);
	Timer_SavePoints(winner);
	Timer_RemovePoints(loser, g_iBet[winner]);
	Timer_SavePoints(loser);
	CPrintToChatAll("%t", "Beaten", winner, loser, g_iBet[winner]);
}

public int OnChallengeForceEnd(int winner, int loser, int reason)
{
	if(reason == 1)
	{
		Timer_RemovePoints(loser, g_iBet[winner]);
		Timer_SavePoints(loser);
		CPrintToChatAll("%t", "ForceEnd", winner, loser, g_iBet[winner]);
	}
}