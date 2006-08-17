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

#include "DECEventProperty.h"
#include "DECPrivate.h" 

#define kDecEventPropertyValueKey		'pval'
#define kDecEventPropertyKeyKey			'pkey'
#define kDecEventPropertyTypeKey		'type' 

DecEventProperty* dec_event_property_new(DecEvent* event)
{
	if (event == NULL)
		return NULL; 
	
	DecEventProperty* propEvent = (DecEventProperty*)malloc(sizeof(DecEventProperty)); 
	
	propEvent->event = event; 
	propEvent->propertyKey = NULL; 
	propEvent->propertyValue = NULL; 
	propEvent->event->type = kDecEventProperty; 
	
	return propEvent; 
}

void dec_event_property_free(DecEventProperty* event)
{
	if (event == NULL)
		return; 
	
	if (event->propertyKey)
		free(event->propertyKey); 
	if (event->propertyValue)
		free(event->propertyValue); 
	free(event); 
}

char* dec_event_property_key_get(DecEventProperty* event)
{
	if (event == NULL)
		return NULL; 
	if (event->propertyKey != NULL)
		return event->propertyKey; 
	
	int size; 
	
	AESizeOfParam(event->event->appleEvent, kDecEventPropertyKeyKey, NULL, (Size*)&size); 
	event->propertyKey = (char*)malloc(sizeof(char)*size); 
	AEGetParamPtr(event->event->appleEvent, kDecEventPropertyKeyKey, typeData, NULL, event->propertyKey, size, NULL);	
	
	return event->propertyKey; 
}

char* dec_event_property_value_get(DecEventProperty* event)
{
	if (event == NULL)
		return NULL; 
	if (event->propertyValue != NULL)
		return event->propertyValue; 
	
	int size; 
	
	AESizeOfParam(event->event->appleEvent, kDecEventPropertyValueKey, NULL, (Size*)&size); 
	event->propertyValue = (char*)malloc(sizeof(char)*size); 
	AEGetParamPtr(event->event->appleEvent, kDecEventPropertyValueKey, typeData, NULL, event->propertyValue, size, NULL);	
	
	return event->propertyValue; 
}

void dec_event_property_key_set(DecEventProperty* event, char* value)
{
	if (event == NULL)
		return; 
	
	if (event->propertyKey) 
	{
		free(event->propertyKey); 
		event->propertyKey = NULL; 
	}
	
	AEPutParamPtr(event->event->appleEvent, kDecEventPropertyKeyKey, typeData, value, sizeof(char)*(strlen(value) + 1));	
}

void dec_event_property_value_set(DecEventProperty* event, char* value)
{
	if (event == NULL)
		return; 
	
	if (event->propertyValue) 
	{
		free(event->propertyValue); 
		event->propertyValue = NULL; 
	}
	
	AEPutParamPtr(event->event->appleEvent, kDecEventPropertyValueKey, typeData, value, sizeof(char)*(strlen(value) + 1));	
}

DecPropertyType dec_event_property_type_get(DecEventProperty* event)
{
	if (event == NULL)
		return kDecPropertyNone; 
	
	DecPropertyType type; 
	
	AEGetParamPtr(event->event->appleEvent, kDecEventPropertyTypeKey, typeSInt32, NULL, &type, sizeof(int), NULL);
	return type; 
}

void dec_event_property_type_set(DecEventProperty* event, DecPropertyType type)
{
	if (event == NULL)
		return; 
	
	AEPutParamPtr(event->event->appleEvent, kDecEventPropertyTypeKey, typeSInt32, &type, sizeof(int)); 	
}