/**
 * YADP, yet another dice plugin for SourceMod.
 * 
 * Copyright (C) 2015 Hendrik Reker
 * 
 * This file is part of YADP.
 * 
 * YADP is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 2 of the
 * License, or (at your option) any later version.
 * 
 * YADP is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * 
 * See the GNU General Public License for more details. You should have received a copy of the GNU
 * General Public License along with YADP. If not, see <http://www.gnu.org/licenses/>.
 * 
 * Version: $version$
 * Authors: Hendrik Reker
 */
#if defined _YADPLIB_CHAT_INCLUDED
	#endinput
#endif
#define _YADPLIB_CHAT_INCLUDED

#pragma newdecls optional
#include <colors_csgo>
#pragma newdecls required

static ConVar g_cvChatName;
static char g_chatName[10];

stock void YADP_Initialize_Chat()
{
	g_cvChatName = CreateConVar("yadp_chatName", "YADP", "The identifier used by YADP in chat messages.", FCVAR_PLUGIN);
}

stock void YADP_Configure_Chat()
{
	GetConVarString(g_cvChatName, g_chatName, sizeof(g_chatName));
}

stock void YADP_Chat_PrintToChat(int client, const char[] message)
{
	char msg[256];
	Format(msg, sizeof(msg), "{orange}[{blue}%s{orange}]:{default} %s", g_chatName, message);
	CPrintToChat(client, msg);
}

stock void YADP_Chat_ReplyToCommand(int client, const char[] message)
{
	char msg[256];
	Format(msg, sizeof(msg), "{orange}[{blue}%s{orange}]:{default} %s", g_chatName, message);
	CReplyToCommand(client, msg);
}


stock int YADP_Chat_SendToClient(Handle plugin, int numParams)
{
	if(numParams != 2 || !YADP_Initialized())
	{
		return 0;
	}
	int clt = GetNativeCell(1);
	char msg[256];
	GetNativeString(2, msg, sizeof(msg));
	char pName[50];
	char cAuth[50];
	char lmsg[306];
	if(YADP_Util_IsValidClient(clt, false))
	{
		GetClientAuthId(clt, AuthId_SteamID64, cAuth, sizeof(cAuth), true);
	} else {
		cAuth = "<missing-auth>"
	}
	GetPluginFilename(plugin, pName, sizeof(pName));
	Format(lmsg, sizeof(lmsg), "%T", "yadp_main_ModMsg", LANG_SERVER, pName, cAuth, msg);
	YADP_Debug_LogMessage("global", lmsg, LogFile, LevelInfo);
	YADP_Chat_PrintToChat(clt, msg);
	return 0;
}