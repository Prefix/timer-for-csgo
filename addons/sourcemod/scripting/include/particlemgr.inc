#if defined _particlemgr_included
 #endinput
#endif
#define _particlemgr_included
 
/**
 * Precaches a particle file (pcf).
 *
 * @param particleFileName     Path of particle file, relative to game directory.
 * @return                     Precache index.
 */
native int ParticleMgr_PrecacheFile(const char[] particleFileName);
 
/* DO NOT EDIT BELOW THIS LINE */
 
public SharedPlugin:__pl_particlemgr = 
{
	name = "particlemgr",
	file = "particlemgr.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
 
#if !defined REQUIRE_PLUGIN
public __pl_particlemgr_SetNTVOptional()
{
	MarkNativeAsOptional("ParticleMgr_PrecacheFile");
}
#endif