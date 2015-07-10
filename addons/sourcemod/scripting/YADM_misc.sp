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
#include <sourcemod>
#include <smlib>
#pragma newdecls required
#include <YADP>

public Plugin myinfo = {
	name = "YADM: misc",
	author = "Hendrik Reker",
	description = "Yet Another Dice Module: misc",
	version = "$version$",
	url = "https://github.com/reker-/YADP"
};

enum MiscMode {
	MiscMode_None = 0,
	MiscMode_GravPull = 1,
	MiscMode_GravPush = 2,
};

static ConVar g_cvEnableGravPull;
static ConVar g_cvWeightGravPull;
static ConVar g_cvEnableGravPush;
static ConVar g_cvWeightGravPush;
static ConVar g_cvGravPullForce;
static ConVar g_cvGravPushForce;
static int g_modIndexGravPull = -1;
static int g_modIndexGravPush = -1;
static Handle g_forceTimer = null;
static MiscMode g_Modes[MAXPLAYERS + 1];
static float g_GravPullForce;
static float g_GravPushForce;

public void OnPluginStart()
{
	LoadTranslations("yadp.misc.phrases.txt");
	g_cvEnableGravPull = CreateConVar("yadp_gravPull_enable", "0", "Players can roll health.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvWeightGravPull = CreateConVar("yadp_gravPull_weight", "50", "Probability of players getting health.", FCVAR_PLUGIN, true, 0.0);
	g_cvGravPullForce = CreateConVar("yadp_gravPull_force", "20.0", "Force of the gravitational pull.", FCVAR_PLUGIN, true, 1.0, true, 100.0);
	g_cvEnableGravPush = CreateConVar("yadp_gravPush_enable", "1", "Players can roll health.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvWeightGravPush = CreateConVar("yadp_gravPush_weight", "50", "Probability of players getting health.", FCVAR_PLUGIN, true, 0.0);
	g_cvGravPushForce = CreateConVar("yadp_gravPush_force", "20.0", "Force of the gravitational pull.", FCVAR_PLUGIN, true, 1.0, true, 100.0);
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
	g_modIndexGravPull = -1;
	g_modIndexGravPush = -1;
}

static void ModuleInit()
{
	AutoExecConfig(true, "plugin.YADP.Misc");
	if(GetConVarInt(g_cvEnableGravPull) == 1)
	{
		g_modIndexGravPull = YADP_RegisterModule("GravPull", "Players get additional gravitational pull.", GetConVarInt(g_cvWeightGravPull), ModuleTeam_Any);
		YADP_RegisterOnDice(g_modIndexGravPull, HandleDicedGravPull, ResetDicedGravPull);
	}
	if(GetConVarInt(g_cvEnableGravPush) == 1)
	{
		g_modIndexGravPush = YADP_RegisterModule("GravPush", "Players get additional gravitational pull.", GetConVarInt(g_cvWeightGravPush), ModuleTeam_Any);
		YADP_RegisterOnDice(g_modIndexGravPush, HandleDicedGravPush, ResetDicedGravPush);
	}
	HookEvent("round_start", RoundStartHook, EventHookMode_Post);
	HookEvent("round_end", RoundEndHook, EventHookMode_Post);
}

static void ModuleConf()
{
	g_GravPullForce = GetConVarFloat(g_cvGravPullForce);
	g_GravPushForce = GetConVarFloat(g_cvGravPushForce);
}

public Action RoundStartHook(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_forceTimer = CreateTimer(0.1, PullTimer, 0, TIMER_REPEAT);
	return Plugin_Continue;
}

public Action RoundEndHook(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_forceTimer != null)
	{
		KillTimer(g_forceTimer, false);
		g_forceTimer = null;
	}
	return Plugin_Continue;
}

static void HandleDicedGravPull(int client)
{
	if(g_modIndexGravPull < 0 || !YADP_IsValidClient(client, true))
	{
		return;
	}
	g_Modes[client] = MiscMode_GravPull;
	char msg[100];
	Format(msg, sizeof(msg), "%T", "yadp_misc_GravPull", client);
	YADP_SendChatMessage(client, msg);
}

static void ResetDicedGravPull(int client)
{
	g_Modes[client] = MiscMode_None;
}

static void HandleDicedGravPush(int client)
{
	if(g_modIndexGravPush < 0 || !YADP_IsValidClient(client, true))
	{
		return;
	}
	g_Modes[client] = MiscMode_GravPush;
	char msg[100];
	Format(msg, sizeof(msg), "%T", "yadp_misc_GravPush", client);
	YADP_SendChatMessage(client, msg);
}

static void ResetDicedGravPush(int client)
{
	g_Modes[client] = MiscMode_None;
}

static Action PullTimer(Handle timer, any data)
{
	for(int i = 1; i <= MAXPLAYERS; i++)
	{
		if(g_Modes[i] == MiscMode_None || !YADP_IsValidClient(i, true)) continue;
		int target = Client_GetClosestToClient(i);
		if(!YADP_IsValidClient(target, true)) continue;
		ApplyForce(i, target);
	}
	return Plugin_Continue;
}

static void ApplyForce(int client, int target)
{
	float clPos[3], clTgt[3], clNew[3], clVel[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", clPos);
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", clTgt);
	if(GetVectorDistance(clPos, clTgt) < 0.5 || GetVectorDistance(clPos, clTgt) > 100.0)
	{
		return;
	}
	SubtractVectors(clTgt, clPos, clNew);
	NormalizeVector(clNew, clNew);
	Entity_GetAbsVelocity(client, clVel);
	int sg = (g_Modes[client] == MiscMode_GravPush ? -1 : 1);
	float fs = (g_Modes[client] == MiscMode_GravPush ? g_GravPushForce : g_GravPullForce);
	clVel[0] += sg * (clNew[0]) * (fs * 10);
	clVel[1] += sg * (clNew[1]) * (fs * 10);
	clVel[2] += sg * (clNew[2]) * (fs * 10);
	Entity_SetAbsVelocity(client, clVel);
}