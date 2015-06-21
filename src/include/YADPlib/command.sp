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

int g_DiceAttepmts[MAXPLAYERS + 1];
public void YAPD_Initialize_Command() {
	YAPD_Debug_LogMessage("command", "initialized.", LogServer, LevelInfo); 
	HookEvent("round_prestart", YAPD_Command_RoundPrestart, EventHookMode_PostNoCopy)

}

public void YAPD_Configure_Command() {
	
}

public Action YAPD_Command_RoundPrestart(Event event, const char[] name, bool dontBroadcast) {
	for(int i = 1; i <= MAXPLAYERS; i++) {
		if(g_DiceAttepmts[i] != 1) g_DiceAttepmts[i]++;
	}
}

public Action YAPD_Command_HandleRequest(int client, int args) {
	if(g_DiceAttepmts[client] < 0) {
		char msg[100];
		Format(msg, sizeof(msg), "%T", "yadp_main_NoAttemptsLeft", client);
		YAPD_Chat_ReplyToCommand(client, msg);
	}
	int mod = YAPD_Module_ChooseRandom();
	Action res;
	YAPD_Module_StartInvoking(mod);
	Call_PushCell(client);
	Call_PushCell(0);
	YAPD_Module_StopInvoking(mod, res);
	g_DiceAttepmts[client]--;
	return Plugin_Handled;
}