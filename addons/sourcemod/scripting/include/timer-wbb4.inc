#if defined _timer_wbb4_included
 #endinput
#endif
#define _timer_wbb4_included

/* Forwards */
forward WBB4_OnPlayerReady(client);

/* Natives */
native WBB4_IsRegistered(client);
native WBB4_IsVerified(client);
native WBB4_GetUserID(client);
native WBB4_GetOnlineGroupID(client);
native WBB4_IsGroupMember(client, GroupID);

native WBB4_UsesCustomChatTag(client);
native WBB4_GetChatTag(client, String:tag[], length);
native WBB4_GetChatTagColor(client, String:color[], length);
native WBB4_GetChatTagColor2(client, String:color[], length);
native WBB4_GetChatTagColor3(client, String:color[], length);

native WBB4_ShoutboxEntry(const String:username, const String:message, any:...);

/* Stocks */
stock bool:GetFriendID_OLD(String:AuthID[], String:FriendID[], size)
{
	ReplaceString(AuthID, strlen(AuthID), "STEAM_", "");
	if (StrEqual(AuthID, "ID_LAN"))
	{
		FriendID[0] = '\0';
		return false;
	}
	decl String:toks[3][16];
	new upper = 765611979;
	new String:temp[12], String:carry[12];

	ExplodeString(AuthID, ":", toks, sizeof(toks), sizeof(toks[]));
	new iServer = StringToInt(toks[1]);
	new iAuthID = StringToInt(toks[2]);
	new iFriendID = (iAuthID*2) + 60265728 + iServer;

	if (iFriendID >= 100000000)
	{
		Format(temp, sizeof(temp), "%d", iFriendID);
		Format(carry, 2, "%s", temp);
		new icarry = StringToInt(carry[0]);
		upper += icarry;

		Format(temp, sizeof(temp), "%d", iFriendID);
		Format(FriendID, size, "%d%s", upper, temp[1]);
	}
	else
		Format(FriendID, size, "765611979%d", iFriendID);
	return true;
}

stock bool:GetFriendID(String:AuthID[], String:FriendID[], size)
{
	if(strlen(AuthID) < 11 || AuthID[0]!='S' || AuthID[6]=='I')
	{
		FriendID[0] = 0;
		return false;
	}
	
	new iUpper = 765611979;
	new iFriendID = StringToInt(AuthID[10])*2 + 60265728 + AuthID[8]-48;
	new iDiv = iFriendID/100000000;
	new iIdx = 9-(iDiv?iDiv/10+1:0);
	iUpper += iDiv;
	IntToString(iFriendID, FriendID[iIdx], size-iIdx);
	iIdx = FriendID[9];
	IntToString(iUpper, FriendID, size);
	FriendID[9] = iIdx;
	return true;
}

public SharedPlugin:__pl_timer_wbb4_included = 
{
	name = "timer-wbb4",
	file = "timer-wbb4.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_timer_wbb4_SetNTVOptional() 
{
	MarkNativeAsOptional("WBB4_IsRegistered");
	MarkNativeAsOptional("WBB4_IsVerified");
	MarkNativeAsOptional("WBB4_GetUserID");
	MarkNativeAsOptional("WBB4_GetGroupID");
	MarkNativeAsOptional("WBB4_ShoutboxEntry");
	MarkNativeAsOptional("WBB4_UsesCustomChatTag");
	MarkNativeAsOptional("WBB4_GetChatTag");
	MarkNativeAsOptional("WBB4_GetChatTagColor");
	MarkNativeAsOptional("WBB4_GetChatTagColor2");
}