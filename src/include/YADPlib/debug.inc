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

forward YAPD_Initialize_Debug();
forward YAPD_Configure_Debug();
forward YAPD_Debug_LogMessage(String:src[], String:msg[], YAPD_Debug_LogMode:mode, YAPD_Debug_LogLevel:level);
forward YAPD_Debug_GetLogFilePath(String:path[], maxlength);
