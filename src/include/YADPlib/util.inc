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
#if defined _YADPLIB_UTIL_INCLUDED
	#endinput
#endif
#define _YADPLIB_UTIL_INCLUDED
#include <YADPlib/debug>

stock void YADP_Initialize_Util()
{
	char msg[40];
	Format(msg, sizeof(msg), "%T", "yadp_main_Init", LANG_SERVER);
	YADP_Debug_LogMessage("util", msg, LogServer, LevelInfo);
}

stock void YADP_Configure_Util()
{

}

stock void YADP_Util_PrintToConsoleAll(const char[] message)
{
	if(strlen(message) > 1024)
	{
		return; // Not Supported by CS:GO & L4D2
	}
	for (int i = 1; i <= MaxClients; i++)
	{ 
		if(!IsClientInGame(i))
		{
			continue;
		}			
		PrintToConsole(i, message); 
	}
}

stock bool YADP_Util_AppendToFile(const char[] path, const char[] content)
{
	Handle hFile = OpenFile(path, "a+");
	if(hFile != null)
	{
		WriteFileLine(hFile, content);
	} else {
		CloseHandle(hFile);
		return false;
	}
	CloseHandle(hFile);
	return true;
}

stock void YADP_Util_RequireDir(const char[] filePath)
{
	char dirPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, dirPath, PLATFORM_MAX_PATH, filePath);
	if(!DirExists(dirPath))
	{
		CreateDirectory(dirPath, 511);
	}
}

stock void YADP_Util_RequireFile(const char[] filePath)
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, filePath);
	if(!FileExists(path))
	{
		Handle hFile = OpenFile(path, "w+");
		CloseHandle(hFile);
	}
}

stock void YADP_Util_ReadAllLines(const char[] path, Handle adtHandle)
{
	char filePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filePath, PLATFORM_MAX_PATH, path);
	Handle hFile = OpenFile(filePath, "r");
	if(hFile != null)
	{
		char buffer[128];
		while(ReadFileLine(hFile, buffer, sizeof(buffer)))
		{
			YADP_Util_ReplaceShellComment(buffer);
			if(strlen(buffer) > 0)
			{
				PushArrayString(adtHandle, buffer);
			}
		}
	}
	CloseHandle(hFile);
}

stock int YADP_Util_CountLines(const char[] path)
{
	char filePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filePath, PLATFORM_MAX_PATH, path);
	Handle hFile = OpenFile(filePath, "r");
	int cnt = 0;
	if(hFile != null)
	{
		char buffer[50];
		while(ReadFileLine(hFile, buffer, sizeof(buffer)))
		{
			YADP_Util_ReplaceShellComment(buffer);
			if(strlen(buffer) > 0)
			{
				cnt++;
			}
		}
	}
	CloseHandle(hFile);
	return cnt;
}

stock void YADP_Util_ReplaceShellComment(char[] str)
{
	int pos = FindCharInString(str, '#');
	if(pos < 0)
	{
		TrimString(str);
		return;
	}
	for(int i = pos; i < strlen(str); i++)
	{
		str[i] = ' ';
	}
	TrimString(str);
}

stock bool YADP_Util_YADP_IsValidClient(int client, bool botsAllowed = false)
{
	if(client < 1 || client > MaxClients)
	{
		return false;
	}
	if(!IsClientConnected(client) || !IsClientAuthorized(client) || !IsClientInGame(client))
	{
		return false;
	}
	if(IsClientSourceTV(client) || IsClientReplay(client))
	{
		return false;
	}
	if(IsClientObserver(client))
	{
		return false;
	}
	if(IsClientInKickQueue(client))
	{
		return false;
	}
	if(!botsAllowed && !IsFakeClient(client))
	{
		return false;
	}
	return true;
}

stock int YADP_Util_YADP_IsValidClientNative(Handle plugin, int numParams)
{
	if(numParams != 2)
	{
		return view_as<int>(false);
	}
	int client = GetNativeCell(1);
	bool ignr = GetNativeCell(2);
	return view_as<int>(YADP_Util_YADP_IsValidClient(client, ignr));
}