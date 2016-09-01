#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
    name = "New Plugin",
    author = "Unknown",
    description = "<- Description ->",
    version = "1.0",
    url = "<- URL ->"
}

public OnPluginStart()
{
    RegAdminCmd("sm_gethid", GetEntInfo, ADMFLAG_ROOT);
}
public Action:GetEntInfo(client, args)
{
    new entId = GetClientAimTarget(client, false);
    if (entId != -1)
    {
        decl String:hammerStr[32];
        new hammerInt = (GetEntProp(entId, Prop_Data, "m_iHammerID", 32));
        IntToString(hammerInt, hammerStr, 32);
        PrintToChat(client, "hammer Id is %s", hammerStr);
    }else
        {
            PrintToChat(client, "No entities found.")
        }
    return Plugin_Handled;
}  