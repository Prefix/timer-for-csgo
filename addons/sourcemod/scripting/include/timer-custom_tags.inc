#if defined _custom_tags_included_
  #endinput
#endif
#define _custom_tags_included_


/**
 * Return if we should use the custom tag or not.
 *
 * @param client    A client.
 * @return        True or false.
 */
native bool:Timer_UseCustomTag(client);

/**
 * Stores the player's custom tag in the buffer provided.
 * @param buffer
 * @param maxlen
 * @param client
 *
 * @noreturn
 */
native Timer_GetCustomTag(String:tag[], size, client);

/**
 * Stores the player's custom tag including the defined chat colors in the buffer provided.
 * @param buffer
 * @param maxlen
 * @param client
 *
 * @noreturn
 */
native Timer_GetCustomChatTag(String:tag[], size, client);

/**
 * Stores the player's custom chat text color in the buffer provided.
 * @param buffer
 * @param maxlen
 * @param client
 *
 * @noreturn
 */
native Timer_GetCustomTextColor(String:text[], size, client);

public SharedPlugin:__pl_timer_custom_tags = 
{
	name = "timer-custom_tags",
	file = "timer-custom_tags.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_timer_custom_tags_SetNTVOptional() 
{
	MarkNativeAsOptional("Timer_UseCustomTag");
	MarkNativeAsOptional("Timer_GetCustomTag");
	MarkNativeAsOptional("Timer_GetCustomChatTag");
	MarkNativeAsOptional("Timer_GetCustomTextColor");
}