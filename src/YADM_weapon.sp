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
#pragma newdecls required
#include <YADP>

public Plugin myinfo = {
	name = "YADM: weapon",
	author = "Hendrik Reker",
	description = "Yet Another Dice Module: weapon",
	version = "$version$",
	url = "https://github.com/reker-/YADP"
};

int g_modIndex = -1;

public void OnAllPluginsLoaded() {
}

public void OnLibraryAdded(const char[] name) {
	if (!StrEqual(name, "yadplib")) return;
	Register_OnModuleInit(ModuleInit);
	Register_OnModuleConf(ModuleConf);
}

public void OnLibraryRemoved(const char[] name) {
	if (StrEqual(name, "yadplib")) return;
	g_modIndex = -1;
}

void ModuleInit() {
	PrintToServer("--init--");
	g_modIndex = RegisterModule("weapon", "Players may get a weapon", 10, ModuleTeam_Any);
	Register_OnDiced(g_modIndex, HandleDiced);
	PrintToServer("--idx: %d", g_modIndex);
}

void ModuleConf() {
	PrintToServer("--conf--");
}

void HandleDiced(int client) {
	if(g_modIndex < 0) return;
	PrintToServer("%N got a weapon.", client);
	SendChatMessage(client, "you got a weapon.");
}