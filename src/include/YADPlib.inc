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
#if defined _YADPLIB_INCLUDED
	#endinput
#endif
#define _YADPLIB_INCLUDED
#pragma newdecls required

#include <YADPlib/util>
#include <YADPlib/debug>
#include <YADPlib/config>
#include <YADPlib/module>
#include <YADPlib/chat>
#include <YADPlib/command>
#include <YADPlib/database>

#pragma newdecls optional
#include <smlib>
#pragma newdecls required

#define	YADPLIB_VERSION		"$version$"
#define	YADPLIB_BUILD_DATE	"$date$"
#define YADPLIB_NAME		"yadplib"
#define __RELEASE__			$release$
#define __DEBUG__			$debug$

static ConVar g_cvVersion;
static ConVar g_cvEnabled;
static bool g_InitializedYADP = false;
static bool g_ConfiguredYADP = false;
static bool g_CreatedYADP = false;

stock APLRes YADP_Create(char[] err, int errmax)
{
	if(LibraryExists(YADPLIB_NAME) || g_CreatedYADP)
    {
        strcopy(err, errmax, "YADPlib already exists, aborting.");
        return APLRes_Failure;
    }
	CreateNative("YADP_RegisterOnInit", YADP_Module_RegOnInit);
	CreateNative("YADP_RegisterOnConf", YADP_Module_RegOnConf);
	CreateNative("YADP_RegisterOnDice", YADP_Module_RegOnDiced);
	CreateNative("YADP_RegisterModule", RegModule);
	CreateNative("YADP_SendChatMessage", YADP_Chat_SendToClient);
	CreateNative("YADP_LogModuleMessage", YADP_Debug_LogMessageNative);
	CreateNative("YADP_IsValidClient", YADP_Util_YADP_IsValidClientNative);
	CreateNative("YADP_SetAttempts", YADP_Command_YADP_SetAttemptsNative);
	CreateNative("YADP_GetAttempts", YADP_Command_YADP_GetAttemptsNative);
	RegPluginLibrary(YADPLIB_NAME);
	g_CreatedYADP = true;
	return APLRes_Success;
}

stock bool YADP_Initialize()
{
	LoadTranslations("yadp.phrases.txt");
	char msgStr[128];
	g_cvEnabled = CreateConVar("yadp_enabled", "1", "Toggles YADP", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvVersion = CreateConVar("yadp_version", YADPLIB_VERSION, "The version of YADP", (FCVAR_PLUGIN|FCVAR_DONTRECORD));
	if(g_cvEnabled == null || g_cvVersion == null)
	{
		char errMsg[40];
		Format(errMsg, sizeof(errMsg), "%T", "yadp_main_ConVarFailed", LANG_SERVER);
		YADP_Debug_LogMessage("global", errMsg, (LogServer | LogFile), LevelCritical);
		return false;
	}
	
	YADP_Initialize_Util();
	YADP_Initialize_Debug();
	YADP_Initialize_Config();
	YADP_Initialize_Database();
	YADP_Initialize_Module();
	YADP_Initialize_Chat();
	YADP_Initialize_Command();

	AutoExecConfig(true, "plugin.YADP");
	
	if(GetConVarInt(g_cvEnabled) != 1)
	{ 
		return false; 
	}
	g_InitializedYADP = true;
	
	Format(msgStr, sizeof(msgStr), "%T", "yadp_main_InitVersion", LANG_SERVER, YADPLIB_VERSION, YADPLIB_BUILD_DATE);
	YADP_Debug_LogMessage("global", msgStr, (LogServer | LogFile), LevelCritical);
	return g_InitializedYADP;
}

stock bool YADP_Configure()
{
	if(!g_InitializedYADP)
	{
		return false;
	}
	YADP_Configure_Util();
	YADP_Configure_Debug();
	YADP_Configure_Config();
	YADP_Configure_Database();
	YADP_Configure_Module();
	YADP_Configure_Chat();
	YADP_Configure_Command();
	g_ConfiguredYADP = true;
	return g_ConfiguredYADP;
}

stock void YADP_EnableModules()
{
	YADP_Module_RegisterEnable();
	YADP_Module_SendOnInit();
	YADP_Module_RegisterDisable();
	YADP_Module_SendOnConf();
}

stock bool YADP_Initialized()
{
	return g_InitializedYADP;
}

stock bool YADP_Configured()
{
	return g_ConfiguredYADP;
}

stock bool YADP_Ready()
{
	return g_InitializedYADP && g_ConfiguredYADP;
}

static int RegModule(Handle plugin, int numParams)
{
	if(numParams != 4 || !g_InitializedYADP)
	{	
		return 0;
	}
	char mName[MAXMODULENAME];
	char mDesc[MAXMODULEDESC];
	GetNativeString(1, mName, sizeof(mName));
	GetNativeString(2, mDesc, sizeof(mDesc));
	char pName[50];
	char msg[128];
	GetPluginFilename(plugin, pName, sizeof(pName));
	Format(msg, sizeof(msg), "%T", "yadp_main_ModReg", LANG_SERVER, mName, pName);
	YADP_Debug_LogMessage("global", msg, LogFile, LevelInfo);
	return YADP_Module_Register(mName, mDesc, GetNativeCell(3), view_as<YADP_Module_Team>(GetNativeCell(4)));
}