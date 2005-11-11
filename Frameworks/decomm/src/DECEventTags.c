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

#include "DECEventTags.h"
#include "DECPrivate.h" 

#define kDecEventTagsValueKey		'tags'
#define kDecEventTagsTypeKey		'type'

DecEventTags* dec_event_tags_new(DecEvent* event)
{
	if (event == NULL)
		return NULL; 
	
	DecEventTags* tagsEvent = (DecEventTags*)malloc(sizeof(DecEventTags)); 
	
	tagsEvent->event = event; 
	tagsEvent->event->type = kDecEventTags; 
	
	return tagsEvent; 
}

void dec_event_tags_free(DecEventTags* event)
{
	if (event == NULL)
		return; 
	
	free(event); 
}

int	dec_event_tags_value_get(DecEventTags* event)
{
	if (event == NULL)
		return 0; 

	int value; 
	
	AEGetParamPtr(event->event->appleEvent, kDecEventTagsValueKey, typeSInt32, NULL, &value, sizeof(int), NULL); 
	return value; 
}

void dec_event_tags_value_set(DecEventTags* event, int value)
{
	if (event == NULL)
		return; 
	
	AEPutParamPtr(event->event->appleEvent, kDecEventTagsValueKey, typeSInt32, &value, sizeof(int)); 	
}

DecTagsType	dec_event_tags_type_get(DecEventTags* event)
{
	if (event == NULL)
		return kDecTagsNone; 
	
	DecTagsType type; 
	
	AEGetParamPtr(event->event->appleEvent, kDecEventTagsTypeKey, typeSInt32, NULL, &type, sizeof(int), NULL); 
	return type; 
}

void dec_event_tags_type_set(DecEventTags* event, DecTagsType type)
{
	if (event == NULL)
		return; 
	
	AEPutParamPtr(event->event->appleEvent, kDecEventTagsTypeKey, typeSInt32, &type, sizeof(int));
}
