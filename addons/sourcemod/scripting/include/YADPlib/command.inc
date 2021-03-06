/**
 * YADP, yet another dice plugin for SourceMod.
 * 
 * Copyright (C) 2015 Hendrik Reker
 * 
 * This file is part of YADP.
 * 
 * YADP is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 * 
 * YADP is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * 
 * See the GNU General Public License for more details. You should have received a copy of the GNU
 * General Public License along with YADP. If not, see <http://www.gnu.org/licenses/>.
 * 
 * Version: $version$
 * GitBase: $git-branch$ / $git-hash-long$
 * Authors: Hendrik Reker
 */
#if defined _YADPLIB_COMMAND_INCLUDED
	#endinput
#endif
#define _YADPLIB_COMMAND_INCLUDED
#pragma newdecls optional
#include <clientprefs>
#pragma newdecls required


static int g_DiceState[MAXPLAYERS + 1][2];
static Handle g_ckDisable;
static Handle g_ckAuto;
static bool g_canRoll = false;
stock void YADP_Initialize_Command()
{
	char msg[40];
	Format(msg, sizeof(msg), "%T", "yadp_main_Init", LANG_SERVER);
	HookEvent("round_start", YADP_Command_Roundstart, EventHookMode_PostNoCopy);
	HookEvent("round_end", YADP_Command_Roundend, EventHookMode_PostNoCopy);
	YADP_Debug_LogMessage("command", msg, LogServer, LevelInfo);
}

stock void YADP_Configure_Command()
{
	g_ckDisable = RegClientCookie("yadp_disable", "YADP disable dice.", CookieAccess_Protected);
	g_ckAuto = RegClientCookie("yadp_auto", "YADP automated rolling.", CookieAccess_Protected);
}

stock Action YADP_Command_Roundstart(Event event, const char[] name, bool dontBroadcast)
{
	g_canRoll = true;
	for(int i = 1; i <= MAXPLAYERS; i++)
	{
		if(!YADP_Util_YADP_IsValidClient(i, true))
		{
			g_DiceState[i][0] = 0;
			g_DiceState[i][1] = -1;
			continue;
		}
		if(g_DiceState[i][0] < 1)
		{
			g_DiceState[i][0]++;
		}
		char msg[100];
		if(!HasDiceDisabled(i))
		{
			if(HasDiceAuto(i) || IsFakeClient(i))
			{
				YADP_Command_HandleRequest(i, 0);
			} else {
				char cmd[15];
				YADP_Config_GetRandomCmd(cmd, sizeof(cmd));
				Format(msg, sizeof(msg), "%T", "yadp_main_RollTheDice", i, cmd);
				YADP_Chat_PrintToChat(i, msg);
			}
		}		
		if(g_DiceState[i][0] > 1 || g_DiceState[i][0] < 0)
		{
			Format(msg, sizeof(msg), "%T", "yadp_main_NumberOfAttempts", i, g_DiceState[i][0]);
			YADP_Chat_PrintToChat(i, msg);
		}
	}
}

stock Action YADP_Command_Roundend(Event event, const char[] name, bool dontBroadcast)
{
	g_canRoll = false;
	for(int i = 1; i <= MAXPLAYERS; i++)
	{
		if(g_DiceState[i][1] < 0)
		{
			continue;
		}
		YADP_Module_SendOnReset(g_DiceState[i][1], i);
		g_DiceState[i][1] = -1;
	}
}

stock Action YADP_Command_HandleRequest(int client, int args)
{
	if(!g_canRoll || !YADP_Util_YADP_IsValidClient(client, true))
	{
		return Plugin_Handled;
	}
	if(g_DiceState[client][0] < 1)
	{
		char msg[100];
		Format(msg, sizeof(msg), "%T", "yadp_main_NoAttemptsLeft", client);
		YADP_Chat_PrintToChat(client, msg);
		return Plugin_Handled;
	}
	

	if(!YADP_IsDebugInstance())
	{
		g_DiceState[client][0]--;
	}
	
	int mod = YADP_Module_ChooseRandom(view_as<YADP_Module_Team>(GetClientTeam(client)));
	g_DiceState[client][1] = mod;
	YADP_Module_SendOnDiced(mod, client);
	return Plugin_Handled;
}

stock bool HasDiceDisabled(int client)
{
	if(!YADP_Util_YADP_IsValidClient(client, false))
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
	if(!YADP_Util_YADP_IsValidClient(client, false))
	{
		return;
	}
	char val[2];
	val	= value ? "1" : "0";
	SetClientCookie(client, g_ckDisable, val);
}

stock bool HasDiceAuto(int client)
{
	if(!YADP_Util_YADP_IsValidClient(client, false))
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
	if(!YADP_Util_YADP_IsValidClient(client, false))
	{
		return;
	}
	char val[2];
	val = value ? "1" : "0";
	SetClientCookie(client, g_ckAuto, val);
}

stock Action YADP_Command_HandleDisable(int client, int args)
{
	if(!YADP_Util_YADP_IsValidClient(client, false))
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
	if(!YADP_Util_YADP_IsValidClient(client, false))
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
	if(!YADP_Util_YADP_IsValidClient(client, false))
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

stock int YADP_Command_YADP_SetAttemptsNative(Handle plugin, int numParams)
{
	if(numParams != 2 || !YADP_Initialized())
	{
		return 0;
	}
	int client = GetNativeCell(1);
	if(!YADP_Util_YADP_IsValidClient(client, true))
	{
		return 0;
	}
	g_DiceState[client][0] = GetNativeCell(2);
	return 0;
}

stock int YADP_Command_YADP_GetAttemptsNative(Handle plugin, int numParams)
{
	if(numParams != 1 || !YADP_Initialized())
	{
		return 0;
	}
	int client = GetNativeCell(1);
	if(!YADP_Util_YADP_IsValidClient(client, true))
	{
		return 0;
	}
	return g_DiceState[client][0];
}