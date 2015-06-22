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
#include <YADPlib>

public Plugin myinfo = {
	name = "YADP",
	author = "Hendrik Reker",
	description = "Yet Another Dice Plugin",
	version = "$version$",
	url = "https://github.com/reker-/YADP"
};

Handle g_hOnModuleInit;
Handle g_hOnModuleConf;

public void OnPluginStart() {
	g_hOnModuleInit = CreateForward(ET_Ignore);
	g_hOnModuleConf = CreateForward(ET_Ignore);
	
	YAPD_Initialize();
	YADP_Configure();
	SendOnModuleInit();
	SendOnModuleConf();
	if(g_InitializedYADP && !g_ConfiguredYADP) 
		YAPD_Debug_LogMessage("global", "could not configure YADP.", (LogServer | LogFile), LevelCritical);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("RegOnModuleInitEx", RegOnModuleInit);
	CreateNative("RegOnModuleConfEx", RegOnModuleConf);
	RegPluginLibrary("yadplib");
	return APLRes_Success;
}

int RegOnModuleInit(Handle plugin, int numParams) {
	AddToForward(g_hOnModuleInit, plugin, GetNativeFunction(1));
}

int RegOnModuleConf(Handle plugin, int numParams) {
	AddToForward(g_hOnModuleConf, plugin, GetNativeFunction(1));
}

void SendOnModuleInit() {
	Call_StartForward(g_hOnModuleInit);
	Call_Finish();
}

void SendOnModuleConf() {
	Call_StartForward(g_hOnModuleConf);
	Call_Finish();
}