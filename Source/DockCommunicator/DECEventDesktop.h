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
#ifndef __DEC_EVENT_DESKTOP_H__
#define __DEC_EVENT_DESKTOP_H__

#include <Carbon/Carbon.h>
#include "DecEvent.h" 

typedef struct _Dec_Event_Desktop DecEventDesktop; 


DecEventDesktop* dec_event_desktop_new(DecEvent* event); 
void dec_event_desktop_free(DecEventDesktop* event); 

int  dec_event_desktop_value_get(DecEventDesktop* event); 
void dec_event_desktop_value_set(DecEventDesktop* event, int value); 


#endif 