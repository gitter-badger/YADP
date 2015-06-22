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
#if defined _YADPLIB_MODULE_INCLUDED
	#endinput
#endif
#define _YADPLIB_MODULE_INCLUDED

#define MAXMODULES		20
#define MAXMODULENAME	10
#define MAXMODULEDESC	100

typedef OnDiceCallback = function void(int client);

enum YADP_Module_Team {
	ModuleTeam_Any	= 0x1,
	ModuleTeam_T 	= 0x2,
	ModuleTeam_CT	= 0x3,
}

static char g_modNames[MAXMODULES][MAXMODULENAME];
static char g_modDescs[MAXMODULES][MAXMODULEDESC];
static char g_modWghts[MAXMODULES];
static OnDiceCallback g_modCallbacks[MAXMODULES];
static YADP_Module_Team g_modTeam[MAXMODULES];
static int g_modIdx = -1;
static int g_modIdxInvoking = -1;
static bool g_CanRegister = false;

stock void YADP_Initialize_Module() {
	g_CanRegister = true;
	char msg[40];
	Format(msg, sizeof(msg), "%T", "yadp_main_Init", LANG_SERVER);
	YADP_Debug_LogMessage("module", msg, LogServer, LevelInfo);
}

stock void YADP_Configure_Module() {
	g_CanRegister = false;
}

stock int YADP_Module_Register(char[] name, char[] desc, int weight, YADP_Module_Team team, OnDiceCallback callback) {
	char errMsg[128];
	char mName[MAXMODULENAME];
	char mDesc[MAXMODULEDESC];
	strcopy(mName, sizeof(mName), name);
	strcopy(mDesc, sizeof(mDesc), desc);
	if(g_modIdx >= MAXMODULES || !g_CanRegister) {
		Format(errMsg, sizeof(errMsg), "%T", "yadp_main_RegModFail", LANG_SERVER, mName);
		YADP_Debug_LogMessage("module", errMsg, (LogServer | LogFile), LevelError);
		if(!g_CanRegister)
			Format(errMsg, sizeof(errMsg), "%T", "yadp_main_RegModLate", LANG_SERVER);
		else
			Format(errMsg, sizeof(errMsg), "%T", "yadp_main_RegModMax", LANG_SERVER, MAXMODULES);
		YADP_Debug_LogMessage("module", errMsg, (LogServer | LogFile), LevelError);
		return -1;
	}
	g_modIdx++;
	g_modNames[g_modIdx] = mName;
	g_modDescs[g_modIdx] = mDesc;
	g_modWghts[g_modIdx] = weight;
	g_modTeam[g_modIdx] = team;
	g_modCallbacks[g_modIdx] = callback;
	Format(errMsg, sizeof(errMsg), "%T", "yadp_main_RegMod", LANG_SERVER, mName);
	YADP_Debug_LogMessage("module", errMsg, LogServer, LevelInfo);
	return g_modIdx;
}

stock void YADP_Module_GetName(int idx, char[] bufferModName, int bufferModNameMaxLength) {
	if((idx < 0 || idx > g_modIdx) || bufferModNameMaxLength < MAXMODULENAME){
		char errMsg[80];
		if((idx < 0 || idx > g_modIdx))
			Format(errMsg, sizeof(errMsg), "%T", "yadp_main_ModDoesNotExist", LANG_SERVER, idx);
		else
			Format(errMsg, sizeof(errMsg), "%T", "yadp_main_ModNameBuffer", LANG_SERVER, MAXMODULENAME);
		YADP_Debug_LogMessage("module", errMsg, (LogServer | LogFile), LevelError);
		return;
	}
	strcopy(bufferModName, bufferModNameMaxLength, g_modNames[idx]);
}

