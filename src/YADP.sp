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
#pragma newdecls required
#include <YADPlib>

public Plugin myinfo = {
	name = "YADP",
	author = "Hendrik Reker",
	description = "Yet Another Dice Plugin",
	version = "$version$",
	url = "https://github.com/reker-/YADP"
};

public void OnPluginStart()
{
	YADP_Initialize();
	YADP_Configure();
	if(!YADP_Ready())
	{
		char errMsg[40];
		Format(errMsg, sizeof(errMsg), "%T", "yadp_main_ConfigFailed", LANG_SERVER);
		YADP_Debug_LogMessage("global", errMsg, (LogServer | LogFile), LevelCritical);
		return;
	}
}

public void OnAllPluginsLoaded()
{
	YADP_EnableModules();
}

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int err_max)
{
	return YADP_Create(error, err_max);
}