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
 * GitBase: $git-branch$ / $git-hash-long$
 * Authors: Hendrik Reker
 */
#if defined _YADPLIB_MODULE_INCLUDED
	#endinput
#endif
#define _YADPLIB_MODULE_INCLUDED

#define MAXMODULES		20
#define MAXMODULENAME	10
#define MAXMODULEDESC	100

typedef GeneralCallback = function void(int client);

enum YADP_Module_Team {
	ModuleTeam_Any	= 0x1,
	ModuleTeam_T 	= 0x2,
	ModuleTeam_CT	= 0x3,
}

static char g_modNames[MAXMODULES][MAXMODULENAME];
static char g_modDescs[MAXMODULES][MAXMODULEDESC];
static int g_modWghts[MAXMODULES];
static bool g_modRegistered[MAXMODULES];
static Handle g_modDicedCallbacks[MAXMODULES];
static Handle g_modResetCallbacks[MAXMODULES];
static YADP_Module_Team g_modTeam[MAXMODULES];
static int g_modIdx = -1;
static bool g_CanRegister = false;
static Handle g_hOnModuleInit;
static Handle g_hOnModuleConf;

stock void YADP_Initialize_Module()
{
	g_hOnModuleInit = CreateForward(ET_Ignore);
	g_hOnModuleConf = CreateForward(ET_Ignore);
	for(int i= 0; i < MAXMODULES; i++)
	{
		g_modDicedCallbacks[i] = CreateForward(ET_Ignore, Param_Cell);
		g_modResetCallbacks[i] = CreateForward(ET_Ignore, Param_Cell);
	}
	char msg[40];
	Format(msg, sizeof(msg), "%T", "yadp_main_Init", LANG_SERVER);
	YADP_Debug_LogMessage("module", msg, LogServer, LevelInfo);
}

stock void YADP_Configure_Module()
{

}

stock void YADP_Module_RegisterEnable()
{
	g_CanRegister = true;
}

stock void YADP_Module_RegisterDisable()
{
	g_CanRegister = false;
}

stock int YADP_Module_Register(const char[] name, const char[] desc, int weight, YADP_Module_Team team)
{
	char errMsg[128];
	char mName[MAXMODULENAME];
	char mDesc[MAXMODULEDESC];
	strcopy(mName, sizeof(mName), name);
	strcopy(mDesc, sizeof(mDesc), desc);
	if(g_modIdx >= MAXMODULES || !g_CanRegister)
	{
		Format(errMsg, sizeof(errMsg), "%T", "yadp_main_RegModFail", LANG_SERVER, mName);
		YADP_Debug_LogMessage("module", errMsg, (LogServer | LogFile), LevelError);
		if(!g_CanRegister)
		{
			Format(errMsg, sizeof(errMsg), "%T", "yadp_main_RegModLate", LANG_SERVER);
		} else {
			Format(errMsg, sizeof(errMsg), "%T", "yadp_main_RegModMax", LANG_SERVER, MAXMODULES);
		}
		YADP_Debug_LogMessage("module", errMsg, (LogServer | LogFile), LevelError);
		return -1;
	}
	g_modIdx++;
	g_modNames[g_modIdx] = mName;
	g_modDescs[g_modIdx] = mDesc;
	g_modWghts[g_modIdx] = weight;
	g_modTeam[g_modIdx] = team;
	g_modRegistered[g_modIdx] = false;
	Format(errMsg, sizeof(errMsg), "%T", "yadp_main_RegMod", LANG_SERVER, mName);
	YADP_Debug_LogMessage("module", errMsg, LogServer, LevelInfo);
	return g_modIdx;
}

stock void YADP_Module_GetName(int idx, char[] bufferModName, int bufferModNameMaxLength)
{
	if(!YADP_Module_IsValid(idx) || bufferModNameMaxLength < MAXMODULENAME)
	{
		if(bufferModNameMaxLength < MAXMODULENAME)
		{
			char errMsg[80];
			Format(errMsg, sizeof(errMsg), "%T", "yadp_main_ModNameBuffer", LANG_SERVER, MAXMODULENAME);
			YADP_Debug_LogMessage("module", errMsg, (LogServer | LogFile), LevelError);
		}
		return;
	}
	strcopy(bufferModName, bufferModNameMaxLength, g_modNames[idx]);
}

stock void YADP_Module_GetDescription(int idx, char[] bufferModDesc, int bufferModDescMaxLength)
{
	if(!YADP_Module_IsValid(idx) || bufferModDescMaxLength < MAXMODULEDESC)
	{
		if(bufferModDescMaxLength < MAXMODULEDESC)
		{
			char errMsg[80];
			Format(errMsg, sizeof(errMsg), "%T", "yadp_main_ModDescBuffer", LANG_SERVER, MAXMODULEDESC);
			YADP_Debug_LogMessage("module", errMsg, (LogServer | LogFile), LevelError);
		}
		return;
	}
	strcopy(bufferModDesc, bufferModDescMaxLength, g_modDescs[idx]);
}

stock int YADP_Module_GetWeight(int idx)
{
	if(!YADP_Module_IsValid(idx))
	{
		return -1;
	}
	return g_modWghts[idx];
}

