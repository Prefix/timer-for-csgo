#pragma semicolon 1

#include <sourcemod>
#include <timer>
#include <timer-mapzones>
#include <timer-config_loader>

public Plugin:myinfo =
{
	name        = "[TIMER] Main Menu",
	author      = "Zipcore, DR. API Improvements",
	description = "Main menu component for [Timer]",
	version     = PL_VERSION,
	url         = "zipcore#googlemail.com"
};

new GameMod:mod;
new String:g_sCurrentMap[PLATFORM_MAX_PATH];


public OnPluginStart()
{
	LoadTranslations("drapi/drapi_timer-menu.phrases");
	LoadPhysics();
	LoadTimerSettings();
	
	RegConsoleCmd("sm_menu", Command_Menu);	
	RegConsoleCmd("sm_timer", Command_HelpMenu);
	RegConsoleCmd("sm_help", Command_HelpMenu);
	RegConsoleCmd("sm_commands", Command_HelpMenu);
	
	mod = GetGameMod();
}

public OnMapStart()
{
	LoadPhysics();
	LoadTimerSettings();
	
	GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));
}

public Action:Command_Menu(client, args)
{
	if(!Timer_IsEnabled()) return Plugin_Continue;
	MenuEx(client);
	
	return Plugin_Handled;
}

enum eCommand
{
String:eCommand_Info[512],
String:eCommand_Plugin[512],
}

new commandsperpage = 7;
new g_iCmdCount = 0;
new g_Commands[512][eCommand];
new g_iCurrentPage[MAXPLAYERS+1];
new maxpage;

public Action:Command_HelpMenu(client, args)
{
	if(!Timer_IsEnabled()) return Plugin_Continue;
	//HelpPanel(client);
	Init_Commands();
	g_iCurrentPage[client] = 1;
	CommandPanel(client);
	
	return Plugin_Handled;
}

public OnMapZonesLoaded()
{
	// If map has start and end.
	if(Timer_GetMapzoneCount(ZtStart) == 0 || Timer_GetMapzoneCount(ZtEnd) == 0) {
		//SetFailState("MapZones start and end points not found! Disabling!");
		
	}
}

public Init_Commands()
{
	if(!Timer_IsEnabled()) return;
	g_iCmdCount = 0;
	
	Add_Command("!timer", "timer-core.smx");
	Add_Command("!menu", "timer-menu.smx");
	Add_Command("!style", "timer-physics.smx");
	Add_Command("!start", "timer-mapzones.smx");
	Add_Command("!restart", "timer-mapzones.smx");
	Add_Command("!bonusstart", "timer-mapzones.smx");
	Add_Command("!pause", "timer-core.smx", g_Settings[PauseEnable]);
	Add_Command("!resume", "timer-core.smx", g_Settings[PauseEnable]);
	Add_Command("!tauto", "timer-physics");
	Add_Command("!stage", "timer-core.smx", g_Settings[LevelTeleportEnable]);
	Add_Command("!tpto", "timer-teleme.smx", g_Settings[PlayerTeleportEnable]);
	Add_Command("!stuck", "timer-mapzones.smx", g_Settings[PlayerTeleportEnable]);
	Add_Command("!hide", "timer-hide.smx");
	Add_Command("!nc", "timer-mapzones.smx", g_Settings[NoclipEnable]);
	Add_Command("!hud", "timer-hud.smx");
	Add_Command("!challenge", "timer-teams.smx", g_Settings[ChallengeEnable]);
	Add_Command("!coop", "timer-teams.smx", g_Settings[CoopEnable]);
	Add_Command("!rank", "timer-worldrecord.smx");
	Add_Command("!top", "timer-worldrecord.smx");
	Add_Command("!btop", "timer-worldrecord.smx");
	Add_Command("!mtop", "timer-worldrecord_maptop.smx");
	Add_Command("!mbtop", "timer-worldrecord_maptop.smx");
	Add_Command("!ranks", "timer-rankings.smx");
	Add_Command("!next", "timer-rankings.smx");
	Add_Command("!prank", "timer-rankings.smx");
	Add_Command("!ptop", "timer-rankings.smx");
	Add_Command("!points", "timer-rankings.smx");
	Add_Command("!latest", "timer-worldrecord_latest.smx");
	Add_Command("!playerinfo", "timer-worldrecord_playerinfo.smx");
	Add_Command("!playerinfo2", "timer-worldrecord_playerinfo.smx");
	Add_Command("!styleinfo", "timer-physics_info.smx");
	Add_Command("!mapinfo", "timer-mapinfo.smx");
	Add_Command("!spec", "timer-spec.smx");
	Add_Command("!specfar", "timer-spec.smx");
	Add_Command("!specmost", "timer-spec.smx");
	Add_Command("!speclist", "timer-spec.smx");
	Add_Command("!georank", "timer-rankings_georank.smx");
}

