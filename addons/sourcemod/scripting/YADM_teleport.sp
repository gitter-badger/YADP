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
#include <sdktools_functions>
#include <sdkhooks>
#pragma newdecls required
#include <YADP>

public Plugin myinfo = {
	name = "YADM: teleport",
	author = "Hendrik Reker",
	description = "Yet Another Dice Module: teleport",
	version = "$version$",
	url = "https://github.com/reker-/YADP"
};

enum TeleportMode {
	TeleportMode_None = 0,
	TeleportMode_TakeDmg = 1,
	TeleportMode_GiveDmg = 2,
	TeleportMode_Smoke = 4,
};

static ConVar g_cvEnableSwitch;
static ConVar g_cvWeightSwitch;
static ConVar g_cvEnableSwitchTeam;
static ConVar g_cvWeightSwitchTeam;
static ConVar g_cvEnableSwitchDmg;
static ConVar g_cvWeightSwitchDmg;
static ConVar g_cvEnableSmoke;
static ConVar g_cvWeightSmoke;
static int g_modIdxSwitch = -1;
static int g_modIdxSwitchTeam = -1;
static int g_modIdxSwitchDmg = -1;
static int g_modIdxSmoke = -1;
static TeleportMode g_Modes[MAXPLAYERS + 1];

public void OnPluginStart()
{
	LoadTranslations("yadp.teleport.phrases.txt");
	g_cvEnableSwitch = CreateConVar("yadp_switch_enable", "1", "Players can roll a position switch.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvWeightSwitch = CreateConVar("yadp_switch_weight", "50", "Probability of players getting a position switch.", FCVAR_PLUGIN, true, 0.0);
	g_cvEnableSwitchTeam = CreateConVar("yadp_switchTeam_enable", "1", "Players can roll a position switch.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvWeightSwitchTeam = CreateConVar("yadp_switchTeam_weight", "50", "Probability of players getting a position switch.", FCVAR_PLUGIN, true, 0.0);
	g_cvEnableSwitchDmg = CreateConVar("yadp_switchDmg_enable", "1", "Players can roll a position switch.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvWeightSwitchDmg = CreateConVar("yadp_switchDmg_weight", "50", "Probability of players getting a position switch.", FCVAR_PLUGIN, true, 0.0);
	g_cvEnableSmoke = CreateConVar("yadp_smoke_enable", "1", "Players can roll a teleportation grenade.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvWeightSmoke = CreateConVar("yadp_smoke_weight", "50", "Probability of players getting a teleportation grenade.", FCVAR_PLUGIN, true, 0.0);
	HookEvent("smokegrenade_detonate", SmokeGrenadeDetonateHook);
}

static Action SmokeGrenadeDetonateHook(Handle:event, const String:name[], bool:dontBroadcast)
{
	char eName[30];
	char msg[100];
	if(event != null)
	{
		GetEventName(event, eName, sizeof(eName));
	}
	Format(msg, sizeof(msg), "event fired: %s - %s - %s", eName, name, (dontBroadcast ? "TRUE" : "FALSE"));
	YADP_LogModuleMessage(msg, LogServer, LevelInfo);
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_Modes[client] != TeleportMode_Smoke)
	{
		return Plugin_Continue;
	}
	float a[3];
	a[0] = GetEventFloat(event, "x");
	a[1] = GetEventFloat(event, "y");
	a[2] = GetEventFloat(event, "z");
	
	TeleportEntity(client, a, NULL_VECTOR, NULL_VECTOR);
	return Plugin_Continue;   
} 

public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamgeHook);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamgeHook);
}

Action OnTakeDamgeHook(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(!YADP_IsValidClient(victim, true) || !YADP_IsValidClient(attacker, true))
	{
		return Plugin_Continue;
	}
	if(g_Modes[victim] == TeleportMode_TakeDmg || g_Modes[attacker] == TeleportMode_GiveDmg)
	{
		SwitchPlayers(victim, attacker);
		NotifyPlayers(victim, attacker);
	}
	return Plugin_Continue;
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
	g_modIdxSwitch = -1;
	g_modIdxSwitchTeam = -1;
	g_modIdxSwitchDmg = -1;
	g_modIdxSmoke = -1;
}

