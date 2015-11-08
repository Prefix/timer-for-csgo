#include <sourcemod>
#include <sdktools>
#include <timer>
#include <timer-logging>
#include <timer-mapzones>

#define MAX_STRAFES 5000

#define STRAFE_A 1
#define STRAFE_D 2
#define STRAFE_W 3
#define STRAFE_S 4

enum PlayerState
{
	bool:bOn,
	nStrafes,
	nStrafesBoosted,
	nStrafeDir,
	Float:fStrafeTimeLastSync[MAX_STRAFES],
	Float:fStrafeTimeAngleTurn[MAX_STRAFES],
	Float:fStrafeDelay[MAX_STRAFES],
	bool:bStrafeAngleGain[MAX_STRAFES],
	bool:bBoosted[MAX_STRAFES]
}

/* Player Stats */
new g_PlayerStates[MAXPLAYERS + 1][PlayerState];
new Float:vLastOrigin[MAXPLAYERS + 1][3];
new Float:vLastAngles[MAXPLAYERS + 1][3];
new Float:vLastVelocity[MAXPLAYERS + 1][3];

new String:g_sCurrentMap[PLATFORM_MAX_PATH];

new Handle:g_hSQL = INVALID_HANDLE;
new g_iSQLReconnectCounter;

public Plugin:myinfo = 
{
	name = "[TIMER] ASH: Anti-Strafe-Hack",
	author = "Zipcore, Credits:Miu",
	description = "Detecting Strafehacks",
	version = PL_VERSION,
	url = "zipcore#googlemail.com"
}

public OnPluginStart()
{
	ConnectSQL();
}

/* Reset/stop strafe stats */
public OnMapStart()
{
	GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));
	
	if (g_hSQL == INVALID_HANDLE)
	{
		ConnectSQL();
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		ResetStrafes(i);
		g_PlayerStates[i][bOn] = false;
	}
}

public OnClientPutInServer(client)
{
	ResetStrafes(client);
	g_PlayerStates[client][bOn] = false;
}

public OnClientStartTouchZoneType(client, MapZoneType:type)
{
	if(!client)
		return;
		
	if (type == ZtEnd)
	{
		g_PlayerStates[client][bOn] = false;
		ComputeStrafes(client);
		ResetStrafes(client);
	}
}

