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
#if defined _YADPLIB_COMMAND_INCLUDED
	#endinput
#endif
#define _YADPLIB_COMMAND_INCLUDED
#pragma newdecls optional
#include <clientprefs>
#pragma newdecls required


static int g_DiceAttepmts[MAXPLAYERS + 1];
static Handle g_ckDisable;
static Handle g_ckAuto;

stock void YADP_Initialize_Command()
{
	char msg[40];
	Format(msg, sizeof(msg), "%T", "yadp_main_Init", LANG_SERVER);
	HookEvent("round_start", YADP_Command_Roundstart, EventHookMode_PostNoCopy);
	YADP_Debug_LogMessage("command", msg, LogServer, LevelInfo);
}

stock void YADP_Configure_Command()
{
	g_ckDisable = RegClientCookie("yadp_disable", "YADP disable dice.", CookieAccess_Protected);
	g_ckAuto = RegClientCookie("yadp_auto", "YADP automated rolling.", CookieAccess_Protected);
}

stock Action YADP_Command_Roundstart(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MAXPLAYERS; i++)
	{
		if(!YADP_Util_IsValidClient(i, true))
		{
			continue;
		}
		if(g_DiceAttepmts[i] < 1)
		{
			g_DiceAttepmts[i]++;
		}
		if(HasDiceDisabled(i))
		{
			continue;
		}
		char msg[100];
		if(HasDiceAuto(i) || IsFakeClient(i))
		{
			YADP_Command_HandleRequest(i, 0);
		} else {
			char cmd[15];
			YADP_Config_GetRandomCmd(cmd, sizeof(cmd));
			Format(msg, sizeof(msg), "%T", "yadp_main_RollTheDice", i, cmd);
			YADP_Chat_PrintToChat(i, msg);
		}
		if(g_DiceAttepmts[i] > 1)
		{
			Format(msg, sizeof(msg), "%T", "yadp_main_NumberOfAttempts", i, g_DiceAttepmts[i]);
			YADP_Chat_PrintToChat(i, msg);
		}
	}
}

stock Action YADP_Command_HandleRequest(int client, int args)
{
	if(!YADP_Util_IsValidClient(client, true))
	{
		return Plugin_Handled;
	}
	if(g_DiceAttepmts[client] < 1)
	{
		char msg[100];
		Format(msg, sizeof(msg), "%T", "yadp_main_NoAttemptsLeft", client);
		YADP_Chat_ReplyToCommand(client, msg);
		return Plugin_Handled;
	}
	if(GetUserAdmin(client) == INVALID_ADMIN_ID || (GetUserAdmin(client) != INVALID_ADMIN_ID && !GetAdminFlag(GetUserAdmin(client), Admin_Root)))
	{
		g_DiceAttepmts[client]--;
	}
	int mod = YADP_Module_ChooseRandom(view_as<YADP_Module_Team>(GetClientTeam(client)));
	YADP_Module_SendOnDiced(mod, client);
	return Plugin_Handled;
}

stock bool HasDiceDisabled(int client)
{
	if(!YADP_Util_IsValidClient(client, false))
	{
		return true;
	}
	if(!AreClientCookiesCached(client))
	{
		SetDiceAuto(client, false);
		SetDiceDisabled(client, false);
		return false;
	}
	char val[5];
	GetClientCookie(client, g_ckDisable, val, sizeof(val));
	return val[0] == '1';
}

stock void SetDiceDisabled(int client, bool value)
{
	if(!YADP_Util_IsValidClient(client, false))
	{
		return;
	}
	char val[2];
	val	= value ? "1" : "0";
	SetClientCookie(client, g_ckDisable, val);
}

stock bool HasDiceAuto(int client)
{
	if(!YADP_Util_IsValidClient(client, false))
	{
		return false;
	}
	if(!AreClientCookiesCached(client))
	{
		SetDiceAuto(client, false);
		SetDiceDisabled(client, false);
		return false;
	}
	char val[5];
	GetClientCookie(client, g_ckAuto, val, sizeof(val));
	return val[0] == '1';
}

stock void SetDiceAuto(int client, bool value)
{
	if(!YADP_Util_IsValidClient(client, false))
	{
		return;
	}
	char val[2];
	val = value ? "1" : "0";
	SetClientCookie(client, g_ckAuto, val);
}

stock Action YADP_Command_HandleDisable(int client, int args)
{
	if(!YADP_Util_IsValidClient(client, false))
	{
		return Plugin_Handled;
	}
	bool disable = !HasDiceDisabled(client);
	SetDiceDisabled(client, disable);
	char msg[80];
	Format(msg, sizeof(msg), "%T", (disable ? "yadp_main_UserDisableActive" : "yadp_main_UserDisableInactive"), client);
	YADP_Chat_ReplyToCommand(client, msg);
	return Plugin_Handled;
}

stock Action YADP_Command_HandleAuto(int client, int args)
{
	if(!YADP_Util_IsValidClient(client, false))
	{
		return Plugin_Handled;
	}
	bool auto = !HasDiceAuto(client);
	SetDiceAuto(client, auto);
	char msg[80];
	Format(msg, sizeof(msg), "%T", (auto ? "yadp_main_UserAutoActive" : "yadp_main_UserAutoInactive"), client);
	YADP_Chat_ReplyToCommand(client, msg);
	return Plugin_Handled;
}

stock Action YADP_Command_HandleMenu(int client, int args)
{
	if(!YADP_Util_IsValidClient(client, false))
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}