static void ModuleInit()
{
	AutoExecConfig(true, "plugin.YADP.Teleport");
	if(GetConVarInt(g_cvEnableSwitch) == 1)
	{
		g_modIdxSwitch = YADP_RegisterModule("Switch", "Players switch position.", GetConVarInt(g_cvWeightSwitch), ModuleTeam_Any);
		YADP_RegisterOnDice(g_modIdxSwitch, HandleDicedSwitch, ResetDicedSwitch);
	}
	if(GetConVarInt(g_cvEnableSwitchTeam) == 1)
	{
		g_modIdxSwitchTeam = YADP_RegisterModule("SwitchTeam", "Players switch position.", GetConVarInt(g_cvWeightSwitchTeam), ModuleTeam_Any);
		YADP_RegisterOnDice(g_modIdxSwitchTeam, HandleDicedSwitchTeam, ResetDicedSwitchTeam);
	}
	if(GetConVarInt(g_cvEnableSwitchDmg) == 1)
	{
		g_modIdxSwitchDmg = YADP_RegisterModule("SwitchDmg", "Players switch position.", GetConVarInt(g_cvWeightSwitchDmg), ModuleTeam_Any);
		YADP_RegisterOnDice(g_modIdxSwitchDmg, HandleDicedSwitchDmg, ResetDicedSwitchDmg);
	}
	if(GetConVarInt(g_cvEnableSmoke) == 1)
	{
		g_modIdxSmoke = YADP_RegisterModule("SmokePort", "Players switch position.", GetConVarInt(g_cvWeightSmoke), ModuleTeam_Any);
		YADP_RegisterOnDice(g_modIdxSmoke, HandleDicedSmoke, ResetDicedSmoke);
	}
}

static void ModuleConf()
{

}

static void HandleDicedSwitch(int client)
{
	if(g_modIdxSwitch < 0 || !YADP_IsValidClient(client, true))
	{
		return;
	}
	int idx;
	if(GetClientCount() > 1)
	{
		do
		{
			idx = GetRandomInt(1, MAXPLAYERS - 1);
		} while(!IsClientInGame(idx) || idx == client || GetClientTeam(idx) != GetClientTeam(client));
		SwitchPlayers(client, idx);
		NotifyPlayers(client, idx);
	}
}

static void ResetDicedSwitch(int client)
{
}

static void HandleDicedSwitchTeam(int client)
{
	if(g_modIdxSwitchTeam < 0 || !YADP_IsValidClient(client, true))
	{
		return;
	}
	int idx;
	if(GetClientCount() > 1)
	{
		do
		{
			idx = GetRandomInt(1, MAXPLAYERS - 1);
		} while(!IsClientInGame(idx) || idx == client);
		SwitchPlayers(client, idx);
		NotifyPlayers(client, idx);
	}
}

static void ResetDicedSwitchTeam(int client)
{
}

static void HandleDicedSwitchDmg(int client)
{
	if(g_modIdxSwitchDmg < 0 || !YADP_IsValidClient(client, true))
	{
		return;
	}
	int rndInt = GetRandomInt(0, 100);
	g_Modes[client] = (rndInt < 50 ? TeleportMode_GiveDmg : TeleportMode_TakeDmg);
}

static void ResetDicedSwitchDmg(int client)
{
	g_Modes[client] = TeleportMode_None;
}

static void HandleDicedSmoke(int client)
{
	if(g_modIdxSmoke < 0 || !YADP_IsValidClient(client, true))
	{
		return;
	}
	g_Modes[client] = TeleportMode_Smoke;
	GivePlayerItem(client, "weapon_smokegrenade");
	char msg[80];
	Format(msg, sizeof(msg), "%T", "yadp_teleport_Smoke", client);
	YADP_SendChatMessage(client, msg);
}

static void ResetDicedSmoke(int client)
{
	g_Modes[client] = TeleportMode_None;
}

static void GetPosition(int client, float position[3])
{
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", position);
}

static void GetRotation(int client, float rotation[3])
{
	GetEntPropVector(client, Prop_Data, "m_angAbsRotation", rotation);
}

static void GetVelocity(int client, float velocity[3])
{
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
}

static void SwitchPlayers(int clFirst, int clSecond)
{
	float clFirstPos[3], clSecondPos[3], clFirstRot[3], clSecondRot[3], clFirstVel[3], clSecondVel[3];
	GetPosition(clFirst, clFirstPos);
	GetPosition(clSecond, clSecondPos);
	GetRotation(clFirst, clFirstRot);
	GetRotation(clSecond, clSecondRot);
	GetVelocity(clFirst, clFirstVel);
	GetVelocity(clSecond, clSecondVel);
	TeleportEntity(clFirst, clSecondPos, clSecondRot, clSecondVel);
	TeleportEntity(clSecond, clFirstPos, clFirstRot, clFirstVel);
}

static void NotifyPlayers(int clFirst, int clSecond)
{
	char cName[40];
	char iName[40];
	char tcl[10];
	Format(cName, sizeof(cName), "%N", clFirst);
	Format(iName, sizeof(iName), "%N", clSecond);
	char msg[128];
	Format(tcl, sizeof(tcl), "%s", GetClientTeam(clSecond) == 3 ? "{blue}" : "{red}");
	Format(msg, sizeof(msg), "%T", "yadp_teleport_SwitchPosition", clFirst, tcl, iName);
	YADP_SendChatMessage(clFirst, msg);
	Format(tcl, sizeof(tcl), "%s", GetClientTeam(clFirst) == 3 ? "{blue}" : "{red}");
	Format(msg, sizeof(msg), "%T", "yadp_teleport_SwitchPosition", clSecond, tcl, cName);
	YADP_SendChatMessage(clSecond, msg);
}