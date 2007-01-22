/******************************************************************************
* 
Peony framework 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller 
* playback@users.sourceforge.net
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#include "main.h" 
#include "DECEvent.h"
#include "DEEventHandlers.h" 
#include "DECVersion.h" 

#include <Carbon/Carbon.h>

#include <mach/mach_init.h>
#include <mach/thread_act.h>

#include <stdio.h>
#include <stdarg.h>
#include <syslog.h> 


int g_minorVersion = 0; 
int g_majorVersion = 1; 


/**
 * @defgroup Group_Virtue_DE VirtueDesktops Dock Extension
 *
 * The VirtueDesktops Dock Extension is used to gain access to window manipulation methods of Carbon that are currently only available as reverse engineered private SPI functions. The extension attaches itself to the MacOX X Dock process and installs AppleEvent handlers that can be used to command the Dock to perform the requested operation. The set of AppleEvents is fixed by this implementation and does not allow dynamic extension during runtime for security reasons, as we do not want the Dock become unstable. 
 *
 * One of the design goals was to keep the injected code as simple and failsafe as possible to not endanger the Dock process. 
 * 
 */ 


/**
 * @brief	Entry point of the dock extension code 
 * @ingroup Group_Virtue_DE
 *
 * This piece of code will be injected into the Mac OS X Dock process to give us access to restricted methods we may find useful in the rest of the framework 
 * 
 * The injected code is intended to be as unintrusive as possible, as failures will crash the Mac OS X Dock, which is, although not dangerous, not pleasant, as VirtueDesktops will stop working after a Dock restart. 
 *
 * For the sake of simplicity, we will install event handlers as the means of communication between the Dock Extension and its clients. 
 */ 
void injectEntry(ptrdiff_t a_iOffset, void *a_poParamBlock, size_t a_iParamSize, char *dummy_pthread_struct) 
{
	OSErr iError;
	
#if defined (__i386__)
	// pierreyves@users.sourceforge.net: Solution suggested by works from Bertrand Guiheneuf (guiheneuf.org)
	// The original comment was :
	//	On intel, per-pthread data is a zone of data that must be allocated. if not, all function trying to access per-pthread data (all mig functions for instance) will crash. 	
	extern void __pthread_set_self(char*);
	__pthread_set_self(dummy_pthread_struct);
#endif
	
	iError = AEInstallEventHandler(kDecEventClass, 
																 kDecEventId, 
																 NewAEEventHandlerUPP((&DEHandleEvent) + a_iOffset), 
																 0,
																 FALSE); 
	if (iError) 
		printf("Installation of Virtue's dock extensions has failed [Error %i]\n", iError); 
		
	/* after we installed the necessary event handlers, we put ourselves to sleep */ 
	thread_suspend(mach_thread_self());
}