public OnClientEndTouchZoneType(client, MapZoneType:type)
{
	if(!client)
		return;
		
	if (type == ZtStart)
	{
		ResetStrafes(client);
		g_PlayerStates[client][bOn] = true;
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(!g_PlayerStates[client][bOn])
	{
		GetClientAbsOrigin(client, vLastOrigin[client]);
		GetClientAbsAngles(client, vLastAngles[client]);
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vLastVelocity[client]);
		return;
	}
	
	/* Overproduced strafe stats */
	if(g_PlayerStates[client][nStrafes] >= MAX_STRAFES)
	{
		/* Force compute of strafe stats */
		ComputeStrafes(client);
		ResetStrafes(client);
		
		GetClientAbsOrigin(client, vLastOrigin[client]);
		GetClientAbsAngles(client, vLastAngles[client]);
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vLastVelocity[client]);
		return;
	}
	
	new Float:time = GetGameTime();
	
	/* Prepare angle */
	new Float:vAngles[3];
	vAngles[1] = angles[1];
	vAngles[1] += 360;
	
	/* Angle direction */
	new bool:angle_gain;
	if (vLastAngles[client][1] < angles[1])
		angle_gain = true;
	else
		angle_gain = false;
	
	/* Angle changed direction */
	if (g_PlayerStates[client][bStrafeAngleGain][g_PlayerStates[client][nStrafes]] != angle_gain)
	{
		g_PlayerStates[client][bStrafeAngleGain][g_PlayerStates[client][nStrafes]] = angle_gain;
		g_PlayerStates[client][fStrafeTimeAngleTurn][g_PlayerStates[client][nStrafes]] = time;
	}
	
	/* Validate strafe */
	new nButtonCount;
	if(buttons & IN_MOVELEFT)
		nButtonCount++;
	if(buttons & IN_MOVERIGHT)
		nButtonCount++;
	if(buttons & IN_FORWARD)
		nButtonCount++;
	if(buttons & IN_BACK)
		nButtonCount++;
	
	/* Get strafe phase */
	new bool:newstrafe;
	if(nButtonCount == 1)
	{
		/* Start new strafe */
		
		if(g_PlayerStates[client][nStrafeDir] != STRAFE_A && (buttons & IN_MOVELEFT))
		{
			g_PlayerStates[client][nStrafeDir] = STRAFE_A;
			newstrafe = true;
		}
		else if(g_PlayerStates[client][nStrafeDir] != STRAFE_D && (buttons & IN_MOVERIGHT))
		{
			g_PlayerStates[client][nStrafeDir] = STRAFE_D;
			newstrafe = true;
		}
		else if(g_PlayerStates[client][nStrafeDir] != STRAFE_W && (buttons & IN_FORWARD ))
		{
			g_PlayerStates[client][nStrafeDir] = STRAFE_W;
			newstrafe = true;
		}
		else if(g_PlayerStates[client][nStrafeDir] != STRAFE_S && (buttons & IN_BACK))
		{
			g_PlayerStates[client][nStrafeDir] = STRAFE_S;
			newstrafe = true;
		}
		
		else if(g_PlayerStates[client][nStrafeDir] != STRAFE_A && (vel[1] < 0))
		{
			g_PlayerStates[client][nStrafeDir] = STRAFE_A;
			newstrafe = true;
		}
		else if(g_PlayerStates[client][nStrafeDir] != STRAFE_D && (vel[1] > 0))
		{
			g_PlayerStates[client][nStrafeDir] = STRAFE_D;
			newstrafe = true;
		}
		else if(g_PlayerStates[client][nStrafeDir] != STRAFE_W && (vel[0] > 0))
		{
			g_PlayerStates[client][nStrafeDir] = STRAFE_W;
			newstrafe = true;
		}
		else if(g_PlayerStates[client][nStrafeDir] != STRAFE_S && (vel[0] < 0))
		{
			g_PlayerStates[client][nStrafeDir] = STRAFE_S;
			newstrafe = true;
		}
		
		/* Continue strafe */
		
		else if(g_PlayerStates[client][nStrafeDir] == STRAFE_A && (buttons & IN_MOVELEFT))
		{
			g_PlayerStates[client][fStrafeTimeLastSync][g_PlayerStates[client][nStrafes]] = time;
		}
		else if(g_PlayerStates[client][nStrafeDir] == STRAFE_D && (buttons & IN_MOVERIGHT))
		{
			g_PlayerStates[client][fStrafeTimeLastSync][g_PlayerStates[client][nStrafes]] = time;
		}
		else if(g_PlayerStates[client][nStrafeDir] == STRAFE_W && (buttons & IN_FORWARD))
		{
			g_PlayerStates[client][fStrafeTimeLastSync][g_PlayerStates[client][nStrafes]] = time;
		}
		else if(g_PlayerStates[client][nStrafeDir] == STRAFE_S && (buttons & IN_BACK))
		{
			g_PlayerStates[client][fStrafeTimeLastSync][g_PlayerStates[client][nStrafes]] = time;
		}
		
		else if(g_PlayerStates[client][nStrafeDir] == STRAFE_A && (vel[1] < 0))
		{
			g_PlayerStates[client][fStrafeTimeLastSync][g_PlayerStates[client][nStrafes]] = time;
		}
		else if(g_PlayerStates[client][nStrafeDir] == STRAFE_D && (vel[1] > 0))
		{
			g_PlayerStates[client][fStrafeTimeLastSync][g_PlayerStates[client][nStrafes]] = time;
		}
		else if(g_PlayerStates[client][nStrafeDir] == STRAFE_W && (vel[0] > 0))
		{
			g_PlayerStates[client][fStrafeTimeLastSync][g_PlayerStates[client][nStrafes]] = time;
		}
		else if(g_PlayerStates[client][nStrafeDir] == STRAFE_S && (vel[0] < 0))
		{
			g_PlayerStates[client][fStrafeTimeLastSync][g_PlayerStates[client][nStrafes]] = time;
		}
	}
	
	/* New strafe action */
	if(newstrafe)
	{
		g_PlayerStates[client][nStrafes]++;
		
		/* Get delay between angle turned and key pressed for a new strafe */
		new Float:strafe_delay;
		strafe_delay = time-g_PlayerStates[client][fStrafeTimeLastSync][g_PlayerStates[client][nStrafes]-1];
		
		g_PlayerStates[client][fStrafeDelay][g_PlayerStates[client][nStrafes]] = strafe_delay;
	}
	
	/* Boosted strafe check */
	if(g_PlayerStates[client][nStrafes] > 0)
	{
		new Float:fVelDelta;
		fVelDelta = GetSpeed(client) - GetVSpeed(vLastVelocity[client]);
	
		if(!(GetEntityFlags(client) & FL_ONGROUND))
		{
			/* Filter low speed */
			if(GetSpeed(client) >= GetEntPropFloat(client, Prop_Send, "m_flMaxspeed"))
			{
				/* Filter low acceleration */
				if(fVelDelta > 3.0)
				{
					/* Strafe is boosted */
					if(!g_PlayerStates[client][bBoosted][g_PlayerStates[client][nStrafes]])
						g_PlayerStates[client][nStrafesBoosted]++;
					
					g_PlayerStates[client][bBoosted][g_PlayerStates[client][nStrafes]] = true;
				}
			}
		}
	}
	
	/* Save last player status */
	GetClientAbsOrigin(client, vLastOrigin[client]);
	GetClientAbsAngles(client, vLastAngles[client]);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vLastVelocity[client]);
}

