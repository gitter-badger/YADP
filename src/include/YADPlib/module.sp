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

char g_modNames[MAXMODULES][MAXMODULENAME];
char g_modDescs[MAXMODULES][MAXMODULEDESC];
char g_modWghts[MAXMODULES];
ModuleCallback g_modCallbacks[MAXMODULES];
int g_modIdx = 0;
int g_modIdxInvoking = -1;
bool g_CanRegister = false;

public void YAPD_Initialize_Module() {
	g_CanRegister = true;
	YAPD_Debug_LogMessage("module", "initialized.", LogServer, LevelInfo);
}

public void YAPD_Configure_Module() {
	g_CanRegister = false;
}

public int YAPD_Module_Register(char[] name, char[] desc, int weight, ModuleCallback callback) {
	char errMsg[128];
	char mName[MAXMODULENAME];
	char mDesc[MAXMODULEDESC];
	strcopy(mName, sizeof(mName), name);
	strcopy(mDesc, sizeof(mDesc), desc);
	if(g_modIdx >= MAXMODULES || !g_CanRegister) {
		Format(errMsg, sizeof(errMsg), "can not register module '%s'.", mName);
		YAPD_Debug_LogMessage("module", errMsg, (LogServer | LogFile), LevelError);
		if(!g_CanRegister)
			Format(errMsg, sizeof(errMsg), "It is too late to register a module.");
		else
			Format(errMsg, sizeof(errMsg), "Maximum number of modules: %d", MAXMODULES);
		YAPD_Debug_LogMessage("module", errMsg, (LogServer | LogFile), LevelError);
		return -1;
	}
	g_modNames[g_modIdx] = mName;
	g_modDescs[g_modIdx] = mDesc;
	g_modWghts[g_modIdx] = weight;
	g_modCallbacks[g_modIdx] = callback;
	Format(errMsg, sizeof(errMsg), "registered module '%s'.", mName);
	YAPD_Debug_LogMessage("module", errMsg, LogServer, LevelInfo);
	return g_modIdx++;
}

public void YAPD_Module_GetName(int idx, char[] bufferModName, int bufferModNameMaxLength) {
	if((g_modIdxInvoking < 0 || g_modIdxInvoking >= g_modIdx) || bufferModNameMaxLength < MAXMODULENAME){
		char errMsg[80];
		if((g_modIdxInvoking < 0 || g_modIdxInvoking >= g_modIdx))
			Format(errMsg, sizeof(errMsg), "Module <%d> does not exist.", idx);
		else
			Format(errMsg, sizeof(errMsg), "Module names require up to %d characters.", MAXMODULENAME);
		YAPD_Debug_LogMessage("module", errMsg, (LogServer | LogFile), LevelError);
		return;
	}
	strcopy(bufferModName, bufferModNameMaxLength, g_modNames[g_modIdx]);
}

public void YAPD_Module_GetDescription(int idx, char[] bufferModDesc, int bufferModDescMaxLength) {
	if((g_modIdxInvoking < 0 || g_modIdxInvoking >= g_modIdx) || bufferModDescMaxLength < MAXMODULEDESC){
		char errMsg[80];
		if((g_modIdxInvoking < 0 || g_modIdxInvoking >= g_modIdx))
			Format(errMsg, sizeof(errMsg), "Module <%d> does not exist.", idx);
		else
			Format(errMsg, sizeof(errMsg), "Module descriptions require up to %d characters.", MAXMODULEDESC);
		YAPD_Debug_LogMessage("module", errMsg, (LogServer | LogFile), LevelError);
		return;
	}
	strcopy(bufferModDesc, bufferModDescMaxLength, g_modDescs[g_modIdx]);
}

public int YAPD_Module_GetWeight(int idx) {
	if((g_modIdxInvoking < 0 || g_modIdxInvoking >= g_modIdx)){
		char errMsg[80];
		Format(errMsg, sizeof(errMsg), "Module <%d> does not exist.", idx);
		YAPD_Debug_LogMessage("module", errMsg, (LogServer | LogFile), LevelError);
		return -1;
	}
	return g_modWghts[g_modIdx];
}

public bool YAPD_Module_StartInvoking(int idx) {
	if(g_modIdxInvoking != -1 || g_modIdxInvoking >= g_modIdx) {
		char errMsg[80];
		if((g_modIdxInvoking < 0 || g_modIdxInvoking >= g_modIdx))
			Format(errMsg, sizeof(errMsg), "Module <%d> does not exist.", idx);
		else
			Format(errMsg, sizeof(errMsg), "can not invoke module <%d>. Already invoking <%d>.", idx, g_modIdxInvoking);
		YAPD_Debug_LogMessage("module", errMsg, (LogServer | LogFile), LevelError);
		return false;
	}
	g_modIdxInvoking = idx;
	Call_StartFunction(INVALID_HANDLE, g_modCallbacks[idx]);
	return true;
}

public bool YAPD_Module_StopInvoking(int idx, any &result) {
	if(g_modIdxInvoking == -1 || (g_modIdxInvoking < 0 || g_modIdxInvoking >= g_modIdx)) {
		char errMsg[80];
		if((g_modIdxInvoking < 0 || g_modIdxInvoking >= g_modIdx))
			Format(errMsg, sizeof(errMsg), "Module <%d> does not exist.", idx);
		else if(g_modIdxInvoking == -1)
			Format(errMsg, sizeof(errMsg), "no invocation in progress.");
		else
			Format(errMsg, sizeof(errMsg), "can not stop invoking module <%d>. Already invoking <%d>.", idx, g_modIdxInvoking);
		YAPD_Debug_LogMessage("module", errMsg, (LogServer | LogFile), LevelError);
		return false;
	}
	Call_Finish(result);
	g_modIdxInvoking = -1;
	return true;
}