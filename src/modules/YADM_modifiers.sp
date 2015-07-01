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
 * Authors: Hendrik Reker
 */
#include <sourcemod>
#pragma newdecls required
#include <YADP>

public Plugin myinfo = {
	name = "YADM: modifiers",
	author = "Hendrik Reker",
	description = "Yet Another Dice Module: modifiers",
	version = "$version$",
	url = "https://github.com/reker-/YADP"
};

enum Modifier {
	Modifier_None = 0,
	Modifier_Longjump = 1,
	Modifier_LongjumpExtreme = 2,
};

static Modifier g_Modifiers[MAXPLAYERS + 1];
static int g_modIndexLongjump = -1;
static int g_modIndexLongjumpExtreme = -1;
static ConVar g_cvEnableLongjump;
static ConVar g_cvWeightLongjump;
static ConVar g_cvEnableLongjumpExtreme;
static ConVar g_cvWeightLongjumpExtreme;

public void OnPluginStart()
{
	LoadTranslations("yadp.modifiers.phrases.txt");
	g_cvEnableLongjump = CreateConVar("yadp_longjump_enable", "0", "Players can roll Longjump.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvWeightLongjump = CreateConVar("yadp_longjump_weight", "50", "Probability of players getting Longjump.", FCVAR_PLUGIN, true, 0.0);
	g_cvEnableLongjumpExtreme = CreateConVar("yadp_longjumpex_enable", "1", "Players can roll Longjump Extreme.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvWeightLongjumpExtreme = CreateConVar("yadp_longjumpex_weight", "50", "Probability of players getting Longjump Extreme.", FCVAR_PLUGIN, true, 0.0);
}

public void OnLibraryAdded(const char[] name)
{
	if (!StrEqual(name, YADPLIB_NAME))
	{
		return;
	}
	YADP_RegisterOnInit(ModuleInit);
	YADP_RegisterOnConf(ModuleConf);
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, YADPLIB_NAME))
	{
		return;
	}
	g_modIndexLongjump = -1;
	g_modIndexLongjumpExtreme = -1;
}

static void ModuleInit()
{
	if(GetConVarInt(g_cvEnableLongjump) == 1)
	{
		g_modIndexLongjump = YADP_RegisterModule("Longjump", "Players get Longjump.", GetConVarInt(g_cvWeightLongjump), ModuleTeam_Any);
		YADP_RegisterOnDice(g_modIndexLongjump, HandleDicedLongjump, ResetDicedLongjump);
	}
	if(GetConVarInt(g_cvEnableLongjumpExtreme) == 1)
	{
		g_modIndexLongjumpExtreme = YADP_RegisterModule("Longjump Extreme", "Players get extreme Longjump.", GetConVarInt(g_cvWeightLongjumpExtreme), ModuleTeam_Any);
		YADP_RegisterOnDice(g_modIndexLongjumpExtreme, HandleDicedLongjumpExtreme, ResetDicedLongjumpExtreme);
	}
	HookEvent("player_jump", PlayerJumpHook, EventHookMode_Post);
}

static void ModuleConf()
{

}

static void HandleDicedLongjump(int client)
{
	if(g_modIndexLongjump < 0 || !YADP_IsValidClient(client, true))
	{
		return;
	}
	g_Modifiers[client] = Modifier_Longjump;
	char msg[80];
	Format(msg, sizeof(msg), "%T", "yadp_modifiers_Longjump", client);
	YADP_SendChatMessage(client, msg);
}

static void ResetDicedLongjump(int client)
{
	g_Modifiers[client] = Modifier_None;
}

static void HandleDicedLongjumpExtreme(int client)
{
	if(g_modIndexLongjumpExtreme < 0 || !YADP_IsValidClient(client, true))
	{
		return;
	}
	g_Modifiers[client] = Modifier_LongjumpExtreme;
	char msg[80];
	Format(msg, sizeof(msg), "%T", "yadp_modifiers_LongjumpExtreme", client);
	YADP_SendChatMessage(client, msg);
}

static void ResetDicedLongjumpExtreme(int client)
{
	g_Modifiers[client] = Modifier_None;
}

static Action PlayerJumpHook(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid", -1));
	if(!YADP_IsValidClient(client, true) || (g_Modifiers[client] != Modifier_Longjump && g_Modifiers[client] != Modifier_LongjumpExtreme))
	{
		return;
	}
	float mod = (g_Modifiers[client] == Modifier_Longjump ? 8.0 : 1000.0);
	float nVel[3];
	nVel[0] = (mod * GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]")) * (1.0 / 4.1);
	nVel[1] = (mod * GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]")) * (1.0 / 4.1);
	
	SetEntPropVector(client, Prop_Send, "m_vecBaseVelocity", nVel);
}