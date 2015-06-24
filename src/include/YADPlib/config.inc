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
#if defined _YADPLIB_CONFIG_INCLUDED
	#endinput
#endif
#define _YADPLIB_CONFIG_INCLUDED

static Handle g_hCmdArray = null;

stock void YADP_Initialize_Config() {
	char msg[40];
	RegisterCommands();
	Format(msg, sizeof(msg), "%T", "yadp_main_Init", LANG_SERVER);
	YADP_Debug_LogMessage("config", msg, LogServer, LevelInfo);
}

stock void YADP_Configure_Config() {
	char cmd[50];
	cmd = "sm_yadp";
	RegConsoleCmd(cmd, YADP_Command_HandleRequest, "YADP roll the dice");
	cmd = "sm_yadp_stop";
	RegConsoleCmd(cmd, YADP_Command_HandleDisable, "YADP stop");
	cmd = "sm_yadp_auto";
	RegConsoleCmd(cmd, YADP_Command_HandleAuto, "YADP auto-roll");
	cmd = "sm_yadp_menu";
	RegConsoleCmd(cmd, YADP_Command_HandleMenu, "YADP menu");
}

stock void YADP_Config_GetRandomCmd(char[] buffer, int maxlength) {
	GetArrayString(g_hCmdArray, GetRandomInt(0, GetArraySize(g_hCmdArray) - 1), buffer, maxlength);
	ReplaceString(buffer, maxlength, "sm_", "!", false);
}

static void ProcessLine(const char[] line) {
	char txt[50];
	RegConsoleCmd(line, YADP_Command_HandleRequest, "YADP roll the dice");
	Format(txt, sizeof(txt), "%s_stop", line);
	RegConsoleCmd(txt, YADP_Command_HandleDisable, "YADP disable");
	Format(txt, sizeof(txt), "%s_auto", line);
	RegConsoleCmd(txt, YADP_Command_HandleAuto, "YADP auto-roll");
	Format(txt, sizeof(txt), "%s_menu", line);
	RegConsoleCmd(txt, YADP_Command_HandleMenu, "YADP menu");
	Format(txt, sizeof(txt), "%T", "yadp_main_RegCmd", LANG_SERVER, line);
	YADP_Debug_LogMessage("config", txt, LogServer, LevelInfo);
}

static void RegisterCommands() {
	char srcPath[26];
	srcPath = "configs/YADP/";
	YADP_Util_RequireDir(srcPath);
	srcPath = "configs/YADP/commands.txt";
	YADP_Util_RequireFile(srcPath);
	
	int cmdCnt = YADP_Util_CountLines(srcPath);
	if(cmdCnt < 1) return;
	g_hCmdArray = CreateArray(cmdCnt);
	YADP_Util_ReadAllLines(srcPath, g_hCmdArray);
	char buffer[20];
	for(int i = 0; i < GetArraySize(g_hCmdArray); i++) {
		GetArrayString(g_hCmdArray, i, buffer, 20);
		ProcessLine(buffer);
    }
}
