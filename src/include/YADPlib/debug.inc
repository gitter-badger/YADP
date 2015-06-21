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
#if defined _YADPLIB_DEBUG_INCLUDED
	#endinput
#endif
#define _YADPLIB_DEBUG_INCLUDED

enum YAPD_Debug_LogMode {
	LogClient	= 0x01,
	LogServer	= 0x02,
	LogFile		= 0x04,
};

enum YAPD_Debug_LogLevel {
	LevelInfo		= 0x01,
	LevelWarning	= 0x02,
	LevelError		= 0x04,
	LevelCritical	= 0x08,
};

static YAPD_Debug_LogLevel g_LogLevel = LevelInfo;
static ConVar g_cvLoglevel;

stock void YAPD_Initialize_Debug() {
	CreateConfig();
	YAPD_Debug_LogMessage("debug", "initialized.", LogServer, LevelInfo);
}

stock void YAPD_Configure_Debug() {
	ApplyConfig();
}

static void CreateConfig() {
	g_cvLoglevel = CreateConVar("yadp_loglevel", "1", "Determines what messages will be ignored. (1,2,4 or 8)", (FCVAR_PLUGIN), true, float(view_as<int>(LevelInfo)), true, float(view_as<int>(LevelCritical)));
}

static void ApplyConfig() {
	int lvl = GetConVarInt(g_cvLoglevel);
	switch(lvl) {
		case LevelInfo:
			g_LogLevel = LevelInfo;
		case LevelWarning:
			g_LogLevel = LevelWarning;
		case LevelError:
			g_LogLevel = LevelError;
		case LevelCritical:
			g_LogLevel = LevelCritical;
		default:
			g_LogLevel = LevelInfo;
	}
}

stock void YAPD_Debug_LogMessage(char[] src, char[] msg, YAPD_Debug_LogMode mode, YAPD_Debug_LogLevel level) {
	if(level < g_LogLevel) return;
	char msgStr[256];
	char timeStr[20];
	char srcStr[8];
	FormatTime(timeStr, sizeof(timeStr), "%Y-%m-%d %H:%M:%S", -1);
	strcopy(srcStr, 8, src);
	Format(msgStr, sizeof(msgStr), "[YADP][%s][%s]: %s", timeStr, srcStr, msg);
	if((mode & LogClient) == LogClient) {
		YAPD_Util_PrintToConsoleAll(msgStr);
	}
	if((mode & LogServer) == LogServer) {
		PrintToServer(msgStr);
	}
	if((mode & LogFile) == LogFile) {
		char logPath[PLATFORM_MAX_PATH];
		YAPD_Debug_GetLogFilePath(logPath, PLATFORM_MAX_PATH);
		if(!YAPD_Util_AppendToFile(logPath, msgStr)) {
			YAPD_Debug_LogMessage("debug", "Can not open log file.", LogServer, LevelError);
			YAPD_Debug_LogMessage("debug", logPath, LogServer, LevelError);
		}
	}
}

stock void YAPD_Debug_GetLogFilePath(char[] path, int maxlength) {
	if(maxlength < PLATFORM_MAX_PATH) {
		YAPD_Debug_LogMessage("debug", "Logfile path buffer was too small.", LogServer, LevelError);
		return;
	}
	char dateStr[9];
	char filePath[28];
	FormatTime(dateStr, sizeof(dateStr), "%Y%m%d", -1);
	filePath = "logs/YADP/";
	YAPD_Util_RequireDir(filePath);
	Format(filePath, sizeof(filePath), "logs/YADP/%s.log", dateStr);
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, filePath);
}