stock void YADP_Module_GetDescription(int idx, char[] bufferModDesc, int bufferModDescMaxLength) {
	if((idx < 0 || idx > g_modIdx) || bufferModDescMaxLength < MAXMODULEDESC){
		char errMsg[80];
		if((idx < 0 || idx > g_modIdx))
			Format(errMsg, sizeof(errMsg), "%T", "yadp_main_ModDoesNotExist", LANG_SERVER, idx);
		else
			Format(errMsg, sizeof(errMsg), "%T", "yadp_main_ModDescBuffer", LANG_SERVER, MAXMODULEDESC);
		YADP_Debug_LogMessage("module", errMsg, (LogServer | LogFile), LevelError);
		return;
	}
	strcopy(bufferModDesc, bufferModDescMaxLength, g_modDescs[idx]);
}

stock int YADP_Module_GetWeight(int idx) {
	if((idx < 0 || idx > g_modIdx)){
		char errMsg[80];
		Format(errMsg, sizeof(errMsg), "%T", "yadp_main_ModDoesNotExist", LANG_SERVER, idx);
		YADP_Debug_LogMessage("module", errMsg, (LogServer | LogFile), LevelError);
		return -1;
	}
	return g_modWghts[idx];
}

stock YADP_Module_Team YADP_Module_GetTeam(int idx) {
	if((idx < 0 || idx > g_modIdx)){
		char errMsg[80];
		Format(errMsg, sizeof(errMsg), "%T", "yadp_main_ModDoesNotExist", LANG_SERVER, idx);
		YADP_Debug_LogMessage("module", errMsg, (LogServer | LogFile), LevelError);
		return 1;
	}
	return g_modTeam[idx];
}

stock bool YADP_Module_StartInvoking(int idx) {
	if(g_modIdxInvoking != -1 || (idx < 0 || idx > g_modIdx)) {
		char errMsg[80];
		if((idx < 0 || idx > g_modIdx))
			Format(errMsg, sizeof(errMsg), "%T", "yadp_main_ModDoesNotExist", LANG_SERVER, idx);
		else
			Format(errMsg, sizeof(errMsg), "%T", "yadp_main_ModInvokeInProgress", LANG_SERVER, idx, g_modIdxInvoking);
		YADP_Debug_LogMessage("module", errMsg, (LogServer | LogFile), LevelError);
		return false;
	}
	g_modIdxInvoking = idx;
	Call_StartFunction(INVALID_HANDLE, g_modCallbacks[idx]);
	return true;
}

stock bool YADP_Module_StopInvoking(int idx, any &result) {
	if(g_modIdxInvoking == -1 || (idx < 0 || idx > g_modIdx) || (idx != g_modIdxInvoking)) {
		char errMsg[80];
		if((idx < 0 || idx > g_modIdx))
			Format(errMsg, sizeof(errMsg), "%T", "yadp_main_ModDoesNotExist", LANG_SERVER, idx);
		else if(g_modIdxInvoking == -1)
			Format(errMsg, sizeof(errMsg), "%T", "yadp_main_ModNoInvokeInProgress", LANG_SERVER);
		else
			Format(errMsg, sizeof(errMsg), "%T", "yadp_main_ModInvokeStopWrongMod", LANG_SERVER, idx, g_modIdxInvoking);
		YADP_Debug_LogMessage("module", errMsg, (LogServer | LogFile), LevelError);
		return false;
	}
	Call_Finish(result);
	g_modIdxInvoking = -1;
	return true;
}

stock int YADP_Module_ChooseRandom(YADP_Module_Team team) {
	int sumWght = 0;
	for(int i = 0; i <= g_modIdx; i++) {
		if(g_modTeam[i] != team && g_modTeam[i] != ModuleTeam_Any) continue;
		sumWght += g_modWghts[i];
	}
	int rndIdx = GetRandomInt(0, sumWght);
	int selIdx = 0;
	for(int i = 0; i <= g_modIdx; i++) {
		if(g_modTeam[i] != team && g_modTeam[i] != ModuleTeam_Any) continue;
		if(rndIdx < g_modWghts[i]) {
			selIdx = i;
			break;
		}
		rndIdx -= g_modWghts[i];
	}
	return selIdx;
}