stock ComputeStrafes(client)
{
	if (!IsClientInGame(client))
		return;
	if (IsFakeClient(client))
		return;
	
	new style = Timer_GetStyle(client);
	
	decl String:auth[64];
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
	
	new ccStrafes;
	new cStrafes[1000000];
	
	for(new i = 2; i < g_PlayerStates[client][nStrafes]; i++)
	{
		/* Ignore boosted strafes */
		if(g_PlayerStates[client][bBoosted][i])
			continue;
		
		/* Get tick delay */
		new delay = RoundToCeil((g_PlayerStates[client][fStrafeDelay][i]-0.01)*100);
		
		/* Count analyzed strafes */
		ccStrafes++;
		
		/* Bad strafes */
		if(delay < 0)
			continue;
		
		cStrafes[delay]++;
		//PrintToChat(client, "%i", delay);
	}
	
	if(ccStrafes < 10)
	{
		return;
	}
	
	decl String:query[2048];
	FormatEx(query, sizeof(query), "INSERT INTO `strafe` (map, auth, style, strafes, strafes0, strafes1, strafes2, strafes3, strafes4, strafes5, strafes6, strafes7, strafes8, strafes9, strafes10) VALUES ('%s', '%s', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d');", g_sCurrentMap, auth, style, ccStrafes, cStrafes[0], cStrafes[1], cStrafes[2], cStrafes[3], cStrafes[4], cStrafes[5], cStrafes[6], cStrafes[7], cStrafes[8], cStrafes[9], cStrafes[10]);
		
	SQL_TQuery(g_hSQL, InsertCallback, query, client, DBPrio_High);
}

/* Reset strafes */
stock ResetStrafes(client)
{
	g_PlayerStates[client][nStrafeDir] = 0;
	g_PlayerStates[client][nStrafes] = 0;
	g_PlayerStates[client][nStrafesBoosted] = 0;
	
	new Float:time = GetGameTime();
	
	for(new i = 0; i < MAX_STRAFES; i++)
	{
		g_PlayerStates[client][bBoosted][i] = false;
		
		g_PlayerStates[client][fStrafeTimeLastSync][i] = time;
		g_PlayerStates[client][fStrafeTimeAngleTurn][i] = time;
		g_PlayerStates[client][bStrafeAngleGain][i] = false;
		g_PlayerStates[client][fStrafeDelay][i] = 0.0;
	}
}

Float:GetSpeed(client)
{
	new Float:vVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);
	vVelocity[2] = 0.0;
	
	return GetVectorLength(vVelocity); 
}

Float:GetVSpeed(Float:v[3])
{
	new Float:vVelocity[3];
	vVelocity = v;
	vVelocity[2] = 0.0;
	
	return GetVectorLength(vVelocity);
}

ConnectSQL()
{
	if (g_hSQL != INVALID_HANDLE)
	{
		CloseHandle(g_hSQL);
	}

	g_hSQL = INVALID_HANDLE;

	if (SQL_CheckConfig("timer"))
	{
		SQL_TConnect(ConnectSQLCallback, "timer");
	}
	else
	{
		SetFailState("PLUGIN STOPPED - Reason: no config entry found for 'timer' in databases.cfg - PLUGIN STOPPED");
	}
}

public ConnectSQLCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (g_iSQLReconnectCounter >= 5)
	{
		PrintToServer("PLUGIN STOPPED - Reason: reconnect counter reached max - PLUGIN STOPPED");
		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("Connection to SQL database has failed, Reason: %s", error);
		g_iSQLReconnectCounter++;
		ConnectSQL();
		return;
	}
	
	decl String:driver[16];
	SQL_GetDriverIdent(owner, driver, sizeof(driver));

	g_hSQL = CloneHandle(hndl);
	
	if (StrEqual(driver, "mysql", false))
	{
		SQL_SetCharset(g_hSQL, "utf8");
		SQL_TQuery(g_hSQL, CreateSQLTableCallback, "CREATE TABLE IF NOT EXISTS `strafe` (`id` int(11) NOT NULL AUTO_INCREMENT, `map` varchar(32) NOT NULL, `auth` varchar(32) NOT NULL, `style` int(11) NOT NULL, `strafes` int(11) NOT NULL, `strafes0` int(11) NOT NULL, `strafes1` int(11) NOT NULL, `strafes2` int(11) NOT NULL, `strafes3` int(11) NOT NULL, `strafes4` int(11) NOT NULL, `strafes5` int(11) NOT NULL, `strafes6` int(11) NOT NULL, `strafes7` int(11) NOT NULL, `strafes8` int(11) NOT NULL, `strafes9` int(11) NOT NULL, `strafes10` int(11) NOT NULL, date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8;");
	}
	
	g_iSQLReconnectCounter = 1;
}

public CreateSQLTableCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (owner == INVALID_HANDLE)
	{
		Timer_LogError(error);
		
		g_iSQLReconnectCounter++;
		ConnectSQL();

		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on CreateSQLTable: %s", error);
		return;
	}
}

public InsertCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on InsertCallback: %s", error);
		return;
	}
}