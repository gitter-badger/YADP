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
};

static ConVar g_cvEnableGravPull;
static ConVar g_cvWeightGravPull;
static ConVar g_cvGravPullForce;
static int g_modIndexGravPull = -1;
static Handle g_PullTimer = null;
static MiscMode g_Modes[MAXPLAYERS + 1];
static float g_GravPullForce;

public void OnPluginStart()
{
	LoadTranslations("yadp.misc.phrases.txt");
	g_cvEnableGravPull = CreateConVar("yadp_gravPull_enable", "1", "Players can roll health.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvWeightGravPull = CreateConVar("yadp_gravPull_weight", "50", "Probability of players getting health.", FCVAR_PLUGIN, true, 0.0);
	g_cvGravPullForce = CreateConVar("yadp_gravPull_force", "20.0", "Force of the gravitational pull.", FCVAR_PLUGIN, true, 1.0, true, 10.0);
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
}

static void ModuleInit()
{
	AutoExecConfig(true, "plugin.YADP.Misc");
	if(GetConVarInt(g_cvEnableGravPull) == 1)
	{
		g_modIndexGravPull = YADP_RegisterModule("GravPull", "Players get additional gravitational pull.", GetConVarInt(g_cvWeightGravPull), ModuleTeam_Any);
		YADP_RegisterOnDice(g_modIndexGravPull, HandleDicedGravPull, ResetDicedGravPull);
	}
	HookEvent("round_start", RoundStartHook, EventHookMode_Post);
	HookEvent("round_end", RoundEndHook, EventHookMode_Post);
}

static void ModuleConf()
{
	g_GravPullForce = GetConVarFloat(g_cvGravPullForce);
}

public Action RoundStartHook(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_PullTimer = CreateTimer(0.1, PullTimer, 0, TIMER_REPEAT);
	return Plugin_Continue;
}

public Action RoundEndHook(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_PullTimer != null)
	{
		KillTimer(g_PullTimer, false);
		g_PullTimer = null;
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
	char msg[80];
	Format(msg, sizeof(msg), "Got GravPull");
	YADP_SendChatMessage(client, msg);
}

static void ResetDicedGravPull(int client)
{
	g_Modes[client] = MiscMode_None;
}

static Action PullTimer(Handle timer, any data)
{
	for(int i = 1; i <= MAXPLAYERS; i++)
	{
		if(g_Modes[i] != MiscMode_GravPull || !YADP_IsValidClient(i, true)) continue;
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
	if(GetVectorDistance(clPos, clTgt) < 0.5)
	{
		return;
	}
	SubtractVectors(clTgt, clPos, clNew);
	NormalizeVector(clNew, clNew);
	Entity_GetAbsVelocity(client, clVel);
	clVel[0] += (clNew[0]) * (g_GravPullForce * 10);
	clVel[1] += (clNew[1]) * (g_GravPullForce * 10);
	clVel[2] += (clNew[2]) * (g_GravPullForce * 10);
	Entity_SetAbsVelocity(client, clVel);
}