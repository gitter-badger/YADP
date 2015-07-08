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
#if defined _YADPLIB_DATABASE_INCLUDED
	#endinput
#endif
#define _YADPLIB_DATABASE_INCLUDED
#include <YADPlib/debug>

stock void YADP_Initialize_Database()
{
	char msg[40];
	Format(msg, sizeof(msg), "%T", "yadp_main_Init", LANG_SERVER);
	YADP_Debug_LogMessage("database", msg, LogServer, LevelInfo);
}

stock void YADP_Configure_Database()
{

}