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

new Handle:g_hCmdArray;
public YAPD_Config_Initialize() {
	RegisterCommands();
	YAPD_Debug_LogMessage("config", "initialized", YAPD_Debug_LogMode:LogServer, YAPD_Debug_LogLevel:LevelInfo);
}

ProcessLine(String:line[]) {
	new String:msg[50];
	RegConsoleCmd(line, YAPD_Command_HandleRequest);
	Format(msg, sizeof(msg), "Registered command '%s'.", line);
	YAPD_Debug_LogMessage("config", msg, YAPD_Debug_LogMode:LogServer, YAPD_Debug_LogLevel:LevelInfo);
}

RegisterCommands() {
	decl String:srcPath[26];
	srcPath = "configs/YADP/";
	YAPD_Util_RequireDir(srcPath);
	srcPath = "configs/YADP/commands.txt";
	YAPD_Util_RequireFile(srcPath);
	
	new cmdCnt = YAPD_Util_CountLines(srcPath);
	if(cmdCnt < 1) return;
	g_hCmdArray = CreateArray(cmdCnt);
	YAPD_Util_ReadAllLines(srcPath, g_hCmdArray);
	decl String:buffer[20];
	for(new i=0; i<GetArraySize(g_hCmdArray); i++ ) {
		GetArrayString(g_hCmdArray, i, buffer, 20);
		ProcessLine(buffer);
    }
}
