#pragma semicolon 1

#include <sourcemod>
#include <timer>
#include <timer-config_loader>

public Plugin:myinfo =
{
    name        = "[TIMER] Physicsinfo",
    author      = "Zipcore, DR. API Improvements",
    description = "[Timer] Show details for all styles",
    version     = PL_VERSION,
    url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
	LoadTranslations("drapi/drapi_timer-physics_info.phrases");
	RegConsoleCmd("sm_styleinfo", Command_Info);
	
	LoadPhysics();
}

public OnMapStart()
{
	LoadPhysics();
}

public Action:Command_Info(client, args) 
{
	if(IsClientConnected(client) && IsClientInGame(client))
	{
		CreateInfoMenu(client);
	}
	return Plugin_Handled;
}

CreateInfoMenu(client)
{
	if(0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(MenuHandler_Info);

		char title[256];
		Format(title, sizeof(title), "%T", "StyleMenuTitle", client);
		SetMenuTitle(menu, title, client);
		
		SetMenuExitButton(menu, true);

		for(new i = 0; i < MAX_STYLES-1; i++) 
		{
			if(!g_Physics[i][StyleEnable])
				continue;
			
			new String:buffer[8];
			IntToString(i, buffer, sizeof(buffer));
				
			AddMenuItem(menu, buffer, g_Physics[i][StyleName]);
		}	

		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public MenuHandler_Info(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select) 
	{
		decl String:info[8];		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		CreateInfoDetailMenu(client, StringToInt(info));
	}
}

CreateInfoDetailMenu(client, style)
{
	if(0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(MenuHandler_InfoDetail);

		char title[256];
		Format(title, sizeof(title), "%T", "SettingsMenuTitle", client, g_Physics[style][StyleName]);
		SetMenuTitle(menu, title);
		
		SetMenuExitButton(menu, true);

		new String:buffer[8];
		new String:bigbuffer[64];
		IntToString(style, buffer, sizeof(buffer));
		
		if(g_Physics[style][StyleIsDefault]) 
		{
			FormatEx(bigbuffer, sizeof(bigbuffer), "%T", "Default Mode", client);
			AddMenuItem(menu, buffer, bigbuffer);
		}
		
		FormatEx(bigbuffer, sizeof(bigbuffer), "%T", "ChatCommand", client, g_Physics[style][StyleQuickCommand]);
		AddMenuItem(menu, buffer, bigbuffer);
		
		if(g_Physics[style][StyleCategory] == MCategory_Fun) 
		{
			FormatEx(bigbuffer, sizeof(bigbuffer), "%T", "Category: Fun", client);
		}
		else if(g_Physics[style][StyleCategory] == MCategory_Ranked) 
		{
			FormatEx(bigbuffer, sizeof(bigbuffer), "%T", "Category: Ranked", client);
		}
		else if(g_Physics[style][StyleCategory] == MCategory_Practise) 
		{
			FormatEx(bigbuffer, sizeof(bigbuffer), "%T", "Category: Practise", client);
		}
		else 
		{
			FormatEx(bigbuffer, sizeof(bigbuffer), "%T", "Category: Unknown", client);
		}
		AddMenuItem(menu, buffer, bigbuffer);
		
		FormatEx(bigbuffer, sizeof(bigbuffer), "%T", "Boost", client, g_Physics[style][StyleBoost]);
		AddMenuItem(menu, buffer, bigbuffer);
		
		if(g_Physics[style][StyleAuto]) 
		{
			FormatEx(bigbuffer, sizeof(bigbuffer), "%T", "Auto: Enabled", client);
		}
		else 
		{
			FormatEx(bigbuffer, sizeof(bigbuffer), "Auto: Disabled", client);
		}
		AddMenuItem(menu, buffer, bigbuffer);
		
		FormatEx(bigbuffer, sizeof(bigbuffer), "%T", "Stamina", client, g_Physics[style][StyleStamina]);
		AddMenuItem(menu, buffer, bigbuffer);
		
		FormatEx(bigbuffer, sizeof(bigbuffer), "%T", "Gravity", client, g_Physics[style][StyleGravity]);
		AddMenuItem(menu, buffer, bigbuffer);
		
		if(g_Physics[style][StyleBlockPreSpeeding] > 0.0) 
		{
			FormatEx(bigbuffer, sizeof(bigbuffer), "%T", "PrespeedMax", client, g_Physics[style][StyleBlockPreSpeeding]);
		}
		else 
		{
			FormatEx(bigbuffer, sizeof(bigbuffer), "%T", "PrespeedMax: Unlimited", client);
		}
		AddMenuItem(menu, buffer, bigbuffer);
		
		if(g_Physics[style][StyleMultiBhop] == 0) 
		{
			FormatEx(bigbuffer, sizeof(bigbuffer), "%T", "Multimode: Map Default", client);
		}
		else if(g_Physics[style][StyleMultiBhop] == 1) 
		{
			FormatEx(bigbuffer, sizeof(bigbuffer), "%T", "Multimode: Multihop", client);
		}
		else if(g_Physics[style][StyleMultiBhop] == 2) 
		{
			FormatEx(bigbuffer, sizeof(bigbuffer), "%T", "Multimode: Nohop", client);
		}
		else 
		{
			FormatEx(bigbuffer, sizeof(bigbuffer), "%T", "Multimode: Unknown", client);
		}
		AddMenuItem(menu, buffer, bigbuffer);

		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public MenuHandler_InfoDetail(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_End) 
	{
		CloseHandle(menu);
		CreateInfoMenu(client);
	}
	else if (action == MenuAction_Select) 
	{
		decl String:info[8];		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		CreateInfoDetailMenu(client, StringToInt(info));
	}
}