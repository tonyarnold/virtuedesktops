/******************************************************************************
* 
* DEComm.Peony.Virtue 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller 
* playback@users.sourceforge.net
*
* See COPYING for licensing details
* 
*****************************************************************************/ 
#ifndef __DEC_EVENT_ALPHA_H__
#define __DEC_EVENT_ALPHA_H__

#include <Carbon/Carbon.h>
#include "DecEvent.h" 

typedef struct _Dec_Event_Alpha DecEventAlpha; 


DecEventAlpha* dec_event_alpha_new(DecEvent* event); 
void dec_event_alpha_free(DecEventAlpha* event); 

float dec_event_alpha_value_get(DecEventAlpha* event); 
void  dec_event_alpha_value_set(DecEventAlpha* event, float value); 
int   dec_event_alpha_duration_get(DecEventAlpha* event); 
void  dec_event_alpha_duration_set(DecEventAlpha* event, int duration); 

#endif 