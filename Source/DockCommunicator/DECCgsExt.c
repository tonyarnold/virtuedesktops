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

#include "DECCgsExt.h"
#include "DECEvent.h" 
#include "DECEventAlpha.h" 
#include "DECEventLevel.h" 
#include "DECEventOrder.h" 
#include "DECEventDesktop.h" 
#include "DECEventTags.h" 
#include "DECEventProperty.h" 


void CGSExtSetWindowAlpha(int window, float startAlpha, float endAlpha, int animate, float animateSeconds)
{
	CGSExtSetWindowListAlpha(&window, 1, startAlpha, endAlpha, animate, animateSeconds); 
}

void CGSExtSetWindowWorkspace(int window, int desktop)
{
	CGSExtSetWindowListWorkspace(&window, 1, desktop); 
}

void CGSExtOrderWindow(int window, int type, int referenceWindow)
{
	CGSExtOrderWindowList(&window, 1, type, referenceWindow); 
} 

void CGSExtSetWindowTags(int window, int tags)
{
	CGSExtSetWindowListTags(&window, 1, tags); 
} 

void CGSExtClearWindowTags(int window, int tags)
{
	CGSExtClearWindowListTags(&window, 1, tags); 
} 

void CGSExtSetWindowLevel(int window, int level)
{
	CGSExtSetWindowListLevel(&window, 1, level); 
} 

void CGSExtSetWindowProperty(int window, char* key, char* value)
{
	CGSExtSetWindowListProperty(&window, 1, key, value); 
} 

void CGSExtDeleteWindowProperty(int window, char* key)
{
	CGSExtDeleteWindowListProperty(&window, 1, key); 
} 

void CGSExtSetWindowListAlpha(int* windows, int count, float startAlpha, float endAlpha, int animate, float duration)
{
	DecEvent*					event; 
	DecEventAlpha*		eventAlpha;
	
	event = dec_event_new(); 
	
	dec_event_apple_event_new(event); 
	dec_event_targets_set(event, windows, count);
	
	eventAlpha = dec_event_alpha_new(event);
	dec_event_alpha_startvalue_set(eventAlpha, startAlpha);
	dec_event_alpha_endvalue_set(eventAlpha, endAlpha);
	dec_event_alpha_duration_set(eventAlpha, (animate == 0) ? 0 : duration);
		
	dec_event_send_sync(event, NULL); 
	
	dec_event_alpha_free(eventAlpha); 
	dec_event_free(event); 	
} 

void CGSExtSetWindowListWorkspace(int* windows, int count, int desktop)
{
	DecEvent*			event; 
	DecEventDesktop*	eventDesktop; 
	
	event = dec_event_new(); 
	
	dec_event_apple_event_new(event); 
	dec_event_targets_set(event, windows, count); 

	eventDesktop = dec_event_desktop_new(event); 
	dec_event_desktop_value_set(eventDesktop, desktop); 

	dec_event_send_sync(event, NULL); 	
	
	dec_event_desktop_free(eventDesktop); 
	dec_event_free(event); 	
} 

void CGSExtOrderWindowList(int* windows, int count, int type, int referenceWindow) 
{
	DecEvent*		event; 
	DecEventOrder*	eventOrder; 
	
	event = dec_event_new(); 
	
	dec_event_apple_event_new(event); 
	dec_event_targets_set(event, windows, count); 
	
	eventOrder = dec_event_order_new(event); 
	dec_event_order_place_set(eventOrder, type); 
	dec_event_order_reference_set(eventOrder, referenceWindow);
	
	dec_event_send_sync(event, NULL); 	
	
	dec_event_order_free(eventOrder); 
	dec_event_free(event); 	
} 

void CGSExtSetWindowListTags(int* windows, int count, int tags)
{
	DecEvent*		event; 
	DecEventTags*	eventTags; 
	
	event = dec_event_new(); 
	
	dec_event_apple_event_new(event);
	dec_event_targets_set(event, windows, count); 
	
	eventTags = dec_event_tags_new(event); 
	dec_event_tags_type_set(eventTags, kDecTagsSet); 
	dec_event_tags_value_set(eventTags, tags);
	
	dec_event_send_sync(event, NULL); 	
	
	dec_event_tags_free(eventTags); 
	dec_event_free(event); 
} 

void CGSExtClearWindowListTags(int* windows, int count, int tags)
{
	DecEvent*		event; 
	DecEventTags*	eventTags; 
	
	event = dec_event_new(); 
	
	dec_event_apple_event_new(event); 
	dec_event_targets_set(event, windows, count); 
	
	eventTags = dec_event_tags_new(event); 
	dec_event_tags_type_set(eventTags, kDecTagsClear); 
	dec_event_tags_value_set(eventTags, tags);
	
	dec_event_send_sync(event, NULL); 	
	
	dec_event_tags_free(eventTags); 
	dec_event_free(event); 
} 

void CGSExtSetWindowListLevel(int* windows, int count, int level)
{
	DecEvent*		event; 
	DecEventLevel*	eventLevel; 
	
	event = dec_event_new(); 
	
	dec_event_apple_event_new(event); 
	dec_event_targets_set(event, windows, count); 
	
	eventLevel = dec_event_level_new(event); 
	dec_event_level_value_set(eventLevel, level); 
	
	dec_event_send_sync(event, NULL); 	
	
	dec_event_level_free(eventLevel); 
	dec_event_free(event); 
} 

void CGSExtSetWindowListProperty(int* windows, int count, char* key, char* value)
{
	DecEvent*			event; 
	DecEventProperty*	eventProp; 
	
	event = dec_event_new(); 
	
	dec_event_apple_event_new(event); 
	dec_event_targets_set(event, windows, count); 
	
	eventProp = dec_event_property_new(event); 
	dec_event_property_type_set(eventProp, kDecPropertySet); 
	dec_event_property_key_set(eventProp, key);
	dec_event_property_value_set(eventProp, value); 
	
	dec_event_send_sync(event, NULL); 	
	
	dec_event_property_free(eventProp); 
	dec_event_free(event); 
} 

void CGSExtDeleteWindowListProperty(int* windows, int count, char* key)
{
	DecEvent*			event; 
	DecEventProperty*	eventProp; 
	
	event = dec_event_new(); 
	
	dec_event_apple_event_new(event); 
	dec_event_targets_set(event, windows, count); 
	
	eventProp = dec_event_property_new(event); 
	dec_event_property_type_set(eventProp, kDecPropertyDelete); 
	dec_event_property_key_set(eventProp, key);
	
	dec_event_send_sync(event, NULL); 	
	
	dec_event_property_free(eventProp); 
	dec_event_free(event); 
}	

