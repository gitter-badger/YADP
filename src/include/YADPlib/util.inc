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

forward YAPD_Initialize_Util();
forward YAPD_Configure_Util();
forward YAPD_Util_PrintToConsoleAll(String:message[]);
forward YAPD_Util_RequireDir(String:path[]);
forward YAPD_Util_RequireFile(String:path[]);
forward bool:YAPD_Util_AppendToFile(String:path[], String:content[]);
forward YAPD_Util_ReadAllLines(String:path[], Handle:adtHandle);
forward YAPD_Util_CountLines(String:path[]);
forward YAPD_Util_ReplaceShellComment(String:str[]);
