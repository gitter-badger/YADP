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
#include "YADPlib/util.sp"
#include "YADPlib/debug.sp"
#include "YADPlib/config.sp"
#include "YADPlib/command.sp"

public Plugin:myinfo = {
	name = "YADP",
	author = "Hendrik Reker",
	description = "Yet Another Dice Plugin",
	version = "$version$",
	url = "https://github.com/reker-/YADP"
};

public OnPluginStart() {
	YAPD_Initialize();
	YADP_Configure();
	if(g_InitializedYADP && !g_ConfiguredYADP) 
		YAPD_Debug_LogMessage("global", "could not configure YADP.", (YAPD_Debug_LogMode:LogServer | YAPD_Debug_LogMode:LogFile), YAPD_Debug_LogLevel:LevelCritical);
}

public OnConfigsExecuted() {
}