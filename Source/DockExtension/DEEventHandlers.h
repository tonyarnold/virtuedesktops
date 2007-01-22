/******************************************************************************
 * 
 * DockExtension bundle
 *
 * Copyright 2004, Thomas Staller playback@users.sourceforge.net
 * Copyright 2007, Tony Arnold tony@tonyarnold.com
 *
 * See COPYING for licensing details
 * 
 *****************************************************************************/ 

#ifndef __VT_DE_EVENT_HANDLERS_H__
#define __VT_DE_EVENT_HANDLERS_H__ 

// Carbon includes 
#include <Carbon/Carbon.h>

OSErr DEHandleEvent(const AppleEvent* a_poEvent, AppleEvent* a_poEventReply, SInt32 a_iHandlerRefCon); 

#endif 