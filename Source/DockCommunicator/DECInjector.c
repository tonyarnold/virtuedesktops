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
#include <Carbon/Carbon.h>
#include "DECInjector.h"
#include "DECEvent.h" 
#include "DECEventInfo.h" 

/* standard includes */
#include <signal.h>
/* mach includes */
#include <mach/thread_act.h>
#include <mach/mach_init.h>
/* mach injection lib */
#include "mach_inject.h"

OSErr dec_find_process_by_signature(OSType, OSType, ProcessSerialNumber*);

/* Mac to Mach error morphing. */
#define kDecErrorMac					err_system(0xf)
#define	kDecErrorMainBundleLoad			(err_local | 1)
#define kDecErrorInjectionBundle		(err_local | 2)
#define	kDecErrorInjectionBundleLoad	(err_local | 3)
#define kDecErrorInjectionCode			(err_local | 4)

static mach_error_t	dec_mac_to_mach_error(OSErr a_oError) 
{
	return a_oError ? (kDecErrorMac | a_oError) : err_none;
}


OSErr dec_find_dock_process(ProcessSerialNumber* psn) {
	return dec_find_process_by_signature('APPL', 'dock', psn); 
}

OSErr dec_info(int* isInjected, int* majorVersion, int* minorVersion) {
	if (isInjected == NULL)
		return noErr; 
	
	AppleEvent		replyEvent; 
	DecEvent*		event; 
	DecEvent*		eventReply; 
	DecEventInfo*	eventInfo; 
	DecEventInfo*	eventInfoReply; 
	
	event = dec_event_new(); 
	dec_event_apple_event_new(event); 
	dec_event_targets_set(event, NULL, 0); 
	
	eventInfo = dec_event_info_new(event); 
	
	OSErr error = dec_event_send_sync(event, &replyEvent); 
	if (error) 
	{
		*isInjected = 0; 
		return error; 
	}
	
	int replyError = 0; 
	AEGetParamPtr(&replyEvent, keyErrorNumber, typeSInt32, NULL, &replyError, sizeof(int), NULL); 
	
	if (replyError)
	{
		*isInjected = 0; 
		
		if (majorVersion)
		*majorVersion = 0; 
		if (minorVersion)
		*minorVersion = 0; 
		
		AEDisposeDesc(&replyEvent); 
		
		dec_event_info_free(eventInfo);
		dec_event_free(event); 
		
		return noErr; 
	}
	
	eventReply		= dec_event_new(); 
	dec_event_apple_event_attach(eventReply, &replyEvent); 
	eventInfoReply	= dec_event_info_new(eventReply); 
	
	if (majorVersion)
	*majorVersion = dec_event_info_version_major_get(eventInfoReply); 
	if (minorVersion)
	*minorVersion = dec_event_info_version_minor_get(eventInfoReply); 
	*isInjected   = 1; 
	
	AEDisposeDesc(&replyEvent); 
	
	dec_event_info_free(eventInfo); 
	dec_event_info_free(eventInfoReply); 
	dec_event_free(event); 
	dec_event_free(eventReply); 
	
	return noErr; 
}

#define err_mac			err_system(0xf)	/* Mac (Carbon) errors */
static mach_error_t	_mac_err( OSErr err ) {
	return err ? (err_mac|err) : err_none;
}
#define	mac_err( CODE )	_mac_err( (CODE) );

