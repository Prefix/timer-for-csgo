/***********************************************************/
/********************* SET CLIENT NAMES ********************/
/***********************************************************/
stock int CS_SetClientName(int client, char[] name)
{
	static Handle hSetName = INVALID_HANDLE;
	
	if (hSetName == INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetFromConf(GetSetNameConf(), SDKConf_Virtual, "CBaseClient::SetName");
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		hSetName = EndPrepSDKCall();
	}
	
	return SDKCall(hSetName, GetBaseClient(client - 1), name);
}

/***********************************************************/
/********************** GET CLIENT NAME ********************/
/***********************************************************/
stock void CS_GetClientName(int client, char[] name, int maxlen)
{
	static Handle hGetName = INVALID_HANDLE;
	
	if (hGetName == INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetFromConf(GetSetNameConf(), SDKConf_Virtual, "CBaseClient::GetClientName");
		PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Pointer);
		hGetName = EndPrepSDKCall();
	}
	
	SDKCall(hGetName, GetIClient(client - 1), name, maxlen);
}

/***********************************************************/
/********************* GET GAMEDATA TXT ********************/
/***********************************************************/
stock Handle GetSetNameConf()
{
	static Handle hGameConf = INVALID_HANDLE;
	
	if (hGameConf == INVALID_HANDLE)
	{
		hGameConf = LoadGameConfigFile("setname.games");
	}
	
	return hGameConf;
}

/***********************************************************/
/********************** GET BASE SERVER ********************/
/***********************************************************/
stock Address GetBaseServer()
{
	static Address pBaseServer = Address_Null;
	
	if (pBaseServer == Address_Null)
	{
		pBaseServer = GameConfGetAddress(GetSetNameConf(), "CBaseServer");
	}
	
	return pBaseServer;
}

/***********************************************************/
/************************ GET CLIENT ***********************/
/***********************************************************/
stock Address GetIClient(int client)
{
	static Handle hGetClient = INVALID_HANDLE;
	
	if (hGetClient == INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetFromConf(GetSetNameConf(), SDKConf_Virtual, "CBaseServer::GetClient");
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		hGetClient = EndPrepSDKCall();
	}
	
	return SDKCall(hGetClient, GetBaseServer(), client);
}

/***********************************************************/
/********************* GET BASE CLIENT *********************/
/***********************************************************/
stock Address GetBaseClient(int client)
{
	return GetIClient(client) - Address:4;
}
