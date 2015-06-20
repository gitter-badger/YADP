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

public void YAPD_Initialize_Util() {
	YAPD_Debug_LogMessage("util", "initialized.", LogServer, LevelInfo);
}

public void YAPD_Configure_Util() {

}

public void YAPD_Util_PrintToConsoleAll(char[] message) {
	if(strlen(message) > 1024) return; // Not Supported by CS:GO
	for (int i = 1; i <= MaxClients; i++) { 
		if(!IsClientInGame(i)) continue;	
		PrintToConsole(i, message); 
	}
}


public bool YAPD_Util_AppendToFile(char[] path, char[] content) {
	Handle hFile = OpenFile(path, "a+");
	if(hFile != null){
		WriteFileLine(hFile, content);
	} else {
		CloseHandle(hFile);
		return false;
	}
	CloseHandle(hFile);
	return true;
}

public void YAPD_Util_RequireDir(char[] filePath) {
	char dirPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, dirPath, PLATFORM_MAX_PATH, filePath);
	if(!DirExists(dirPath)) {
		CreateDirectory(dirPath, 511);
	}
}

public void YAPD_Util_RequireFile(char[] filePath) {
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, filePath);
	if(!FileExists(path)) {
		Handle hFile = OpenFile(path, "w+");
		CloseHandle(hFile);
	}
}

public void YAPD_Util_ReadAllLines(char[] path, Handle adtHandle) {
	char filePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filePath, PLATFORM_MAX_PATH, path);
	Handle hFile = OpenFile(filePath, "r");
	if(hFile != null){
		char buffer[128];
		while(ReadFileLine(hFile, buffer, sizeof(buffer))) {
			YAPD_Util_ReplaceShellComment(buffer);
			if(strlen(buffer) > 0) {
				PushArrayString(adtHandle, buffer);
			}
		}
	}
	CloseHandle(hFile);
}

public int YAPD_Util_CountLines(char[] path) {
	char filePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filePath, PLATFORM_MAX_PATH, path);
	Handle hFile = OpenFile(filePath, "r");
	int cnt = 0;
	if(hFile != null){
		char buffer[50];
		while(ReadFileLine(hFile, buffer, sizeof(buffer))) {
			YAPD_Util_ReplaceShellComment(buffer);
			if(strlen(buffer) > 0) cnt++;
		}
	}
	CloseHandle(hFile);
	return cnt;
}

public void YAPD_Util_ReplaceShellComment(char[] str) {
	int pos = FindCharInString(str, '#');
	if(pos < 0) {
		TrimString(str);
		return;
	}
	for(int i = pos; i < strlen(str); i++) {
		str[i] = ' ';
	}
	TrimString(str);
}