OSErr dec_inject_code() 
{
	mach_error_t err = err_none;
	//	printf("Attempting to install Dock patch...\n");
	
	// Get the main bundle for the app.
	CFBundleRef mainBundle = NULL;
	if(!err) {
		mainBundle = CFBundleGetMainBundle();
		if( !mainBundle )
			err = kDecErrorMainBundleLoad;
	}
	
	// Find our injection bundle by name.
	CFURLRef injectionURL = NULL;
	if( !err ) {
		injectionURL = CFBundleCopyResourceURL( mainBundle, CFSTR("DockExtension.bundle"), NULL, NULL );
		if( !injectionURL )
			err = kDecErrorInjectionBundle;
	}
	
	if(err) {
		printf("VirtueDesktops => DockExtension: injectionURL failed.\n");
	}
	
	//	Create injection bundle instance.
	CFBundleRef injectionBundle = NULL;
	if( !err ) {
		injectionBundle = CFBundleCreate( kCFAllocatorDefault, injectionURL );
		if( !injectionBundle )
			err = kDecErrorInjectionBundleLoad;
	}
	
	if(err) {
		printf("VirtueDesktops => DockExtension: CFBundleCreate failed.\n");
	}
	
	
	//	Load the thread code injection.
	void *injectionCode = NULL;
	if( !err ) {
		injectionCode = CFBundleGetFunctionPointerForName( injectionBundle, CFSTR(INJECT_ENTRY_SYMBOL));
		if( injectionCode == NULL )
			err = kDecErrorInjectionCode;
	}
	
	if(err) {
		printf("VirtueDesktops => DockExtension: CFBundleGetFunctionPointerForName failed.\n");
	}
	
	//	Find target by signature.
	ProcessSerialNumber psn;
	if( !err )
		err = mac_err( dec_find_process_by_signature( 'APPL', 'dock', &psn ));
	
	if(err) {
		printf("VirtueDesktops => DockExtension: dec_find_process_by_signature failed.\n");
	}
	
	
	//	Convert PSN to PID.
	pid_t dockpid;
	if( !err )
		err = mac_err( GetProcessPID( &psn, &dockpid ) );
	
	if(err) {
		printf("VirtueDesktops => DockExtension: GetProcessPID failed.\n");
	}
	
	
	//	Inject the code.
	if( !err )
		err = mach_inject( injectionCode, NULL, 0, dockpid, 0 );
	
	if(err) {
		printf("VirtueDesktops => DockExtension: mach_inject failed.\n");
	}
	
	//	Clean up.
	if( injectionBundle )
		CFRelease( injectionBundle );
	if( injectionURL )
		CFRelease( injectionURL );
	if( mainBundle )
		CFRelease( mainBundle );
	
	return err;
}

OSErr dec_kill_dock() 
{
	mach_error_t oError = err_none;
	
	/* Find the Dock process by its signature   */
	ProcessSerialNumber oSerial;
	oError = dec_mac_to_mach_error(dec_find_process_by_signature('APPL', 'dock', &oSerial));
	if (oError)
		return oError; 
	
	/* Convert PSN to PID. */
	pid_t oDockPID;
	oError = dec_mac_to_mach_error(GetProcessPID(&oSerial, &oDockPID));
	if (oError)
		return oError; 
	
	/* Die Dock, die... */
	kill(oDockPID, SIGKILL);
	
	return oError; 
}

OSErr dec_find_process_by_signature(OSType a_oType, OSType a_oCreator, ProcessSerialNumber* a_poSerial) 
{
	ProcessSerialNumber oTempSerial = {0, kNoProcess};
	ProcessInfoRec			oProcessInfo;
	
	OSErr oError = noErr;
	
	oProcessInfo.processInfoLength  = sizeof(ProcessInfoRec);
	oProcessInfo.processName				= nil;
	oProcessInfo.processAppSpec			= nil;
	
	while (!oError) 
	{
		/* fetch next process */
		oError = GetNextProcess(&oTempSerial);
		if (oError)
			break; 
		
		/* fetch process information */
		oError = GetProcessInformation(&oTempSerial, &oProcessInfo); 
		if (oError)
			break; 
		
		/* check if we found the requested process */ 
		if (oProcessInfo.processType      == a_oType && 
			oProcessInfo.processSignature == a_oCreator)
		{
			/* set psn and return */
			*a_poSerial = oTempSerial; 
			return noErr; 
		}
	}
	
	/* return error */
	return oError;
}