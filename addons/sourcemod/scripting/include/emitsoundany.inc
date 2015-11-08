#if defined _emitsoundany_included
 #endinput
#endif
#define _emitsoundany_included

static bool B_check_engine = false;
static bool B_need_fake_precache = false;

/***********************************************************/
/******************* CHECK ENGINE VERSION ******************/
/***********************************************************/
stock static void EmitSoundCheckEngineVersion()
{
	if (B_check_engine)
	{
		return;
	}

	EngineVersion engVersion = GetEngineVersion();
	
	if (engVersion == Engine_CSGO || engVersion == Engine_DOTA)
	{
		B_need_fake_precache = true;
	}
	B_check_engine = true;
}

/***********************************************************/
/******************** FAKE PRECACHE SOUND ******************/
/***********************************************************/
stock static bool FakePrecacheSoundEx(const char[] szPath)
{
	char szPathStar[PLATFORM_MAX_PATH];
	Format(szPathStar, sizeof(szPathStar), "*%s", szPath);
	
	AddToStringTable( FindStringTable( "soundprecache" ), szPathStar );
	return true;
}

/***********************************************************/
/********************** PRECACHE SOUND *********************/
/***********************************************************/
stock bool PrecacheSoundAny(const char[] szPath, bool preload=false)
{
	EmitSoundCheckEngineVersion();
	
	if (B_need_fake_precache)
	{
		return FakePrecacheSoundEx(szPath);
	}
	else
	{
		return PrecacheSound(szPath, preload);
	}
}

/***********************************************************/
/************************* EMIT SOUND **********************/
/***********************************************************/
stock void EmitSoundAny(const int[] clients, 
                 int numClients, 
                 const char[] sample, 
                 int entity = SOUND_FROM_PLAYER, 
                 int channel = SNDCHAN_AUTO, 
                 int level = SNDLEVEL_NORMAL, 
                 int flags = SND_NOFLAGS, 
                 float volume = SNDVOL_NORMAL, 
                 int pitch = SNDPITCH_NORMAL, 
                 int speakerentity = -1, 
                 const float origin[3] = NULL_VECTOR, 
                 const float dir[3] = NULL_VECTOR, 
                 bool updatePos = true, 
                 float soundtime = 0.0)
{
	EmitSoundCheckEngineVersion();

	char szSound[PLATFORM_MAX_PATH];
	
	if (B_need_fake_precache)
	{
		Format(szSound, sizeof(szSound), "*%s", sample);
	}
	else
	{
		strcopy(szSound, sizeof(szSound), sample);
	}
	
	EmitSound(clients, numClients, szSound, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);	
}

/***********************************************************/
/******************** EMIT SOUND TO CLIENT *****************/
/***********************************************************/
stock void EmitSoundToClientAny(int client,
				 const char[] sample,
				 int entity = SOUND_FROM_PLAYER,
				 int channel = SNDCHAN_AUTO,
				 int level = SNDLEVEL_NORMAL,
				 int flags = SND_NOFLAGS,
				 float volume = SNDVOL_NORMAL,
				 int pitch = SNDPITCH_NORMAL,
				 int speakerentity = -1,
				 const float origin[3] = NULL_VECTOR,
				 const float dir[3] = NULL_VECTOR,
				 bool updatePos = true,
				 float soundtime = 0.0)
{
	int[] clients = new int[1];
	clients[0] = client;
	/* Save some work for SDKTools and remove SOUND_FROM_PLAYER references */
	entity = (entity == SOUND_FROM_PLAYER) ? client : entity;
	EmitSoundAny(clients, 1, sample, entity, channel, 
	level, flags, volume, pitch, speakerentity,
	origin, dir, updatePos, soundtime);
}

/***********************************************************/
/********************* EMIT SOUND TO ALL *******************/
/***********************************************************/
stock void EmitSoundToAllAny(const char[] sample, 
                 int entity = SOUND_FROM_PLAYER, 
                 int channel = SNDCHAN_AUTO, 
                 int level = SNDLEVEL_NORMAL, 
                 int flags = SND_NOFLAGS, 
                 float volume = SNDVOL_NORMAL, 
                 int pitch = SNDPITCH_NORMAL, 
                 int speakerentity = -1, 
                 const float origin[3] = NULL_VECTOR, 
                 const float dir[3] = NULL_VECTOR, 
                 bool updatePos = true, 
                 float soundtime = 0.0)
{
	int[] clients= new int[MaxClients];
	int total = 0;
	
	for (int i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			clients[total++] = i;
		}
	}
	
	if (!total)
	{
		return;
	}
	
	EmitSoundAny(clients, total, sample, entity, channel, 
	level, flags, volume, pitch, speakerentity,
	origin, dir, updatePos, soundtime);
}

/***********************************************************/
/******************** EMIT AMBIENT SOUND *******************/
/***********************************************************/
stock void EmitAmbientSoundAny(const char[] name,
						const float pos[3],
						int entity = SOUND_FROM_WORLD,
						int level = SNDLEVEL_NORMAL,
						int flags = SND_NOFLAGS,
						float vol = SNDVOL_NORMAL,
						int pitch = SNDPITCH_NORMAL,
						float delay = 0.0)
{
	char szSound[PLATFORM_MAX_PATH];
	
	if (B_need_fake_precache)
	{
		Format(szSound, sizeof(szSound), "*%s", sample);
	}
	else
	{
		strcopy(szSound, sizeof(szSound), sample);
	}
	
	EmitAmbientSound(szSound, pos, entity, level, flags, vol, pitch, delay);
}
