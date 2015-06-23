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
 * Version: 0.0.0.252
 * Authors: Hendrik Reker
 */
#if defined _YADP_INCLUDED
	#endinput
#endif
#define _YADP_INCLUDED
#pragma newdecls required

#define	YADP_VERSION		"0.0.0.252"
#define	YADP_BUILD_DATE		"2015-06-23"

#if !defined _YADPLIB_MODULE_INCLUDED

#define MAXMODULENAME	10
#define MAXMODULEDESC	100

typedef OnDicedCallback = function void(int client);

enum YADP_Module_Team {
	ModuleTeam_Any	= 0x1,
	ModuleTeam_T 	= 0x2,
	ModuleTeam_CT	= 0x3,
}

#endif

typedef ModuleCallback = function void();

native void Register_OnModuleInit(ModuleCallback f);
native void Register_OnModuleConf(ModuleCallback f);
native int RegisterModule(char[] name, char[] desc, int weight, YADP_Module_Team team, OnDicedCallback callback);
native void SendChatMessage(int client, char[] msg);

#pragma newdecls optional