Add_Command(String:info[], String:plugin[], bool:enable = true)
{
	if(!Timer_IsEnabled()) return;
	if(enable && PluginEnabled(plugin))
	{
		Format(g_Commands[g_iCmdCount][eCommand_Info], 512, "%s", info);
		Format(g_Commands[g_iCmdCount][eCommand_Plugin], 512, "%s", plugin);
		g_iCmdCount++;
		maxpage = RoundToCeil(float(g_iCmdCount)/float(commandsperpage));
	}
}

public CommandPanel(client)
{
	if(!Timer_IsEnabled()) return;
	new firstcomand = g_iCurrentPage[client]*commandsperpage-commandsperpage;
	
	new Handle:panel = CreatePanel();
	char title[256];
	Format(title, sizeof(title), "%T", "MenuTitle", client);
	SetPanelTitle(panel, title);
	
	new String:buffer[512];
	new iCmdCount;
	for(new i=firstcomand; i < (g_iCurrentPage[client]*commandsperpage); i++)
	{
		Format(buffer, sizeof(buffer), "%T", g_Commands[i][eCommand_Info], client);
		DrawPanelText(panel, buffer);
		iCmdCount++;
	}
	
	DrawPanelText(panel, " ");
	
	
	new startkey = 8;
	if(g_iCurrentPage[client] > 1)
	startkey = 7;
	
	//Fix CS:GO menu buttons
	if(mod == MOD_CSGO) SetPanelCurrentKey(panel, startkey);
	else SetPanelCurrentKey(panel, startkey+1);
	
	if(g_iCurrentPage[client] > 1)
	{
		char back[256];
		Format(back, sizeof(back), "%T", "back", client);
		DrawPanelItem(panel, back);
	}
	else 
	{
		DrawPanelText(panel, " ");
	}
	
	if(g_iCurrentPage[client] < maxpage) 
	{
		char next[256];
		Format(next, sizeof(next), "%T", "next", client);
		DrawPanelItem(panel, next);
	}
	else 
	{
		DrawPanelText(panel, " ");
	}
	
	char sexit[256];
	Format(sexit, sizeof(sexit), "%T", "exit", client);
	DrawPanelItem(panel, sexit);
	
	SendPanelToClient(panel, client, CommandPanelHandler, MENU_TIME_FOREVER);

	CloseHandle(panel);
}

public CommandPanelHandler (Handle:menu, MenuAction:action,client, param2)
{
	if(!Timer_IsEnabled()) return;
	if ( action == MenuAction_Select )
	{
		if(mod == MOD_CSGO) 
		{
			switch (param2)
			{
			case 7:
				{
					if(g_iCurrentPage[client] > 1)
					g_iCurrentPage[client]--;
					CommandPanel(client);
				}
			case 8:
				{
					if(g_iCurrentPage[client] < maxpage)
					g_iCurrentPage[client]++;
					CommandPanel(client);
				}
			}
		}
		else
		{
			switch (param2)
			{
			case 8:
				{
					if(g_iCurrentPage[client] > 1)
					g_iCurrentPage[client]--;
					CommandPanel(client);
				}
			case 9:
				{
					if(g_iCurrentPage[client] < maxpage)
					g_iCurrentPage[client]++;
					CommandPanel(client);
				}
			}
		}
	}
}

