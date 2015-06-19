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

#include <YADPlib/util>
#include <YADPlib/debug>
#include <YADPlib/config>
#include <YADPlib/command>

#define	YADPLIB_VERSION		"$version$"
#define	YADPLIB_BUILD_DATE	"$date$"



new Handle:g_cvVersion = INVALID_HANDLE;
stock YAPD_Initialize() {
	new String:msgStr[128];
	YAPD_Util_Initialize();
	YAPD_Debug_Initialize();
	YAPD_Config_Initialize();
	YAPD_Command_Initialize();
	
	g_cvVersion = CreateConVar("yadp_version", YADPLIB_VERSION, "The version of YADP", (FCVAR_PLUGIN|FCVAR_DONTRECORD));
	
	AutoExecConfig(true, "plugin.YADP");
	
	Format(msgStr, sizeof(msgStr), "initialized. V<%s/%s>", YADPLIB_VERSION, YADPLIB_BUILD_DATE);
	YAPD_Debug_LogMessage("global", msgStr, (YAPD_Debug_LogMode:LogServer | YAPD_Debug_LogMode:LogFile), YAPD_Debug_LogLevel:LevelCritical);
}

stock YADP_Configure() {
	YAPD_Util_Configure();
	YAPD_Debug_Configure();
	YAPD_Config_Configure();
	YAPD_Command_Configure();
}