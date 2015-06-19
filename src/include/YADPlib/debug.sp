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
#include <YADPlib>

YAPD_Debug_LogLevel:g_LogLevel = YAPD_Debug_LogLevel:LevelInfo;
new ConVar:g_cvLoglevel;

public YAPD_Debug_Initialize() {
	CreateConfig();
	YAPD_Debug_LogMessage("debug", "initialized", YAPD_Debug_LogMode:LogServer, YAPD_Debug_LogLevel:LevelInfo);
}

public YAPD_Debug_Configure() {
	ApplyConfig();
}

CreateConfig() {
	g_cvLoglevel = CreateConVar("yadp_loglevel", "1", "Determines what messages will be ignored. (1,2,4 or 8)", (FCVAR_PLUGIN), true, float(_:LevelInfo), true, float(_:LevelCritical));
}

ApplyConfig() {
	new lvl = GetConVarInt(g_cvLoglevel);
	switch(lvl) {
		case 1:
			g_LogLevel = YAPD_Debug_LogLevel:LevelInfo;
		case 2:
			g_LogLevel = YAPD_Debug_LogLevel:LevelWarning;
		case 4:
			g_LogLevel = YAPD_Debug_LogLevel:LevelError;
		case 8:
			g_LogLevel = YAPD_Debug_LogLevel:LevelCritical;
		default:
			g_LogLevel = YAPD_Debug_LogLevel:LevelInfo;
	}
}

public YAPD_Debug_LogMessage(String:src[], String:msg[], YAPD_Debug_LogMode:mode, YAPD_Debug_LogLevel:level) {
	if(level < g_LogLevel) return;
	decl String:msgStr[256];
	decl String:timeStr[20];
	decl String:srcStr[8];
	FormatTime(timeStr, sizeof(timeStr), "%Y-%m-%d %H:%M:%S", -1);
	strcopy(srcStr, 8, src);
	Format(msgStr, sizeof(msgStr), "[YADP][%s][%s]: %s", timeStr, srcStr, msg);
	if((mode & YAPD_Debug_LogMode:LogClient) == YAPD_Debug_LogMode:LogClient) {
		YAPD_Util_PrintToConsoleAll(msgStr);
	}
	if((mode & YAPD_Debug_LogMode:LogServer) == YAPD_Debug_LogMode:LogServer) {
		PrintToServer(msgStr);
	}
	if((mode & YAPD_Debug_LogMode:LogFile) == YAPD_Debug_LogMode:LogFile) {
		decl String:logPath[PLATFORM_MAX_PATH];
		YAPD_Debug_GetLogFilePath(logPath, PLATFORM_MAX_PATH);
		if(!YAPD_Util_AppendToFile(logPath, msgStr)) {
			YAPD_Debug_LogMessage("debug", "Can not open log file.", YAPD_Debug_LogMode:LogServer, YAPD_Debug_LogLevel:LevelError);
			YAPD_Debug_LogMessage("debug", logPath, YAPD_Debug_LogMode:LogServer, YAPD_Debug_LogLevel:LevelError);
		}
	}
}

public YAPD_Debug_GetLogFilePath(String:path[], maxlength) {
	if(maxlength < PLATFORM_MAX_PATH) {
		YAPD_Debug_LogMessage("debug", "Logfile path buffer was too small.", YAPD_Debug_LogMode:LogServer, YAPD_Debug_LogLevel:LevelError);
		return;
	}
	decl String:dateStr[9];
	decl String:filePath[28];
	FormatTime(dateStr, sizeof(dateStr), "%Y%m%d", -1);
	filePath = "logs/YADP/";
	YAPD_Util_RequireDir(filePath);
	Format(filePath, sizeof(filePath), "logs/YADP/%s.log", dateStr);
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, filePath);
}