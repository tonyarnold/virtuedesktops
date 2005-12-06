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

#include "DECEventDesktop.h"
#include "DECPrivate.h" 

#define kDecEventDesktopValueKey		'desk'

DecEventDesktop* dec_event_desktop_new(DecEvent* event)
{
	if (event == NULL)
		return NULL; 

	DecEventDesktop* desktopEvent = (DecEventDesktop*)malloc(sizeof(DecEventDesktop)); 
	
	desktopEvent->event = event;
	desktopEvent->event->type = kDecEventDesktop; 
	
	return desktopEvent; 
}

void dec_event_desktop_free(DecEventDesktop* event)
{
	if (event == NULL)
		return; 
	
	free(event); 
}

int  dec_event_desktop_value_get(DecEventDesktop* event)
{
	if (event == NULL)
		return -1; 
	
	int desktop; 
	
	AEGetParamPtr(event->event->appleEvent, kDecEventDesktopValueKey, typeSInt32, NULL, &desktop, sizeof(int), NULL); 
	return desktop; 
}

void dec_event_desktop_value_set(DecEventDesktop* event, int value)
{
	if (event == NULL)
		return; 
	if (event->event == NULL)
		return; 
	
	AEPutParamPtr(event->event->appleEvent, kDecEventDesktopValueKey, typeSInt32, &value, sizeof(int)); 	
}
