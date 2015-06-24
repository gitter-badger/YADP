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
 * Version: 0.0.0.294
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

#define	YADPLIB_VERSION		"0.0.0.294"
#define	YADPLIB_BUILD_DATE	"2015-06-24"
#define YADPLIB_NAME		"yadplib"

static ConVar g_cvVersion;
static ConVar g_cvEnabled;
static bool g_InitializedYADP = false;
static bool g_ConfiguredYADP = false;
static bool g_CreatedYADP = false;
static Handle g_hOnModuleInit;
static Handle g_hOnModuleConf;

stock void YADP_Create() {
	if(g_CreatedYADP) return;
	CreateNative("Register_OnModuleInit", RegOnModuleInit);
	CreateNative("Register_OnModuleConf", RegOnModuleConf);
	CreateNative("Register_OnDiced", RegOnDiced);
	CreateNative("RegisterModule", RegModule);
	CreateNative("SendChatMessage", SendToClient);
	RegPluginLibrary(YADPLIB_NAME);
	g_CreatedYADP = true;
}

stock bool YADP_Initialize() {
	LoadTranslations("yadp.phrases.txt");
	char msgStr[128];
	g_hOnModuleInit = CreateForward(ET_Ignore);
	g_hOnModuleConf = CreateForward(ET_Ignore);
	g_cvEnabled = CreateConVar("yadp_enabled", "1", "Toggles YADP", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvVersion = CreateConVar("yadp_version", YADPLIB_VERSION, "The version of YADP", (FCVAR_PLUGIN|FCVAR_DONTRECORD));
	if(g_cvEnabled == null || g_cvVersion == null) {
		char errMsg[40];
		Format(errMsg, sizeof(errMsg), "%T", "yadp_main_ConVarFailed", LANG_SERVER);
		YADP_Debug_LogMessage("global", errMsg, (LogServer | LogFile), LevelCritical);
		return false;
	}
	
	YADP_Initialize_Util();
	YADP_Initialize_Debug();
	YADP_Initialize_Config();
	YADP_Initialize_Module();
	YADP_Initialize_Chat();
	YADP_Initialize_Command();

	AutoExecConfig(true, "plugin.YADP");
	
	if(GetConVarInt(g_cvEnabled) != 1) return false;
	g_InitializedYADP = true;
	
	Format(msgStr, sizeof(msgStr), "%T", "yadp_main_InitVersion", LANG_SERVER, YADPLIB_VERSION, YADPLIB_BUILD_DATE);
	YADP_Debug_LogMessage("global", msgStr, (LogServer | LogFile), LevelCritical);
	return g_InitializedYADP;
}

stock bool YADP_Configure() {
	if(!g_InitializedYADP) return false;
	YADP_Configure_Util();
	YADP_Configure_Debug();
	YADP_Configure_Config();
	YADP_Configure_Module();
	YADP_Configure_Chat();
	YADP_Configure_Command();
	g_ConfiguredYADP = true;
	return g_ConfiguredYADP;
}

stock void YADP_EnableModules() {
	YADP_Module_RegisterEnable();
	SendOnModuleInit();
	YADP_Module_RegisterDisable();
	SendOnModuleConf();
}

static int RegOnModuleInit(Handle plugin, int numParams) {
	if(numParams != 1 || !g_InitializedYADP) return 0;
	char pName[50];
	char msg[128];
	GetPluginFilename(plugin, pName, sizeof(pName));
	Format(msg, sizeof(msg), "%T", "yadp_main_ModInit", LANG_SERVER, pName);
	YADP_Debug_LogMessage("global", msg, LogFile, LevelInfo);
	AddToForward(g_hOnModuleInit, plugin, GetNativeFunction(1));
	return 0;
}

static int RegOnModuleConf(Handle plugin, int numParams) {
	if(numParams != 1 || !g_InitializedYADP) return 0;
	char pName[50];
	char msg[128];
	GetPluginFilename(plugin, pName, sizeof(pName));
	Format(msg, sizeof(msg), "%T", "yadp_main_ModConf", LANG_SERVER, pName);
	YADP_Debug_LogMessage("global", msg, LogFile, LevelInfo);
	AddToForward(g_hOnModuleConf, plugin, GetNativeFunction(1)); 
	return 0;
}

static int RegOnDiced(Handle plugin, int numParams) {
	if(numParams != 2 || !g_InitializedYADP) return 0;
	int modIdx = GetNativeCell(1);
	Handle fwd = YADP_Module_GetHandle(modIdx);
	if(fwd == null) return -1;
	char pName[50];
	char msg[128];
	GetPluginFilename(plugin, pName, sizeof(pName));
	Format(msg, sizeof(msg), "%T", "yadp_main_RegOnDiced", LANG_SERVER, modIdx, pName);
	YADP_Debug_LogMessage("global", msg, LogFile, LevelInfo);
	
	AddToForward(fwd, plugin, GetNativeFunction(2)); 
	return 0;
}

static int RegModule(Handle plugin, int numParams) {
	if(numParams != 4 || !g_InitializedYADP) return 0;
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

static int SendToClient(Handle plugin, int numParams) {
	if(numParams != 2 || !g_InitializedYADP) return 0;
	int clt = GetNativeCell(1);
	char msg[256];
	GetNativeString(2, msg, sizeof(msg));
	char pName[50];
	char cAuth[50];
	char lmsg[306];
	if(YADP_Util_isValidClient(clt))
		GetClientAuthId(clt, AuthId_SteamID64, cAuth, sizeof(cAuth), true);
	else
		cAuth = "<missing-auth>"
	GetPluginFilename(plugin, pName, sizeof(pName));
	Format(lmsg, sizeof(lmsg), "%T", "yadp_main_ModMsg", LANG_SERVER, pName, cAuth, msg);
	YADP_Debug_LogMessage("global", lmsg, LogFile, LevelInfo);
	YADP_Chat_PrintToChat(clt, msg);
	return 0;
}

static void SendOnModuleInit() {
	if(!g_InitializedYADP) return;
	Call_StartForward(g_hOnModuleInit);
	Call_Finish();
}

static void SendOnModuleConf() {
	if(!g_InitializedYADP) return;
	Call_StartForward(g_hOnModuleConf);
	Call_Finish();
}