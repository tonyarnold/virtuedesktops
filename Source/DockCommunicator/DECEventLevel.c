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

#include "DECEventLevel.h"
#include "DECPrivate.h" 

#define kDecEventLevelValueKey		'levl'

DecEventLevel* dec_event_level_new(DecEvent* event)
{
	if (event == NULL)
		return NULL; 
	
	DecEventLevel* levelEvent = (DecEventLevel*)malloc(sizeof(DecEventLevel)); 
	
	levelEvent->event = event; 
	levelEvent->event->type = kDecEventLevel; 
	
	return levelEvent; 
}

void dec_event_level_free(DecEventLevel* event)
{
	if (event == NULL)
		return; 
	
	free(event); 
}

int  dec_event_level_value_get(DecEventLevel* event)
{
	if (event == NULL)
		return 0; 
	
	int level; 
	
	AEGetParamPtr(event->event->appleEvent, kDecEventLevelValueKey, typeSInt32, NULL, &level, sizeof(int), NULL); 
	return level; 
}

void dec_event_level_value_set(DecEventLevel* event, int value)
{
	if (event == NULL)
		return; 
	
	AEPutParamPtr(event->event->appleEvent, kDecEventLevelValueKey, typeSInt32, &value, sizeof(int)); 
}