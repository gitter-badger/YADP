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
#include <sdktools_functions>
#include <sdkhooks>
#pragma newdecls required
#include <YADP>

public Plugin myinfo = {
	name = "YADM: health",
	author = "Hendrik Reker",
	description = "Yet Another Dice Module: health",
	version = "$version$",
	url = "https://github.com/reker-/YADP"
};

enum HealthMode {
	HealthMode_None = 0,
	HealthMode_HalfDamageR = 1,
	HealthMode_DoubleDamageR = 2,
	HealthMode_HalfDamageG = 4,
	HealthMode_DoubleDamageG = 8,
};

static ConVar g_cvEnableHealth;
static ConVar g_cvWeigthHealth;
static ConVar g_cvHealthMin;
static ConVar g_cvHealthMax;
static ConVar g_cvEnableArmor;
static ConVar g_cvWeigthArmor;
static ConVar g_cvArmorMin;
static ConVar g_cvArmorMax;
static ConVar g_cvEnableDamage;
static ConVar g_cvWeigthDamage;
static ConVar g_cvEnableFire;
static ConVar g_cvWeigthFire;
static int g_modIdxHealth = -1;
static int g_modIdxArmor = -1;
static int g_modIdxHealthArmor = -1;
static int g_modIdxDamage = -1;
static int g_modIdxFire = -1;
static int g_minHealth = 0;
static int g_maxHealth = 0;
static int g_minArmor = 0;
static int g_maxArmor = 0;
static HealthMode g_Modes[MAXPLAYERS + 1];
static Handle g_Timers[MAXPLAYERS + 1];
static int g_TimerCount[MAXPLAYERS + 1];

