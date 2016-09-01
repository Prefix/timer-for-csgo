#pragma semicolon 1
 
#include <sourcemod>
#include <sdktools>
#include <timer>
#include <timer-stocks>
#include <timer-mapzones>

new bool:enabled = true;
 
public Plugin:myinfo =
{
	name        = "[Timer] Auto lower case commands",
	author      = "Zipcore, DR. API Improvements",
	description = "Auto. converts chat triggers to lower case.",
	version     = PL_VERSION,
	url         = "forums.alliedmods.net/showthread.php?p=2074699"
};
 
public OnPluginStart()
{
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_SayTeam, "say_team");
}

public OnMapZonesLoaded()
{
	// If map has start and end.
	if(Timer_GetMapzoneCount(ZtStart) == 0 || Timer_GetMapzoneCount(ZtEnd) == 0) {
		//SetFailState("MapZones start and end points not found! Disabling!");
		enabled = false;
	}
}

public Action:Command_Say(client, const String:command[], argc)
{
	if(!enabled) return Plugin_Continue;
	
	decl String:sText[300];
	GetCmdArgString(sText, sizeof(sText));
	StripQuotes(sText);
	
	if((sText[0] == '!') || (sText[0] == '/'))
	{
		if(IsCharUpper(sText[1]))
		{
			for(new i = 0; i <= strlen(sText); ++i)
			{
				sText[i] = CharToLower(sText[i]);
			}

			FakeClientCommand(client, "say %s", sText);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}
 
public Action:Command_SayTeam(client, const String:command[], argc)
{
	if(!enabled) return Plugin_Continue;
	decl String:sText[300];
	GetCmdArgString(sText, sizeof(sText));
	StripQuotes(sText);
	
	if((sText[0] == '!') || (sText[0] == '/'))
	{
		if(IsCharUpper(sText[1]))
		{
			for(new i = 0; i <= strlen(sText); ++i)
			{
				sText[i] = CharToLower(sText[i]);
			}

			FakeClientCommand(client, "say_team %s", sText);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}