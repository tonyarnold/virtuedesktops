/******************************************************************************
* 
* DEComm.Peony.Virtue 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2005-2007, Tony Arnold tony@tonyarnold.com
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

#ifndef __DEC_EVENT_H__
#define __DEC_EVENT_H__

#include <Carbon/Carbon.h>

#define kDecEventClass		'DExt' 
#define kDecEventId				'DExd'


/* DecEvent types */ 
typedef enum
{
	kDecEventNone			= 0, 
	
	kDecEventAlpha		= 1, 
	kDecEventDesktop	= 2,
	kDecEventOrder		= 3,
	kDecEventLevel		= 4,
	kDecEventTags			= 5,
	kDecEventProperty	= 6,
	kDecEventInfo			= 7, 
	
	kDecEventLast			= 8,
} DecEventType; 

typedef struct _Dec_Event DecEvent; 


DecEvent* dec_event_new(); 
void dec_event_free(DecEvent* event); 

void dec_event_apple_event_new(DecEvent* event); 
void dec_event_apple_event_attach(DecEvent* event, const AppleEvent* appleEvent); 

int* dec_event_targets_get(DecEvent* event);
int  dec_event_targets_size_get(DecEvent* event); 
void dec_event_targets_set(DecEvent* event, int* targets, int targetsSize); 
int  dec_event_type_get(DecEvent* event); 

OSErr dec_event_send_sync(DecEvent* event, AppleEvent* replyEvent); 
OSErr dec_event_send_asyn(DecEvent* event); 

#endif 


