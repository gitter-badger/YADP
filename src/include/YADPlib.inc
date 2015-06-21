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

#define	YADPLIB_VERSION		"$version$"
#define	YADPLIB_BUILD_DATE	"$date$"

ConVar g_cvVersion;
ConVar g_cvEnabled;
bool g_InitializedYADP = false;
bool g_ConfiguredYADP = false;

stock void YAPD_Initialize() {
	char msgStr[128];
	
	g_cvEnabled = CreateConVar("yadp_enabled", "1", "Toggles YADP", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvVersion = CreateConVar("yadp_version", YADPLIB_VERSION, "The version of YADP", (FCVAR_PLUGIN|FCVAR_DONTRECORD));
	if(g_cvEnabled == null || g_cvEnabled == null) {
		YAPD_Debug_LogMessage("global", "could not register ConVars.", (LogServer | LogFile), LevelCritical);
		return;
	}
	if(GetConVarInt(g_cvEnabled) != 1) return;
	
	YAPD_Initialize_Util();
	YAPD_Initialize_Debug();
	YAPD_Initialize_Config();
	YAPD_Initialize_Module();
	YAPD_Initialize_Chat();
	YAPD_Initialize_Command();

	AutoExecConfig(true, "plugin.YADP");
	g_InitializedYADP = true;
	
	Format(msgStr, sizeof(msgStr), "initialized. V<%s/%s>", YADPLIB_VERSION, YADPLIB_BUILD_DATE);
	YAPD_Debug_LogMessage("global", msgStr, (LogServer | LogFile), LevelCritical);
}

stock void YADP_Configure() {
	if(!g_InitializedYADP) return;
	YAPD_Configure_Util();
	YAPD_Configure_Debug();
	YAPD_Configure_Config();
	YAPD_Configure_Module();
	YAPD_Configure_Chat();
	YAPD_Configure_Command();
	g_ConfiguredYADP = true;
}