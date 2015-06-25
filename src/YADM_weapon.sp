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
#include <sourcemod>
#include <sdktools>
#pragma newdecls required
#include <YADP>

#define MAXWEAPONS		32
#define MAXGRENADES		6
#define WEIGHT_WEAPON	10
#define WEIGHT_GRENADE	50

public Plugin myinfo = {
	name = "YADM: weapon",
	author = "Hendrik Reker",
	description = "Yet Another Dice Module: weapon",
	version = "$version$",
	url = "https://github.com/reker-/YADP"
};

static int g_modIndexWeapon = -1;
static int g_modIndexGrenade = -1;
static ConVar g_cvGrenadeMax = null;
static ConVar g_cvGrenadeMin = null;


static char g_wNames[MAXWEAPONS][2][15] = {
	{"negev", "Negev"}, 
	{"m249", "M249"},
	{"awp", "AWP"},
	{"g3sg1", "G3SG1"},
	{"scar20", "SCAR-20"},
	{"ssg08", "SSG 08"},
	{"ak47", "AK-47"},
	{"m4a1", "M4A1"},
	{"sg556", "SG 556"},
	{"aug", "AUG"},
	{"galilar", "Galil AR"},
	{"famas", "FAMAS"},
	{"nova", "Nova"},
	{"xm1014", "XM1014"},
	{"sawedoff", "Sawed-Off"},
	{"mag7", "MAG-7"},
	{"mac10", "MAC-10"},
	{"mp9", "MP9"},
	{"mp7", "MP7"},
	{"ump45", "UMP-45"},
	{"bizon", "PP-Bizon"},
	{"p90", "P90"},
	{"taser", "Zeus x27"},
	{"glock", "Glock-18"},
	{"hkp2000", "P2000"},
	{"usp_silencer", "USP-S"},
	{"p250", "P250"},
	{"deagle", "Desert Eagle"},
	{"elite", "Dual Berettas"},
	{"tec9", "Tec-9"},
	{"fiveseven", "Five-SeveN"},
	{"cz75a", "CZ75-Auto"},
};

static char g_gNames[MAXGRENADES][2][20] = {
	{"molotov", "Molotov cocktail"},
	{"incgrenade", "Incendiary grenade"},
	{"c4", "C4"},
	{"smokegrenade", "Smoke grenade"},
	{"flashbang", "Flashbang"},
	{"hegrenade", "HE grenade"},
};

static ConVar g_cVarsWeapons[MAXWEAPONS][4];
static ConVar g_cVarsGrenades[MAXGRENADES][4];

public void OnLibraryAdded(const char[] name) {
	if (!StrEqual(name, YADPLIB_NAME)) return;
	Register_OnModuleInit(ModuleInit);
	Register_OnModuleConf(ModuleConf);
}

public void OnLibraryRemoved(const char[] name) {
	if (StrEqual(name, YADPLIB_NAME)) return;
	g_modIndexWeapon = -1;
	g_modIndexGrenade = -1;
}

static void ModuleInit() {
	g_modIndexWeapon = RegisterModule("Weapon", "Players may get random weapons", WEIGHT_WEAPON, ModuleTeam_Any);
	Register_OnDiced(g_modIndexWeapon, HandleDicedWeapon);
	g_modIndexGrenade = RegisterModule("Grenade", "Players may get random grenades", WEIGHT_GRENADE, ModuleTeam_Any);
	Register_OnDiced(g_modIndexGrenade, HandleDicedGrenade);
	CreateConVars();
	AutoExecConfig(true, "plugin.YADP.Weapon");
}

static void ModuleConf() {

}

static void HandleDicedWeapon(int client) {
	if(g_modIndexWeapon < 0) return;
	GiveItem(client, GetRandomItem(GetClientTeam(client), true), true);
}

static void HandleDicedGrenade(int client) {
	if(g_modIndexGrenade < 0) return;
	GiveItem(client, GetRandomItem(GetClientTeam(client), false), false);
}

static void GiveItem(int client, int idx, bool weapon) {
	if((weapon && (idx < 0 || idx > MAXWEAPONS)) || (!weapon && (idx < 0 || idx > MAXGRENADES))) return;
	char wType[40];
	char wName[40];
	int amount = 1;
	if(weapon) {
		Format(wType, sizeof(wType), "weapon_%s", g_wNames[idx][0]);
		Format(wName, sizeof(wName), "you got a %s.", g_wNames[idx][1]);
	} else {
		amount = GetRandomInt(GetMinGrenadeAmount(), GetMaxGrenadeAmount());
		Format(wType, sizeof(wType), "weapon_%s", g_gNames[idx][0]);
		Format(wName, sizeof(wName), "you got %d %s.", amount, g_gNames[idx][1]);
	}
	for(int i = 0; i < amount; i++) {
		GivePlayerItem(client, wType);
	}
	SendChatMessage(client, wName);
}

