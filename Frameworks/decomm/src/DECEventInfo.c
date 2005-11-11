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

#include "DECEventInfo.h"
#include "DECPrivate.h" 

#define kDecEventInfoMinor	'vmnr'
#define kDecEventInfoMajor	'vmaj'

DecEventInfo* dec_event_info_new(DecEvent* event)
{
	if (event == NULL)
		return NULL; 
	
	DecEventInfo* infoEvent = (DecEventInfo*)malloc(sizeof(DecEventInfo)); 

	infoEvent->event = event; 
	infoEvent->event->type = kDecEventInfo; 
	
	return infoEvent; 
}

void dec_event_info_free(DecEventInfo* event)
{
	if (event == NULL)
		return; 
	
	free(event); 
}

int  dec_event_info_version_major_get(DecEventInfo* event)
{
	if (event == NULL)
		return -1; 
	if (event->event == NULL)
		return -1; 
	
	int majorVersion; 

	AEGetParamPtr(event->event->appleEvent, kDecEventInfoMajor, typeSInt32, NULL, &majorVersion, sizeof(int), NULL);
	return majorVersion; 
}

int  dec_event_info_version_minor_get(DecEventInfo* event)
{
	if (event == NULL)
		return -1; 
	if (event->event == NULL)
		return -1; 
	
	int minorVersion; 
	
	AEGetParamPtr(event->event->appleEvent, kDecEventInfoMinor, typeSInt32, NULL, &minorVersion, sizeof(int), NULL);
	return minorVersion; 
}

void dec_event_info_version_major_set(DecEventInfo* event, int value)
{
	if (event == NULL)
		return; 
	
	AEPutParamPtr(event->event->appleEvent, kDecEventInfoMajor, typeSInt32, &value, sizeof(int)); 	
}

void dec_event_info_version_minor_set(DecEventInfo* event, int value)
{
	if (event == NULL)
		return; 
	
	AEPutParamPtr(event->event->appleEvent, kDecEventInfoMinor, typeSInt32, &value, sizeof(int)); 	
}