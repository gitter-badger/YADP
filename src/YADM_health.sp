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
#pragma newdecls required
#include <YADP>

public Plugin myinfo = {
	name = "YADM: ",
	author = "Hendrik Reker",
	description = "Yet Another Dice Module: ",
	version = "$version$",
	url = "https://github.com/reker-/YADP"
};

static int g_modIdxHealth = -1;
static int g_modIdxArmor = -1;
static int g_modIdxHealthArmor = -1;
static int g_minHealth = 0;
static int g_maxHealth = 0;
static int g_minArmor = 0;
static int g_maxArmor = 0;
static ConVar g_cvEnableHealth;
static ConVar g_cvWeigthHealth;
static ConVar g_cvHealthMin;
static ConVar g_cvHealthMax;
static ConVar g_cvEnableArmor;
static ConVar g_cvWeigthArmor;
static ConVar g_cvArmorMin;
static ConVar g_cvArmorMax;

public void OnPluginStart() {
	LoadTranslations("yadp.health.phrases.txt");
	g_cvEnableHealth = CreateConVar("yadp_health_enable", "1", "Players can roll health.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvWeigthHealth = CreateConVar("yadp_health_weight", "50", "Probability of players getting health.", FCVAR_PLUGIN, true, 0.0);
	g_cvHealthMin = CreateConVar("yadp_health_min", "-90", "Minimum health a player can receive.", FCVAR_PLUGIN);
	g_cvHealthMax = CreateConVar("yadp_health_max", "90", "Maximum health a player can receive.", FCVAR_PLUGIN);
	g_cvEnableArmor = CreateConVar("yadp_armor_enable", "1", "Players can roll armor.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvWeigthArmor = CreateConVar("yadp_armor_weight", "50", "Probability of players getting armor.", FCVAR_PLUGIN, true, 0.0);
	g_cvArmorMin = CreateConVar("yadp_armor_min", "10", "Minimum armor a player can receive.", FCVAR_PLUGIN);
	g_cvArmorMax = CreateConVar("yadp_armor_max", "150", "Maximum armor a player can receive.", FCVAR_PLUGIN);
}

public void OnLibraryAdded(const char[] name) {
	if (!StrEqual(name, YADPLIB_NAME)) return;
	Register_OnModuleInit(ModuleInit);
	Register_OnModuleConf(ModuleConf);
}

public void OnLibraryRemoved(const char[] name) {
	if (StrEqual(name, YADPLIB_NAME)) return;
	g_modIdxHealth = -1;
	g_modIdxArmor = -1;
	g_modIdxHealthArmor = -1;
}

static void ModuleInit() {
	if(GetConVarInt(g_cvEnableHealth) == 1) {
		g_modIdxHealth = RegisterModule("Health", "desc", GetConVarInt(g_cvWeigthHealth), ModuleTeam_Any);
		Register_OnDiced(g_modIdxHealth, HandleDicedHealth);
	}
	if(GetConVarInt(g_cvEnableArmor) == 1) {
		g_modIdxArmor = RegisterModule("Armor", "desc", GetConVarInt(g_cvWeigthArmor), ModuleTeam_Any);
		Register_OnDiced(g_modIdxArmor, HandleDicedArmor);
	}
	if(GetConVarInt(g_cvEnableArmor) == 1) {
		g_modIdxHealthArmor = RegisterModule("Armor", "desc", ((GetConVarInt(g_cvWeigthHealth) + GetConVarInt(g_cvWeigthArmor)) / 2), ModuleTeam_Any);
		Register_OnDiced(g_modIdxHealthArmor, HandleDicedHealthArmor);
	}
	AutoExecConfig(true, "plugin.YADP.Health");
}

static void ModuleConf() {
	g_minHealth = GetConVarInt(g_cvHealthMin);
	g_maxHealth = GetConVarInt(g_cvHealthMax);
	g_minArmor = GetConVarInt(g_cvArmorMin);
	g_maxArmor = GetConVarInt(g_cvArmorMax);
}

static void HandleDicedHealth(int client) {
	if(g_modIdxHealth < 0) return;
	
	NotifyPlayer(client, GetPlayerHealth(client), true);
	SetPlayerHealth(client, RandomHealth());
}

static void HandleDicedArmor(int client) {
	if(g_modIdxArmor < 0) return;
	NotifyPlayer(client, GetPlayerArmor(client), false);
	SetPlayerArmor(client, RandomArmor());
}

static void HandleDicedHealthArmor(int client) {
	if(g_modIdxHealthArmor < 0) return;
	SetPlayerHealth(client, RandomHealth());
	SetPlayerArmor(client, RandomArmor());
}

static int RandomHealth() {
	return GetRandomInt(g_minHealth, g_maxHealth);
}

static int RandomArmor() {
	return GetRandomInt(g_minArmor, g_maxArmor);
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