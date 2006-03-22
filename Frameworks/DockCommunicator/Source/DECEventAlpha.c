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

#include "DECEventAlpha.h"
#include "DECEvent.h" 
#include "DECPrivate.h" 

#define kDecEventAlphaStartValueKey	'salp'
#define kDecEventAlphaEndValueKey		'ealp'
#define kDecEventAlphaDurationKey		'dura'

DecEventAlpha* dec_event_alpha_new(DecEvent* event)
{
	if (event == NULL)
		return NULL; 
	
	DecEventAlpha* alphaEvent = (DecEventAlpha*)malloc(sizeof(DecEventAlpha)); 
	alphaEvent->event = event;
	alphaEvent->event->type = kDecEventAlpha; 
	
	return alphaEvent; 
}

void dec_event_alpha_free(DecEventAlpha* event)
{
	if (event == NULL)
		return; 
	
	free(event); 
}

float dec_event_alpha_startvalue_get(DecEventAlpha* event)
{
	if (event == NULL)
		return 0.0; 
	
	float alpha; 
	AEGetParamPtr(event->event->appleEvent, kDecEventAlphaStartValueKey, typeFloat, NULL, &alpha, sizeof(float), NULL); 

	return alpha; 
}

void  dec_event_alpha_startvalue_set(DecEventAlpha* event, float value)
{
	if (event == NULL)
		return; 
	if (event->event == NULL)
		return; 
	
	AEPutParamPtr(event->event->appleEvent, kDecEventAlphaStartValueKey, typeFloat, &value, sizeof(float)); 
}

float dec_event_alpha_endvalue_get(DecEventAlpha* event)
{
	if (event == NULL)
		return 0.0; 
	
	float alpha; 
	AEGetParamPtr(event->event->appleEvent, kDecEventAlphaEndValueKey, typeFloat, NULL, &alpha, sizeof(float), NULL); 
	
	return alpha; 
}

void  dec_event_alpha_endvalue_set(DecEventAlpha* event, float value)
{
	if (event == NULL)
		return; 
	if (event->event == NULL)
		return; 
	
	AEPutParamPtr(event->event->appleEvent, kDecEventAlphaEndValueKey, typeFloat, &value, sizeof(float)); 
}

int dec_event_alpha_duration_get(DecEventAlpha* event)
{
	if (event == NULL)
		return 0; 
	if (event->event == NULL)
		return 0; 
	
	int duration; 
	AEGetParamPtr(event->event->appleEvent, kDecEventAlphaDurationKey, typeSInt32, NULL, &duration, sizeof(int), NULL); 
	
	return duration; 
}

void dec_event_alpha_duration_set(DecEventAlpha* event, int duration)
{
	if (event == NULL)
		return; 
	if (event->event == NULL)
		return; 
		
	AEPutParamPtr(event->event->appleEvent, kDecEventAlphaDurationKey, typeSInt32, &duration, sizeof(int)); 	
}