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
#if defined _YADP_INCLUDED
	#endinput
#endif
#define _YADP_INCLUDED
#pragma newdecls required

#define	YADP_VERSION		"$version$"
#define	YADP_BUILD_DATE		"$date$"
#define __RELEASE__			$release$
#define __DEBUG__			$debug$

#if !defined _YADPLIB_INCLUDED

#define YADPLIB_NAME		"yadplib"

#endif

#if !defined _YADPLIB_MODULE_INCLUDED

#define MAXMODULENAME	10
#define MAXMODULEDESC	100

typedef GeneralCallback = function void(int client);

enum YADP_Module_Team {
	ModuleTeam_Any	= 0x1,
	ModuleTeam_T 	= 0x2,
	ModuleTeam_CT	= 0x3,
}

#endif

#if !defined _YADPLIB_DEBUG_INCLUDED

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

#endif

typedef ModuleCallback = function void();

native void RegOnModuleInit(ModuleCallback f);
native void RegOnModuleConf(ModuleCallback f);
native void RegOnDiced(int idx, GeneralCallback OnDiced, GeneralCallback OnReset);
native int RegisterModule(char[] name, char[] desc, int weight, YADP_Module_Team team);
native void SendChatMessage(int client, char[] msg);
native void LogModuleMessage(const char[] msg, YADP_Debug_LogMode mode, YADP_Debug_LogLevel level);
native bool IsValidClient(int client, bool botsAllowed);
native void SetAttempts(int client, int number);
native int GetAttempts(int client);

#pragma newdecls optional