public void OnPluginStart() {
	LoadTranslations("yadp.health.phrases.txt");
	g_cvEnableHealth = CreateConVar("yadp_health_enable", "0", "Players can roll health.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvWeigthHealth = CreateConVar("yadp_health_weight", "50", "Probability of players getting health.", FCVAR_PLUGIN, true, 0.0);
	g_cvHealthMin = CreateConVar("yadp_health_min", "-90", "Minimum health a player can receive.", FCVAR_PLUGIN);
	g_cvHealthMax = CreateConVar("yadp_health_max", "90", "Maximum health a player can receive.", FCVAR_PLUGIN);
	g_cvEnableArmor = CreateConVar("yadp_armor_enable", "0", "Players can roll armor.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvWeigthArmor = CreateConVar("yadp_armor_weight", "50", "Probability of players getting armor.", FCVAR_PLUGIN, true, 0.0);
	g_cvArmorMin = CreateConVar("yadp_armor_min", "10", "Minimum armor a player can receive.", FCVAR_PLUGIN);
	g_cvArmorMax = CreateConVar("yadp_armor_max", "150", "Maximum armor a player can receive.", FCVAR_PLUGIN);
	g_cvEnableDamage = CreateConVar("yadp_damage_enable", "0", "Players can roll damage.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvWeigthDamage = CreateConVar("yadp_damage_weight", "50", "Probability of players getting damage.", FCVAR_PLUGIN, true, 0.0);
	g_cvEnableFire = CreateConVar("yadp_fire_enable", "1", "Players can roll fire.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvWeigthFire = CreateConVar("yadp_fire_weight", "50", "Probability of players getting lit on fire.", FCVAR_PLUGIN, true, 0.0);
	HookEvent("round_start", RoundStartHook, EventHookMode_PostNoCopy);
}

static Action RoundStartHook(Event event, const char[] name, bool dontBroadcast) {
	char eName[30];
	char msg[100];
	if(event != null) GetEventName(event, eName, sizeof(eName));
	Format(msg, sizeof(msg), "event fired: %s - %s - %s", eName, name, (dontBroadcast ? "TRUE" : "FALSE"));
	LogModuleMessage(msg, LogServer, LevelInfo);
	for(int i = 1; i < MAXPLAYERS + 1; i++) {
		g_Modes[i] = HealthMode_None;
		g_TimerCount[i] = 0;
		if(g_Timers[i] != null) KillTimer(g_Timers[i], false);
	}
}

public void OnClientPostAdminCheck(int client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamgeHook);
}

public void OnClientDisconnect(int client) {
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamgeHook);
}

Action OnTakeDamgeHook(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
	if((damagetype == (DMG_BURN | DMG_DIRECT) || damagetype == DMG_BURN) && g_TimerCount[victim] > 0 && g_TimerCount[victim] <= 99) {
		return Plugin_Handled;
	}
	float dmg = damage;
	if(victim > 0 && victim < MAXPLAYERS + 1) {
		if((g_Modes[victim] & HealthMode_HalfDamageR) == HealthMode_HalfDamageR) dmg /= 2.0;
		if((g_Modes[victim] & HealthMode_DoubleDamageR) == HealthMode_DoubleDamageR) dmg *= 2.0;
	}
	if(attacker > 0 && attacker < MAXPLAYERS + 1) {
		if((g_Modes[attacker] & HealthMode_HalfDamageG) == HealthMode_HalfDamageG) dmg /= 2.0;
		if((g_Modes[attacker] & HealthMode_DoubleDamageG) == HealthMode_DoubleDamageG) dmg *= 2.0;
	}
	damage = dmg;
	return Plugin_Changed;
}

public void OnLibraryAdded(const char[] name) {
	if (!StrEqual(name, YADPLIB_NAME)) return;
	RegOnModuleInit(ModuleInit);
	RegOnModuleConf(ModuleConf);
}

public void OnLibraryRemoved(const char[] name) {
	if (StrEqual(name, YADPLIB_NAME)) return;
	g_modIdxHealth = -1;
	g_modIdxArmor = -1;
	g_modIdxHealthArmor = -1;
	g_modIdxDamage = -1;
	g_modIdxFire = -1;
}

static void ModuleInit() {
	AutoExecConfig(true, "plugin.YADP.Health");
	if(GetConVarInt(g_cvEnableHealth) == 1) {
		g_modIdxHealth = RegisterModule("Health", "Players get random health.", GetConVarInt(g_cvWeigthHealth), ModuleTeam_Any);
		RegOnDiced(g_modIdxHealth, HandleDicedHealth);
	}
	if(GetConVarInt(g_cvEnableArmor) == 1) {
		g_modIdxArmor = RegisterModule("Armor", "Players get random armor.", GetConVarInt(g_cvWeigthArmor), ModuleTeam_Any);
		RegOnDiced(g_modIdxArmor, HandleDicedArmor);
	}
	if(GetConVarInt(g_cvEnableArmor) == 1) {
		g_modIdxHealthArmor = RegisterModule("Health&Armor", "Players get random health & armor", ((GetConVarInt(g_cvWeigthHealth) + GetConVarInt(g_cvWeigthArmor)) / 2), ModuleTeam_Any);
		RegOnDiced(g_modIdxHealthArmor, HandleDicedHealthArmor);
	}
	if(GetConVarInt(g_cvEnableDamage) == 1) {
		g_modIdxDamage = RegisterModule("Damage", "Players get random damage modifiers.", GetConVarInt(g_cvWeigthDamage), ModuleTeam_Any);
		RegOnDiced(g_modIdxDamage, HandleDicedDamage);
	}
	if(GetConVarInt(g_cvEnableFire) == 1) {
		g_modIdxFire = RegisterModule("Fire", "Players get randomly lit on fire.", GetConVarInt(g_cvWeigthFire), ModuleTeam_Any);
		RegOnDiced(g_modIdxFire, HandleDicedFire);
	}
}

static void ModuleConf() {
	g_minHealth = GetConVarInt(g_cvHealthMin);
	g_maxHealth = GetConVarInt(g_cvHealthMax);
	g_minArmor = GetConVarInt(g_cvArmorMin);
	g_maxArmor = GetConVarInt(g_cvArmorMax);
}

static void HandleDicedHealth(int client) {
	if(g_modIdxHealth < 0 || !IsValidClient(client, true)) return;
	NotifyPlayer(client, GetPlayerHealth(client), true);
	SetPlayerHealth(client, RandomHealth());
}

static void HandleDicedArmor(int client) {
	if(g_modIdxArmor < 0 || !IsValidClient(client, true)) return;
	NotifyPlayer(client, GetPlayerArmor(client), false);
	SetPlayerArmor(client, RandomArmor());
}

static void HandleDicedHealthArmor(int client) {
	if(g_modIdxHealthArmor < 0 || !IsValidClient(client, true)) return;
	SetPlayerHealth(client, RandomHealth());
	SetPlayerArmor(client, RandomArmor());
}

static void HandleDicedDamage(int client) {
	if(g_modIdxDamage < 0 || !IsValidClient(client, true)) return;
	HealthMode mode = RandomHealthMode();
	char phrase[40];
	HealthModeToString(mode, phrase, sizeof(phrase));
	g_Modes[client] = mode;
	char msg[80];
	Format(msg, sizeof(msg), "%T", phrase, client);
	SendChatMessage(client, msg);
}

static void HandleDicedFire(int client) {
	if(g_modIdxFire < 0 || !IsValidClient(client, true)) return;
	char msg[80];
	Format(msg, sizeof(msg), "%T", "yadp_health_Fire", client);
	SendChatMessage(client, msg);
	g_TimerCount[client] = 0;
	g_Timers[client] = CreateTimer(0.2, FireTimer, client, TIMER_REPEAT);
}

static Action FireTimer(Handle timer, any client) {
	if(g_TimerCount[client] >= 99 || !IsValidClient(client, true)) {
		KillTimer(timer, false);
		g_Timers[client] = null;
		return Plugin_Continue;
	}
	g_TimerCount[client]++;
	SlapPlayer(client, 1, true);
	IgniteEntity(client, 0.1, false, 0.0, true);
	return Plugin_Continue;
}

static int RandomHealth() {
	return GetRandomInt(g_minHealth, g_maxHealth);
}

static int RandomArmor() {
	return GetRandomInt(g_minArmor, g_maxArmor);
}

static HealthMode RandomHealthMode() {
	int i = GetRandomInt(0,5);
	switch(i) {
		case 0: return HealthMode_HalfDamageR;
		case 1: return HealthMode_DoubleDamageR;
		case 2: return HealthMode_HalfDamageG;
		case 3: return HealthMode_DoubleDamageG;
	}
	return HealthMode_HalfDamageG;
}

static void HealthModeToString(HealthMode mode, char[] str, int maxlength) {
	switch(mode) {
		case HealthMode_HalfDamageR: Format(str, maxlength, "%s", "yadp_health_HalfDamageR");
		case HealthMode_DoubleDamageR: Format(str, maxlength, "%s", "yadp_health_DoubleDamageR");
		case HealthMode_HalfDamageG: Format(str, maxlength, "%s", "yadp_health_HalfDamageG");
		case HealthMode_DoubleDamageG: Format(str, maxlength, "%s", "yadp_health_DoubleDamageG");
	}
}

static void SetPlayerHealth(int client, int val) {
	int nval = GetPlayerHealth(client) + val;
	if(nval < 1) {
		ForcePlayerSuicide(client);
	} else {
		SetEntityHealth(client, nval);
	}
	NotifyPlayer(client, val, true);
}

static void SetPlayerArmor(int client, int val) {
	int nval = GetPlayerArmor(client) + val;
	SetEntProp(client, Prop_Data, "m_ArmorValue", (nval < 1 ? 0 : nval));
	NotifyPlayer(client, val, false);
}

static int GetPlayerHealth(int client) {
	return GetClientHealth(client);
}

static int GetPlayerArmor(int client) {
	return GetEntProp(client, Prop_Data, "m_ArmorValue");
}

static void NotifyPlayer(int client, int val, bool health) {
	char valStr[10];
	Format(valStr, sizeof(valStr), "%s%d", (val<0?"":"+"), val); 
	char msg[80];
	Format(msg, sizeof(msg), "%T", (health?"yadp_health_ChangeHealth":"yadp_health_ChangeArmor"), client, (val<0?"{red}":"{green}"), valStr);
	SendChatMessage(client, msg);
}