static int GetMaxGrenadeAmount() {
	return GetConVarInt(g_cvGrenadeMax);
}

static int GetMinGrenadeAmount() {
	return GetConVarInt(g_cvGrenadeMin);
}

static void CreateConVars() {
	for(int i = 0; i < MAXWEAPONS; i++) {
		char cvVal[10];
		IntToString(i * 10, cvVal, sizeof(cvVal));
		g_cVarsWeapons[i][0] = CreateItemConVarEnable(g_wNames[i][0], g_wNames[i][1], true, true, "1");
		g_cVarsWeapons[i][1] = CreateItemConVarEnable(g_wNames[i][0], g_wNames[i][1], true, false, (i >= 22 ? "1" : "0"));
		g_cVarsWeapons[i][2] = CreateItemConVarWeight(g_wNames[i][0], g_wNames[i][1], true, true, "100");
		g_cVarsWeapons[i][3] = CreateItemConVarWeight(g_wNames[i][0], g_wNames[i][1], true, false, cvVal);
	}
	for(int i = 0; i < MAXGRENADES; i++) {
		g_cVarsGrenades[i][0] = CreateItemConVarEnable(g_gNames[i][0], g_gNames[i][1], false, true, "1");
		g_cVarsGrenades[i][1] = CreateItemConVarEnable(g_gNames[i][0], g_gNames[i][1], false, false, "1");
		g_cVarsGrenades[i][2] = CreateItemConVarWeight(g_gNames[i][0], g_gNames[i][1], false, true, "100");
		g_cVarsGrenades[i][3] = CreateItemConVarWeight(g_gNames[i][0], g_gNames[i][1], false, false, "100");
	}
	g_cvGrenadeMax = CreateConVar("yadp_grenade_max", "5", "Upper bound of grenades a player might get.", FCVAR_PLUGIN, true, 1.0);
	g_cvGrenadeMin = CreateConVar("yadp_grenade_min", "1", "Lower bound of grenades a player might get.", FCVAR_PLUGIN, true, 1.0);
}

static ConVar CreateItemConVarEnable(const char[] name, const char[] lName, bool weapon, bool ct, const char[] defVal) {
	char cvName[50];
	char cvDesc[128];
	Format(cvName, sizeof(cvName), "yadp_%s_%s_enable_%s", (weapon?"weapon":"grenade"), (ct?"ct":"t"), name);
	Format(cvDesc, sizeof(cvDesc), "Are %ss allowed to get a %s?", (ct?"CT":"T"), lName);
	return CreateConVar(cvName, defVal, cvDesc, FCVAR_PLUGIN, true, 0.0, true, 1.0);
}


static ConVar CreateItemConVarWeight(const char[] name, const char[] lName, bool weapon, bool ct, const char[] defVal) {
	char cvName[50];
	char cvDesc[128];
	Format(cvName, sizeof(cvName), "yadp_%s_%s_weight_%s", (weapon?"weapon":"grenade"), (ct?"ct":"t"), name);
	Format(cvDesc, sizeof(cvDesc), "Determines the probability of %ss getting a %s", (ct?"CT":"T"), lName);
	return CreateConVar(cvName, defVal, cvDesc, FCVAR_PLUGIN, true, 0.0);
}

static bool CanGetItem(int idx, int team, bool weapon) {
	if((weapon && (idx < 0 || idx > MAXWEAPONS)) || (!weapon && (idx < 0 || idx > MAXGRENADES))) return false;
	if(weapon)
		return GetConVarInt(g_cVarsWeapons[idx][(team == 3 ? 0 : 1)]) == 1;
	else
		return GetConVarInt(g_cVarsGrenades[idx][(team == 3 ? 0 : 1)]) == 1; 
}

static int GetWeightItem(int idx, int team, bool weapon) {
	if((weapon && (idx < 0 || idx > MAXWEAPONS)) || (!weapon && (idx < 0 || idx > MAXGRENADES))) return false;
	if(weapon)
		return GetConVarInt(g_cVarsWeapons[idx][(team == 3 ? 2 : 3)]);
	else
		return GetConVarInt(g_cVarsGrenades[idx][(team == 3 ? 2 : 3)]); 
}

static int GetRandomItem(int team, bool weapon) {
	int sumWght = 0;
	for(int i = 0; i < (weapon ? MAXWEAPONS : MAXGRENADES); i++) {
		if(!CanGetItem(i, team, weapon)) continue;
		sumWght += GetWeightItem(i, team, weapon);
	}
	int rndIdx = GetRandomInt(0, sumWght);
	int selIdx = 0;
	for(int i = 0; i < (weapon ? MAXWEAPONS : MAXGRENADES); i++) {
		if(!CanGetItem(i, team, weapon)) continue;
		if(rndIdx < GetWeightItem(i, team, weapon)) {
			selIdx = i;
			break;
		}
		rndIdx -= GetWeightItem(i, team, weapon);
	}
	return selIdx;
}