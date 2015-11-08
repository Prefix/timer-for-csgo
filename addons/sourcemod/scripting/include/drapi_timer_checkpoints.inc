#if defined _drapi_timer_checkpoints_included
 #endinput
#endif
#define _drapi_timer_checkpoints_included

/* Natives */
native Timer_GetCheckpointsWR(client, &bool:enable, &level, &Float:wrtime, &Float:pbtime);
native Timer_GetCheckpointsWRBonus(client, &bool:enable, &level, &Float:wrtime, &Float:pbtime);

native Timer_GetActiveHud(client);
native Timer_SetActiveHud(client, status);
	
public SharedPlugin:__pl_drapi_timer_checkpoints = 
{
	name = "drapi_timer_checkpoints",
	file = "drapi_timer_checkpoints.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_drapi_timer_checkpoints_SetNTVOptional() 
{
	MarkNativeAsOptional("Timer_GetCheckpointsWR");
	MarkNativeAsOptional("Timer_GetCheckpointsWRBonus");
	MarkNativeAsOptional("Timer_GetActiveHud");
	MarkNativeAsOptional("Timer_SetActiveHud");
}