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
#if defined _YADPLIB_MODULE_INCLUDED
	#endinput
#endif
#define _YADPLIB_MODULE_INCLUDED

#define MAXMODULES		20
#define MAXMODULENAME	10
#define MAXMODULEDESC	100

typedef ModuleCallback = function Action(int args);

forward void YAPD_Initialize_Module();
forward void YAPD_Configure_Module();
forward int YAPD_Module_Register(char[] name, char[] desc, int weight, ModuleCallback callback);
forward void YAPD_Module_GetName(int idx, char[] buffer, int maxlength);
forward void YAPD_Module_GetDescription(int idx, char[] buffer, int maxlength);
forward int YAPD_Module_GetWeight(int idx);
forward bool YAPD_Module_StartInvoking(int idx);
forward bool YAPD_Module_StopInvoking(int idx, any &result);