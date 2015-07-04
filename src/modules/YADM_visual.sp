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
#include <smlib>
#pragma newdecls required
#include <YADP>

public Plugin myinfo = {
	name = "YADM: visual",
	author = "Hendrik Reker",
	description = "Yet Another Dice Module: visual",
	version = "$version$",
	url = "https://github.com/reker-/YADP"
};

static float g_minFoV;
static float g_maxFoV;
static int g_modIndexFOV = -1;
static int g_modIndexFOVExtreme = -1;
static ConVar g_cvEnableFoV;
static ConVar g_cvWeightFoV;
static ConVar g_cvFoVMin;
static ConVar g_cvFoVMax;
static ConVar g_cvEnableFoVExtreme;
static ConVar g_cvWeightFoVExtreme;

public void OnPluginStart()
{
	LoadTranslations("yadp.visual.phrases.txt");
	g_cvEnableFoV = CreateConVar("yadp_fov_enable", "1", "Players can roll a FoV change.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvWeightFoV = CreateConVar("yadp_fov_weight", "50", "Probability of players getting a FoV change.", FCVAR_PLUGIN, true, 0.0);
	g_cvFoVMin = CreateConVar("yadp_fov_min", "0.5", "Minimum health a player can receive.", FCVAR_PLUGIN);
	g_cvFoVMax = CreateConVar("yadp_fov_max", "1.5", "Maximum health a player can receive.", FCVAR_PLUGIN);
	g_cvEnableFoVExtreme = CreateConVar("yadp_fovExtreme_enable", "1", "Players can roll a FoV change.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvWeightFoVExtreme = CreateConVar("yadp_fovExtreme_weight", "50", "Probability of players getting a FoV change.", FCVAR_PLUGIN, true, 0.0);
	HookEvent("player_spawn", OnPlayerSpawnHook);
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
	g_modIndexFOV = -1;
}

static void ModuleInit()
{
	AutoExecConfig(true, "plugin.YADP.Visual");
	if(GetConVarInt(g_cvEnableFoV) == 1)
	{
		g_modIndexFOV = YADP_RegisterModule("FoV", "Players get random FoV.", GetConVarInt(g_cvWeightFoV), ModuleTeam_Any);
		YADP_RegisterOnDice(g_modIndexFOV, HandleDicedFoV, ResetDicedFoV);
	}
	if(GetConVarInt(g_cvEnableFoVExtreme) == 1)
	{
		g_modIndexFOVExtreme = YADP_RegisterModule("FoVEx", "Players get extreme FoV.", GetConVarInt(g_cvWeightFoVExtreme), ModuleTeam_Any);
		YADP_RegisterOnDice(g_modIndexFOVExtreme, HandleDicedFoVExtreme, ResetDicedFoVExtreme);
	}
}

static void ModuleConf()
{
	g_minFoV = GetConVarFloat(g_cvFoVMin);
	g_maxFoV = GetConVarFloat(g_cvFoVMax);
}

public Action OnPlayerSpawnHook(Handle:event, const String:name[], bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!YADP_IsValidClient(client, true))
	{
		return Plugin_Continue;
	}
	SetPlayerFoV(client, 90);
	return Plugin_Continue;
}

static void HandleDicedFoV(int client)
{
	if(g_modIndexFOV < 0 || !YADP_IsValidClient(client, true))
	{
		return;
	}
	float val = Math_GetRandomFloat(g_minFoV, g_maxFoV);
	int oldVal = GetPlayerFoV(client);
	int newVal = RoundToFloor(oldVal * val);
	SetPlayerFoV(client, newVal);
	char msg[80];
	Format(msg, sizeof(msg), "%T", "yadp_visual_FoV", client, newVal);
	YADP_SendChatMessage(client, msg);
}

static void ResetDicedFoV(int client)
{
	if(g_modIndexFOV < 0 || !YADP_IsValidClient(client, true))
	{
		return;
	}
	SetPlayerFoV(client, 90);
}

static void HandleDicedFoVExtreme(int client)
{
	if(g_modIndexFOVExtreme < 0 || !YADP_IsValidClient(client, true))
	{
		return;
	}
	SetPlayerFoV(client, 199);
	char msg[80];
	Format(msg, sizeof(msg), "%T", "yadp_visual_FoVExtreme", client);
	YADP_SendChatMessage(client, msg);
}

static void ResetDicedFoVExtreme(int client)
{
	if(g_modIndexFOVExtreme < 0 || !YADP_IsValidClient(client, true))
	{
		return;
	}
	SetPlayerFoV(client, 90);
}

static int GetPlayerFoV(int client)
{
	return !YADP_IsValidClient(client, true) ? -1 : GetEntProp(client, Prop_Send, "m_iDefaultFOV");
}

static void SetPlayerFoV(int client, int val)
{
	if(!YADP_IsValidClient(client, true))
	{
		return;
	}
	SetEntProp(client, Prop_Send, "m_iDefaultFOV", val);
	SetEntProp(client, Prop_Send, "m_iFOV", val);
}