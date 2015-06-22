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
 * Version: 0.0.0.219
 * Authors: Hendrik Reker
 */
#if defined _YADPLIB_INCLUDED
	#endinput
#endif
#define _YADPLIB_INCLUDED
#pragma newdecls required

#include <YADPlib/util>
#include <YADPlib/debug>
#include <YADPlib/config>
#include <YADPlib/module>
#include <YADPlib/chat>
#include <YADPlib/command>

#define	YADPLIB_VERSION		"0.0.0.219"
#define	YADPLIB_BUILD_DATE	"2015-06-22"

static ConVar g_cvVersion;
static ConVar g_cvEnabled;
static bool g_InitializedYADP = false;
static bool g_ConfiguredYADP = false;

stock bool YADP_Initialize() {
	LoadTranslations("yadp.phrases.txt");
	char msgStr[128];
	g_cvEnabled = CreateConVar("yadp_enabled", "1", "Toggles YADP", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvVersion = CreateConVar("yadp_version", YADPLIB_VERSION, "The version of YADP", (FCVAR_PLUGIN|FCVAR_DONTRECORD));
	if(g_cvEnabled == null || g_cvVersion == null) {
		char errMsg[40];
		Format(errMsg, sizeof(errMsg), "%T", "yadp_main_ConVarFailed", LANG_SERVER);
		YADP_Debug_LogMessage("global", errMsg, (LogServer | LogFile), LevelCritical);
		return false;
	}
	
	YADP_Initialize_Util();
	YADP_Initialize_Debug();
	YADP_Initialize_Config();
	YADP_Initialize_Module();
	YADP_Initialize_Chat();
	YADP_Initialize_Command();

	AutoExecConfig(true, "plugin.YADP");
	
	if(GetConVarInt(g_cvEnabled) != 1) return false;
	g_InitializedYADP = true;
	
	Format(msgStr, sizeof(msgStr), "%T", "yadp_main_InitVersion", LANG_SERVER, YADPLIB_VERSION, YADPLIB_BUILD_DATE);
	YADP_Debug_LogMessage("global", msgStr, (LogServer | LogFile), LevelCritical);
	return g_InitializedYADP;
}

stock bool YADP_Configure() {
	if(!g_InitializedYADP) return false;
	YADP_Configure_Util();
	YADP_Configure_Debug();
	YADP_Configure_Config();
	YADP_Configure_Module();
	YADP_Configure_Chat();
	YADP_Configure_Command();
	g_ConfiguredYADP = true;
	return g_ConfiguredYADP;
}