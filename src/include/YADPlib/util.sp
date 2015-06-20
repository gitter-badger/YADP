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

public YAPD_Initialize_Util() {
	YAPD_Debug_LogMessage("util", "initialized.", YAPD_Debug_LogMode:LogServer, YAPD_Debug_LogLevel:LevelInfo);
}

public YAPD_Configure_Util() {

}

public YAPD_Util_PrintToConsoleAll(String:message[]) {
	if(strlen(message) > 1024) return; // Not Supported by CS:GO
	for (new i = 1; i <= MaxClients; i++) { 
		if(!IsClientInGame(i)) continue;	
		PrintToConsole(i, message); 
	}
}


public bool:YAPD_Util_AppendToFile(String:path[], String:content[]) {
	new Handle:hFile = OpenFile(path, "a+");
	if(hFile != INVALID_HANDLE){
		WriteFileLine(hFile, content);
	} else {
		CloseHandle(hFile);
		return false;
	}
	CloseHandle(hFile);
	return true;
}

public YAPD_Util_RequireDir(String:filePath[]) {
	decl String:dirPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, dirPath, PLATFORM_MAX_PATH, filePath);
	if(!DirExists(dirPath)) {
		CreateDirectory(dirPath, 511);
	}
}

public YAPD_Util_RequireFile(String:filePath[]) {
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, filePath);
	if(!FileExists(path)) {
		new Handle:hFile = OpenFile(path, "w+");
		CloseHandle(hFile);
	}
}

public YAPD_Util_ReadAllLines(String:path[], Handle:adtHandle) {
	decl String:filePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filePath, PLATFORM_MAX_PATH, path);
	new Handle:hFile = OpenFile(filePath, "r");
	if(hFile != INVALID_HANDLE){
		decl String:buffer[128];
		while(ReadFileLine(hFile, buffer, sizeof(buffer))) {
			YAPD_Util_ReplaceShellComment(buffer);
			if(strlen(buffer) > 0) {
				PushArrayString(adtHandle, buffer);
			}
		}
	}
	CloseHandle(hFile);
}

public YAPD_Util_CountLines(String:path[]) {
	decl String:filePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filePath, PLATFORM_MAX_PATH, path);
	new Handle:hFile = OpenFile(filePath, "r");
	new cnt = 0;
	if(hFile != INVALID_HANDLE){
		decl String:buffer[50];
		while(ReadFileLine(hFile, buffer, sizeof(buffer))) {
			YAPD_Util_ReplaceShellComment(buffer);
			if(strlen(buffer) > 0) cnt++;
		}
	}
	CloseHandle(hFile);
	return cnt;
}

public YAPD_Util_ReplaceShellComment(String:str[]) {
	new pos = FindCharInString(str, '#');
	if(pos < 0) {
		TrimString(str);
		return;
	}
	for(new i = pos; i < strlen(str); i++) {
		str[i] = ' ';
	}
	TrimString(str);
}