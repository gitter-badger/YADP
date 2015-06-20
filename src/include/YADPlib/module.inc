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
forward YAPD_Initialize_Module();
forward YAPD_Configure_Module();
forward YAPD_Module_Register(String:name[],String:desc[], weight);
forward YAPD_Module_GetName(idx, String:buffer[], maxlength);
forward YAPD_Module_GetDescription(idx, String:buffer[], maxlength);
forward YAPD_Module_GetWeight(idx);