stock YADP_Module_Team YADP_Module_GetTeam(int idx)
{
	if(!YADP_Module_IsValid(idx))
	{
		return 1;
	}
	return g_modTeam[idx];
}

stock Handle YADP_Module_GetHandle(int idx, bool diced)
{
	if(!YADP_Module_IsValid(idx))
	{
		return null;
	}
	return diced ? g_modDicedCallbacks[idx] : g_modResetCallbacks[idx];
}

stock int YADP_Module_RegOnInit(Handle plugin, int numParams)
{
	if(numParams != 1 || !YADP_Initialized())
	{
		return 0;
	}
	char pName[50];
	char msg[128];
	GetPluginFilename(plugin, pName, sizeof(pName));
	Format(msg, sizeof(msg), "%T", "yadp_main_ModInit", LANG_SERVER, pName);
	YADP_Debug_LogMessage("global", msg, LogFile, LevelInfo);
	AddToForward(g_hOnModuleInit, plugin, GetNativeFunction(1));
	return 0;
}

stock int YADP_Module_RegOnConf(Handle plugin, int numParams)
{
	if(numParams != 1 || !YADP_Initialized())
	{
		return 0;
	}
	char pName[50];
	char msg[128];
	GetPluginFilename(plugin, pName, sizeof(pName));
	Format(msg, sizeof(msg), "%T", "yadp_main_ModConf", LANG_SERVER, pName);
	YADP_Debug_LogMessage("global", msg, LogFile, LevelInfo);
	AddToForward(g_hOnModuleConf, plugin, GetNativeFunction(1)); 
	return 0;
}

stock int YADP_Module_RegOnDiced(Handle plugin, int numParams)
{
	if(numParams != 3 || !YADP_Initialized())
	{
		return 0;
	}
	int modIdx = GetNativeCell(1);
	if(!YADP_Module_IsValid(modIdx))
	{
		return -1;
	}
	char msg[128];
	if(g_modRegistered[modIdx])
	{
		Format(msg, sizeof(msg), "%T", "yadp_main_AlreadyRegOnDiced", LANG_SERVER, modIdx);
		YADP_Debug_LogMessage("global", msg, (LogFile | LogServer), LevelError);
		return -1;
	}
	Handle hDiced = YADP_Module_GetHandle(modIdx, true);
	Handle hReset = YADP_Module_GetHandle(modIdx, false);
	if(hDiced == null || hReset == null)
	{
		Format(msg, sizeof(msg), "%T", "yadp_main_RegOnDicedUnexpected", LANG_SERVER, modIdx);
		YADP_Debug_LogMessage("global", msg, (LogFile | LogServer), LevelError);
		return -1;
	}
	AddToForward(hDiced, plugin, GetNativeFunction(2)); 
	AddToForward(hReset, plugin, GetNativeFunction(3)); 
	g_modRegistered[modIdx] = true;
	char pName[50];
	GetPluginFilename(plugin, pName, sizeof(pName));
	Format(msg, sizeof(msg), "%T", "yadp_main_RegOnDiced", LANG_SERVER, modIdx, pName);
	YADP_Debug_LogMessage("global", msg, LogFile, LevelInfo);
	return 0;
}

stock void YADP_Module_SendOnInit()
{
	if(!YADP_Ready())
	{
		return;
	}
	Call_StartForward(g_hOnModuleInit);
	Call_Finish();
}

stock void YADP_Module_SendOnConf()
{
	if(!YADP_Ready())
	{
		return;
	}
	Call_StartForward(g_hOnModuleConf);
	Call_Finish();
}

stock void YADP_Module_SendOnDiced(int idx, int client)
{
	if(!YADP_Ready() || !YADP_Module_IsValid(idx))
	{
		return;
	}
	Call_StartForward(g_modDicedCallbacks[idx]);
	Call_PushCell(client);
	Call_Finish();
}

stock void YADP_Module_SendOnReset(int idx, int client)
{
	if(!YADP_Ready() || !YADP_Module_IsValid(idx))
	{
		return;
	}
	Call_StartForward(g_modResetCallbacks[idx]);
	Call_PushCell(client);
	Call_Finish();
}

stock int YADP_Module_ChooseRandom(YADP_Module_Team team)
{
	int sumWght = 0;
	for(int i = 0; i <= g_modIdx; i++)
	{
		if(g_modTeam[i] != team && g_modTeam[i] != ModuleTeam_Any)
		{
			continue;
		}
		sumWght += g_modWghts[i];
	}
	int rndIdx = GetRandomInt(0, sumWght);
	int selIdx = 0;
	for(int i = 0; i <= g_modIdx; i++)
	{
		if(g_modTeam[i] != team && g_modTeam[i] != ModuleTeam_Any)
		{
			continue;
		}
		if(rndIdx < g_modWghts[i])
		{
			selIdx = i;
			break;
		}
		rndIdx -= g_modWghts[i];
	}
	return selIdx;
}

stock bool YADP_Module_IsValid(int idx)
{
	if(idx < 0 || idx > g_modIdx)
	{
		char errMsg[80];
		Format(errMsg, sizeof(errMsg), "%T", "yadp_main_ModDoesNotExist", LANG_SERVER, idx);
		YADP_Debug_LogMessage("module", errMsg, (LogServer | LogFile), LevelError);
		return false;
	}
	return true;
}