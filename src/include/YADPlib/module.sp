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

new String:g_modNames[MAXMODULES][MAXMODULENAME];
new String:g_modDescs[MAXMODULES][MAXMODULEDESC];
new g_modWghts[MAXMODULES];
new g_modIdx = 0;
new bool:g_CanRegister = false;
public YAPD_Initialize_Module() {
	g_CanRegister = true;
	YAPD_Debug_LogMessage("module", "initialized.", YAPD_Debug_LogMode:LogServer, YAPD_Debug_LogLevel:LevelInfo);
}

public YAPD_Configure_Module() {
	g_CanRegister = false;
}

public YAPD_Module_Register(String:name[],String:desc[], weight) {
	new String:errMsg[128];
	new String:mName[MAXMODULENAME];
	new String:mDesc[MAXMODULEDESC];
	strcopy(mName, sizeof(mName), name);
	strcopy(mDesc, sizeof(mDesc), desc);
	if(g_modIdx >= MAXMODULES || !g_CanRegister) {
		Format(errMsg, sizeof(errMsg), "can not register module '%s'.", mName);
		YAPD_Debug_LogMessage("module", errMsg, (YAPD_Debug_LogMode:LogServer | YAPD_Debug_LogMode:LogFile), YAPD_Debug_LogLevel:LevelError);
		if(!g_CanRegister)
			Format(errMsg, sizeof(errMsg), "It is too late to register a module.");
		else
			Format(errMsg, sizeof(errMsg), "Maximum number of modules: %d", MAXMODULES);
		YAPD_Debug_LogMessage("module", errMsg, (YAPD_Debug_LogMode:LogServer | YAPD_Debug_LogMode:LogFile), YAPD_Debug_LogLevel:LevelError);
		return -1;
	}
	g_modNames[g_modIdx] = mName;
	g_modDescs[g_modIdx] = mDesc;
	g_modWghts[g_modIdx] = weight;
	Format(errMsg, sizeof(errMsg), "registered module '%s'.", mName);
	YAPD_Debug_LogMessage("module", errMsg, YAPD_Debug_LogMode:LogServer, YAPD_Debug_LogLevel:LevelInfo);
	return g_modIdx++;
}

public YAPD_Module_GetName(idx, String:bufferModName[], bufferModNameMaxLength) {
	if(idx >= g_modIdx || bufferModNameMaxLength < MAXMODULENAME){
		new String:errMsg[80];
		if(idx >= g_modIdx)
			Format(errMsg, sizeof(errMsg), "Module %d does not exist.", idx);
		else
			Format(errMsg, sizeof(errMsg), "Module names require up to %d characters.", MAXMODULENAME);
		YAPD_Debug_LogMessage("module", errMsg, (YAPD_Debug_LogMode:LogServer | YAPD_Debug_LogMode:LogFile), YAPD_Debug_LogLevel:LevelError);
		return;
	}
	strcopy(bufferModName, bufferModNameMaxLength, g_modNames[g_modIdx]);
}

public YAPD_Module_GetDescription(idx, String:bufferModDesc[], bufferModDescMaxLength) {
	if(idx >= g_modIdx || bufferModDescMaxLength < MAXMODULEDESC){
		new String:errMsg[80];
		if(idx >= g_modIdx)
			Format(errMsg, sizeof(errMsg), "Module %d does not exist.", idx);
		else
			Format(errMsg, sizeof(errMsg), "Module descriptions require up to %d characters.", MAXMODULEDESC);
		YAPD_Debug_LogMessage("module", errMsg, (YAPD_Debug_LogMode:LogServer | YAPD_Debug_LogMode:LogFile), YAPD_Debug_LogLevel:LevelError);
		return;
	}
	strcopy(bufferModDesc, bufferModDescMaxLength, g_modDescs[g_modIdx]);
}

public YAPD_Module_GetWeight(idx) {
	if(idx >= g_modIdx){
		new String:errMsg[80];
		Format(errMsg, sizeof(errMsg), "Module %d does not exist.", idx);
		YAPD_Debug_LogMessage("module", errMsg, (YAPD_Debug_LogMode:LogServer | YAPD_Debug_LogMode:LogFile), YAPD_Debug_LogLevel:LevelError);
		return -1;
	}
	return g_modWghts[g_modIdx];
}