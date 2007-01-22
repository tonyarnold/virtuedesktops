/******************************************************************************
* 
* DEComm.Peony.Virtue 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2005-2007, Tony Arnold tony@tonyarnold.com
*
* See COPYING for licensing details
* 
*****************************************************************************/ 
#ifndef __DEC_EVENT_LEVEL_H__
#define __DEC_EVENT_LEVEL_H__

#include <Carbon/Carbon.h>
#include "DecEvent.h" 

typedef struct _Dec_Event_Level DecEventLevel; 


DecEventLevel* dec_event_level_new(DecEvent* event); 
void dec_event_level_free(DecEventLevel* event); 

int  dec_event_level_value_get(DecEventLevel* event); 
void dec_event_level_value_set(DecEventLevel* event, int value); 

#endif 