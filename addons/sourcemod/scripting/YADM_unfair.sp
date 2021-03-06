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
#include <sourcemod>
#pragma newdecls required
#include <YADP>

public Plugin myinfo = {
	name = "YADM: ",
	author = "Hendrik Reker",
	description = "Yet Another Dice Module: ",
	version = "$version$",
	url = "https://github.com/reker-/YADP"
};

static int g_modIndex = -1;

public void OnLibraryAdded(const char[] name)
{
	if (!StrEqual(name, YADPLIB_NAME))
	{
		return;
	}
	YADP_RegisterOnInit(ModuleInit);
	YADP_RegisterOnConf(ModuleConf);
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, YADPLIB_NAME))
	{
		return;
	}
	g_modIndex = -1;
}

static void ModuleInit()
{
	g_modIndex = YADP_RegisterModule("name", "desc", 50, ModuleTeam_Any);
	YADP_RegisterOnDice(g_modIndex, HandleDiced, ResetDiced);
}

static void ModuleConf()
{

}

static void HandleDiced(int client)
{
	if(g_modIndex < 0 || !YADP_IsValidClient(client, true))
	{
		return;
	}
}

static void ResetDiced(int client)
{
	if(g_modIndex < 0 || !YADP_IsValidClient(client, true))
	{
		return;
	}
}