MenuEx(client)
{
	if(!Timer_IsEnabled()) return;
	if (0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(Handle_Menu);
		char title[256];
		Format(title, sizeof(title), "%T", "MainMenuTitle", client);
		SetMenuTitle(menu, title);		
		
		char style[256];
		Format(style, sizeof(style), "%T", "Style", client);
		AddMenuItem(menu, "mode", style);	
		
		if(PluginEnabled("timer-physics_info.smx"))
		{
			char styleinfo[256];
			Format(styleinfo, sizeof(styleinfo), "%T", "Styleinfo", client);
			AddMenuItem(menu, "info", styleinfo);
		}
		if(g_Settings[ChallengeEnable])
		{
			char challenge[256];
			Format(challenge, sizeof(challenge), "%T", "Challenge", client);
			AddMenuItem(menu, "challenge", challenge);
		}
		if(PluginEnabled("timer-cpmod.smx") || g_Settings[LevelTeleportEnable] || g_Settings[PlayerTeleportEnable])
		{
			char tele[256];
			Format(tele, sizeof(tele), "%T", "Teleport", client);
			AddMenuItem(menu, "tele", tele);
		}
		
		char wrm[256];
		Format(wrm, sizeof(wrm), "%T", "World Record Menu", client);
		AddMenuItem(menu, "wrm", wrm);
		
		if(PluginEnabled("timer-hud_csgo.smx"))
		{
			char hud[256];
			Format(hud, sizeof(hud), "%T", "HUD", client);
			AddMenuItem(menu, "hud", "Custom HUD Settings");
		}
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public Handle_Menu(Handle:menu, MenuAction:action, client, itemNum)
{
	if(!Timer_IsEnabled()) return;
	if ( action == MenuAction_Select )
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		if(found)
		{
			if(StrEqual(info, "mode"))
			{
				FakeClientCommand(client, "sm_style");
			}
			else if(StrEqual(info, "info"))
			{
				FakeClientCommand(client, "sm_styleinfo");
			}
			else if(StrEqual(info, "wrm"))
			{
				WorldRecordMenu(client);
			}
			else if(StrEqual(info, "tele"))
			{
				TeleportMenu(client);
			}
			else if(StrEqual(info, "challenge"))
			{
				if(IsClientInGame(client)) FakeClientCommand(client, "sm_challenge"); 
			}
			else if(StrEqual(info, "hud"))
			{
				if(IsClientInGame(client)) FakeClientCommand(client, "sm_hud"); 
			}
		}
	}
}

WorldRecordMenu(client)
{
	if(!Timer_IsEnabled()) return;
	if (0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(Handle_WorldRecordMenu);
		
		char title[256];
		Format(title, sizeof(title), "%T", "WRMenuTitle", client);
		SetMenuTitle(menu, title);
		
		char wr[256];
		Format(wr, sizeof(wr), "%T", "WR", client);
		AddMenuItem(menu, "wr", wr);
		
		char bwr[256];
		Format(bwr, sizeof(bwr), "%T", "BWR", client);
		AddMenuItem(menu, "bwr", bwr);
		
		char main[256];
		Format(main, sizeof(main), "%T", "Main", client);
		AddMenuItem(menu, "main", main);
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public Handle_WorldRecordMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if(!Timer_IsEnabled()) return;
	if ( action == MenuAction_Select )
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		if(found)
		{
			if(StrEqual(info, "wr"))
			{
				FakeClientCommand(client, "sm_top");
			}
			else if(StrEqual(info, "bwr"))
			{
				FakeClientCommand(client, "sm_btop");
			}
			else if(StrEqual(info, "main"))
			{
				FakeClientCommand(client, "sm_menu");
			}
		}
	}
}

TeleportMenu(client)
{
	if(!Timer_IsEnabled()) return;
	if (0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(Handle_TeleportMenu);
		
		char title[256];
		Format(title, sizeof(title), "%T", "TPMenuTitle", client);
		SetMenuTitle(menu, title);
		
		if(g_Settings[PlayerTeleportEnable])
		{
			char teleme[256];
			Format(teleme, sizeof(teleme), "%T", "Teleme", client);
			AddMenuItem(menu, "teleme", teleme);
		}
		if(g_Settings[LevelTeleportEnable])
		{
			char levels[256];
			Format(levels, sizeof(levels), "%T", "Levels", client);
			AddMenuItem(menu, "levels", levels);
		}
		if(PluginEnabled("timer-cpmod.smx"))
		{
			char checkpoint[256];
			Format(checkpoint, sizeof(checkpoint), "%T", "Checkpoints", client);
			AddMenuItem(menu, "checkpoint", checkpoint);
		}
		
		char main[256];
		Format(main, sizeof(main), "%T", "Main", client);
		AddMenuItem(menu, "main", main);
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public Handle_TeleportMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if(!Timer_IsEnabled()) return;
	if ( action == MenuAction_Select )
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		if(found)
		{
			if(StrEqual(info, "teleme"))
			{
				FakeClientCommand(client, "sm_tpto");
			}
			else if(StrEqual(info, "levels"))
			{
				FakeClientCommand(client, "sm_stage");
			}
			else if(StrEqual(info, "checkpoint"))
			{
				FakeClientCommand(client, "sm_cphelp");
			}
			else if(StrEqual(info, "main"))
			{
				FakeClientCommand(client, "sm_menu");
			}
		}
	}
}

bool:PluginEnabled(const String:pluginNane[])
{
	decl String: pluginPath[PLATFORM_MAX_PATH + 1];
	BuildPath(Path_SM, pluginPath, sizeof(pluginPath), "plugins/%s", pluginNane);
	if(FileExists(pluginPath))
	{
		return true;
	}
	return false;
}
