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
static float g_GravityMin;
static float g_GravityMax;
static float g_SpeedMin;
static float g_SpeedMax;
static int g_AttemptsMin;
static int g_AttemptsMax;
static int g_modIndexLongjump = -1;
static int g_modIndexLongjumpExtreme = -1;
static int g_modIndexGravity = -1;
static int g_modIndexSpeed = -1;
static int g_modIndexAttempts = -1;
static ConVar g_cvEnableLongjump;
static ConVar g_cvWeightLongjump;
static ConVar g_cvEnableLongjumpExtreme;
static ConVar g_cvWeightLongjumpExtreme;
static ConVar g_cvEnableGravity;
static ConVar g_cvWeightGravity;
static ConVar g_cvGravityMin;
static ConVar g_cvGravityMax;
static ConVar g_cvEnableSpeed;
static ConVar g_cvWeightSpeed;
static ConVar g_cvSpeedMin;
static ConVar g_cvSpeedMax;
static ConVar g_cvEnableAttempts;
static ConVar g_cvWeightAttempts;
static ConVar g_cvAttemptsMin;
static ConVar g_cvAttemptsMax;

public void OnPluginStart()
{
	LoadTranslations("yadp.modifiers.phrases.txt");
	g_cvEnableLongjump = CreateConVar("yadp_longjump_enable", "1", "Players can roll Longjump.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvWeightLongjump = CreateConVar("yadp_longjump_weight", "50", "Probability of players getting Longjump.", FCVAR_NONE, true, 0.0);
	g_cvEnableLongjumpExtreme = CreateConVar("yadp_longjumpex_enable", "1", "Players can roll Longjump Extreme.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvWeightLongjumpExtreme = CreateConVar("yadp_longjumpex_weight", "50", "Probability of players getting Longjump Extreme.", FCVAR_NONE, true, 0.0);
	g_cvEnableGravity = CreateConVar("yadp_gravity_enable", "1", "Players can roll a gravity change.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvWeightGravity = CreateConVar("yadp_gravity_weight", "50", "Probability of players getting a gravity change.", FCVAR_NONE, true, 0.0);
	g_cvGravityMin = CreateConVar("yadp_gravity_min", "0.1", "Minimum gravity.", FCVAR_NONE, true, 0.1, true, 1.0);
	g_cvGravityMax = CreateConVar("yadp_gravity_max", "3.0", "Maximum gravity.", FCVAR_NONE, true, 1.0, true, 3.0);
	g_cvEnableSpeed = CreateConVar("yadp_speed_enable", "1", "Players can roll a speed change.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvWeightSpeed = CreateConVar("yadp_speed_weight", "50", "Probability of players getting a speed change.", FCVAR_NONE, true, 0.0);
	g_cvSpeedMin = CreateConVar("yadp_speed_min", "0.1", "Minimum speed.", FCVAR_NONE, true, 0.1, true, 1.0);
	g_cvSpeedMax = CreateConVar("yadp_speed_max", "2.0", "Maximum speed.", FCVAR_NONE, true, 1.0, true, 2.0);
	g_cvEnableAttempts = CreateConVar("yadp_attempts_enable", "1", "Players can roll additional attempts.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvWeightAttempts = CreateConVar("yadp_attempts_weight", "50", "Probability of players getting additional attempts.", FCVAR_NONE, true, 0.0);
	g_cvAttemptsMin = CreateConVar("yadp_attempts_min", "-3.0", "Minimum attempts.", FCVAR_NONE, true, -5.0, true, 1.0);
	g_cvAttemptsMax = CreateConVar("yadp_attempts_max", "3.0", "Maximum attempts.", FCVAR_NONE, true, 1.0, true, 5.0);
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
	g_modIndexGravity = -1;
	g_modIndexSpeed = -1;
	g_modIndexAttempts = -1;
}

static void ModuleInit()
{
	AutoExecConfig(true, "plugin.YADP.Modifiers");
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
	if(GetConVarInt(g_cvEnableGravity) == 1)
	{
		g_modIndexGravity = YADP_RegisterModule("Gravity", "Players get random gravity.", GetConVarInt(g_cvWeightGravity), ModuleTeam_Any);
		YADP_RegisterOnDice(g_modIndexGravity, HandleDicedGravity, ResetDicedGravity);
	}
	if(GetConVarInt(g_cvEnableSpeed) == 1)
	{
		g_modIndexSpeed = YADP_RegisterModule("Speed", "Players get random speed.", GetConVarInt(g_cvWeightSpeed), ModuleTeam_Any);
		YADP_RegisterOnDice(g_modIndexSpeed, HandleDicedSpeed, ResetDicedSpeed);
	}
	if(GetConVarInt(g_cvEnableAttempts) == 1)
	{
		g_modIndexAttempts = YADP_RegisterModule("Attempts", "Players get additional attempts.", GetConVarInt(g_cvWeightAttempts), ModuleTeam_Any);
		YADP_RegisterOnDice(g_modIndexAttempts, HandleDicedAttempts, ResetDicedAttempts);
	}
	HookEvent("player_jump", PlayerJumpHook, EventHookMode_Post);
}

static void ModuleConf()
{
	g_GravityMin = GetConVarFloat(g_cvGravityMin);
	g_GravityMax = GetConVarFloat(g_cvGravityMax);
	g_SpeedMin = GetConVarFloat(g_cvSpeedMin);
	g_SpeedMax = GetConVarFloat(g_cvSpeedMax);
	g_AttemptsMin = GetConVarInt(g_cvAttemptsMin);
	g_AttemptsMax = GetConVarInt(g_cvAttemptsMax);
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

static void HandleDicedGravity(int client)
{
	if(g_modIndexGravity < 0 || !YADP_IsValidClient(client, true))
	{
		return;
	}
	float val = Math_GetRandomFloat(g_GravityMin, g_GravityMax);
	char msg[80];
	Format(msg, sizeof(msg), "%T", "yadp_modifiers_Gravity", client, val * 100);
	YADP_SendChatMessage(client, msg);
	SetEntityGravity(client, val);
}

static void ResetDicedGravity(int client)
{
	if(YADP_IsValidClient(client, true))
	{
		SetEntityGravity(client, 1.0);
	}
}

static void HandleDicedSpeed(int client)
{
	if(g_modIndexSpeed < 0 || !YADP_IsValidClient(client, true))
	{
		return;
	}
	float val = Math_GetRandomFloat(g_SpeedMin, g_SpeedMax);
	char msg[80];
	Format(msg, sizeof(msg), "%T", "yadp_modifiers_Speed", client, val * 100);
	YADP_SendChatMessage(client, msg);
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", val); 
}

static void ResetDicedSpeed(int client)
{
	if(YADP_IsValidClient(client, true))
	{
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0); 
	}
}

static void HandleDicedAttempts(int client)
{
	if(g_modIndexAttempts < 0 || !YADP_IsValidClient(client, true))
	{
		return;
	}
	int val = Math_GetRandomInt(g_AttemptsMin, g_AttemptsMax);
	char col[10];
	col = val < 0 ? "{red}" : "{green}+"; 
	char msg[80];
	Format(msg, sizeof(msg), "%T", "yadp_modifiers_Attempts", client, col, val);
	YADP_SendChatMessage(client, msg);
	YADP_SetAttempts(client, YADP_GetAttempts(client) + val);
}

static void ResetDicedAttempts(int client)
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