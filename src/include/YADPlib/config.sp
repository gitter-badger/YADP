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

Handle g_hCmdArray = null;
public void YAPD_Initialize_Config() {
	RegisterCommands();
	YAPD_Debug_LogMessage("config", "initialized.", LogServer, LevelInfo);
}

public void YAPD_Configure_Config() {

}

void ProcessLine(char[] line) {
	char msg[50];
	RegConsoleCmd(line, YAPD_Command_HandleRequest, "YADP roll the dice.");
	Format(msg, sizeof(msg), "Registered command '%s'.", line);
	YAPD_Debug_LogMessage("config", msg, LogServer, LevelInfo);
}

void RegisterCommands() {
	char srcPath[26];
	srcPath = "configs/YADP/";
	YAPD_Util_RequireDir(srcPath);
	srcPath = "configs/YADP/commands.txt";
	YAPD_Util_RequireFile(srcPath);
	
	int cmdCnt = YAPD_Util_CountLines(srcPath);
	if(cmdCnt < 1) return;
	g_hCmdArray = CreateArray(cmdCnt);
	YAPD_Util_ReadAllLines(srcPath, g_hCmdArray);
	char buffer[20];
	for(int i = 0; i < GetArraySize(g_hCmdArray); i++) {
		GetArrayString(g_hCmdArray, i, buffer, 20);
		ProcessLine(buffer);
    }
}
