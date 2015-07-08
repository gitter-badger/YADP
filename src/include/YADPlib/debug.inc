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
 * GitBase: $git-branch$ / $git-hash-long$
 * Authors: Hendrik Reker
 */
#if defined _YADPLIB_DEBUG_INCLUDED
	#endinput
#endif
#define _YADPLIB_DEBUG_INCLUDED

enum YADP_Debug_LogMode {
	LogClient	= 0x01,
	LogServer	= 0x02,
	LogFile		= 0x04,
};

enum YADP_Debug_LogLevel {
	LevelInfo		= 0x01,
	LevelWarning	= 0x02,
	LevelError		= 0x04,
	LevelCritical	= 0x08,
};

static YADP_Debug_LogLevel g_LogLevel = LevelInfo;
static ConVar g_cvLoglevel;

stock void YADP_Initialize_Debug()
{
	char msg[40];
	CreateConfig();
	Format(msg, sizeof(msg), "%T", "yadp_main_Init", LANG_SERVER);
	YADP_Debug_LogMessage("debug", "initialized.", LogServer, LevelInfo);
}

stock void YADP_Configure_Debug()
{
	ApplyConfig();
}

static void CreateConfig()
{
	g_cvLoglevel = CreateConVar("yadp_loglevel", "1", "Determines what messages will be ignored. (1,2,4 or 8)", (FCVAR_PLUGIN), true, float(view_as<int>(LevelInfo)), true, float(view_as<int>(LevelCritical)));
}

static void ApplyConfig()
{
	int lvl = GetConVarInt(g_cvLoglevel);
	switch(lvl)
	{
		case LevelInfo:
		{
			g_LogLevel = LevelInfo;
		}
		case LevelWarning:
		{
			g_LogLevel = LevelWarning;
		}
		case LevelError:
		{
			g_LogLevel = LevelError;
		}
		case LevelCritical:
		{
			g_LogLevel = LevelCritical;
		}
		default:
		{		
			g_LogLevel = LevelInfo;
		}
	}
}

stock void YADP_Debug_LogMessage(const char[] src, const char[] msg, YADP_Debug_LogMode mode, YADP_Debug_LogLevel level)
{
	if(level < g_LogLevel)
	{
		return;
	}
	char msgStr[256];
	char timeStr[20];
	char srcStr[8];
	FormatTime(timeStr, sizeof(timeStr), "%Y-%m-%d %H:%M:%S", -1);
	strcopy(srcStr, 8, src);
	Format(msgStr, sizeof(msgStr), "[YADP][%s][%s]: %s", timeStr, srcStr, msg);
	if((mode & LogClient) == LogClient)
	{
		YADP_Util_PrintToConsoleAll(msgStr);
	}
	if((mode & LogServer) == LogServer)
	{
		PrintToServer(msgStr);
	}
	if((mode & LogFile) == LogFile)
	{
		char logPath[PLATFORM_MAX_PATH];
		YADP_Debug_GetLogFilePath(logPath, PLATFORM_MAX_PATH);
		if(!YADP_Util_AppendToFile(logPath, msgStr))
		{
			char errMsg[40];
			Format(errMsg, sizeof(errMsg), "%T", "yadp_main_LogFileFailed", LANG_SERVER)
			YADP_Debug_LogMessage("debug", errMsg, LogServer, LevelError);
			YADP_Debug_LogMessage("debug", logPath, LogServer, LevelError);
		}
	}
}

stock int YADP_Debug_LogMessageNative(Handle plugin, int numParams)
{
	if(numParams != 3)
	{
		return 0;
	}
	char pName[10];
	char nMsg[256];
	GetNativeString(1, nMsg, sizeof(nMsg));
	YADP_Debug_LogMode mode = view_as<YADP_Debug_LogMode>(GetNativeCell(2));
	YADP_Debug_LogLevel lvl = view_as<YADP_Debug_LogLevel>(GetNativeCell(3));
	GetPluginFilename(plugin, pName, sizeof(pName));
	YADP_Debug_LogMessage(pName, nMsg, mode, lvl);
	return 0;
}

stock void YADP_Debug_GetLogFilePath(char[] path, int maxlength)
{
	if(maxlength < PLATFORM_MAX_PATH)
	{
		char errMsg[40];
		Format(errMsg, sizeof(errMsg), "%T", "yadp_main_LogFileBuffer", LANG_SERVER);
		YADP_Debug_LogMessage("debug", errMsg, LogServer, LevelError);
		return;
	}
	char dateStr[9];
	FormatTime(dateStr, sizeof(dateStr), "%Y%m%d", -1);
	YADP_Util_RequireDir("logs/YADP/");
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "logs/YADP/%s.log", dateStr);
}