/******************************************************************************
* 
* DEComm.Peony.Virtue 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller 
* playback@users.sourceforge.net
*
* Redistribution and use in source and binary forms, with or without modification, 
* are permitted provided that the following conditions are met:
* 
* - Redistributions of source code must retain the above copyright notice, this list 
*   of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above copyright notice, this 
*   list of conditions and the following disclaimer in the documentation and/or other 
*   materials provided with the distribution.
* - The name of the author may not be used to endorse or promote products derived 
*   from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, 
* INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR 
* A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY 
* DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
* BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER 
* IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY 
* WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
* 
*****************************************************************************/ 

#ifndef __DEC_H__
#define __DEC_H__ 

#include <Carbon/Carbon.h>

#define kDecEventTypeKey		'TYPE'

struct _Dec_Event
{
	int			type; 
	int			targetCount; 
	int*		targets; 
	
	AppleEvent* appleEvent; 
	int			appleEventOwned; 
}; 

struct _Dec_Event_Alpha 
{
	struct _Dec_Event* event; 
}; 

struct _Dec_Event_Level
{
	struct _Dec_Event* event; 
}; 

struct _Dec_Event_Property 
{
	struct _Dec_Event* event; 
	char* propertyKey; 
	char* propertyValue; 
}; 

struct _Dec_Event_Info
{
	struct _Dec_Event* event; 
}; 

struct _Dec_Event_Desktop
{
	struct _Dec_Event* event; 
}; 

struct _Dec_Event_Order
{
	struct _Dec_Event* event; 
}; 

struct _Dec_Event_Tags
{
	struct _Dec_Event* event; 
}; 

#endif 