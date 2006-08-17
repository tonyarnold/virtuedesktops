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

#include "DECEvent.h"
#include "DECPrivate.h" 

#define kDecEventTargetsKey		'TRGT'

DecEvent* dec_event_new()
{
	/* create the event */ 
	DecEvent* decEvent = (DecEvent*)malloc(sizeof(DecEvent)); 
	if (decEvent == NULL)
		return NULL; 
	
	decEvent->type						= kDecEventNone; 
	decEvent->appleEvent			= NULL;
	decEvent->appleEventOwned	= 0; 
	decEvent->targets					= NULL; 
	decEvent->targetCount			= 0; 
	
	return decEvent; 
}

void dec_event_free(DecEvent* event)
{
	if (event == NULL)
		return; 

	if (event->appleEventOwned && event->appleEvent)
	{
		AEDisposeDesc(event->appleEvent); 
		free(event->appleEvent);
	}
	event->appleEvent	= NULL; 
	if (event->targets)
		free(event->targets); 
	event->targets			= NULL; 
	event->targetCount	= 0; 
	free(event); 
}

void dec_event_apple_event_attach(DecEvent* event, const AppleEvent* appleEvent)
{
	if (event == NULL)
		return; 
	if (appleEvent == NULL)
		return; 
	
	event->appleEvent		= (AppleEvent*)appleEvent;
	event->appleEventOwned	= 0; 
	
	DescType	type; 
	Size		size; 
	OSErr		error; 
	
	error = AEGetParamPtr(event->appleEvent, kDecEventTypeKey, typeSInt32, NULL, &(event->type), sizeof(int), NULL);
	if (error) 
		return; 
	
	/* set up the targets array */ 
	error = AESizeOfParam(event->appleEvent, kDecEventTargetsKey, &type, &size); 
	if (error)
		return; 
	
	/* create the event target memory */
	event->targetCount = size / sizeof(int); 
	event->targets = (int*)malloc(size); 
	AEGetParamPtr(event->appleEvent, kDecEventTargetsKey, typeData, NULL, event->targets, size, NULL); 	
}

void dec_event_apple_event_new(DecEvent* event)
{
	if (event == NULL)
		return; 
 	
	event->appleEvent = (AppleEvent*)malloc(sizeof(AppleEvent)); 
	
    int				iSignature = 'dock';	/* our target */ 
    OSErr			iError;
    AEAddressDesc	oTargetDesc;
    
	/* create the descriptor and bail if creation failed */ 
    iError = AECreateDesc(typeApplSignature, &iSignature, sizeof(int), &oTargetDesc);
	if (iError) 
		return; 
	
	/* create the event. if that fails, continue as we will nonetheless destroy the desc and return */ 
	iError = AECreateAppleEvent(kDecEventClass, kDecEventId, &oTargetDesc, kAutoGenerateReturnID, kAnyTransactionID, event->appleEvent);
    AEDisposeDesc(&oTargetDesc);
	
	event->appleEventOwned = 1; 
}

void dec_event_targets_set(DecEvent* event, int* targets, int targetCount)
{
	if (event == NULL)
		return; 
	if (event->appleEvent == NULL)
		return; 
	
	/* copy targets */ 
	if (targets) {
		event->targets = (int*)malloc(sizeof(int)*targetCount); 
		memcpy(event->targets, targets, (sizeof(int)*targetCount)); 
	}
	else {
		event->targets = NULL; 
	}
	
	event->targetCount	= targetCount; 
	
	AEPutParamPtr(event->appleEvent, kDecEventTargetsKey, typeData, event->targets, (event->targetCount * sizeof(int))); 	
}

int* dec_event_targets_get(DecEvent* event)
{
	if (event == NULL)
		return NULL; 

	return event->targets; 
}

int dec_event_targets_size_get(DecEvent* event)
{
	if (event == NULL)
		return 0; 
	
	return event->targetCount; 
}

int dec_event_type_get(DecEvent* event)
{
	if (event == NULL)
		return kDecEventNone; 
	
	return event->type; 
}

OSErr dec_event_send_asyn(DecEvent* event)
{
	if (event == NULL)
		return noErr; 
	if (event->appleEvent == NULL)
		return noErr; 
	
	/* set type */ 
	AEPutParamPtr(event->appleEvent, kDecEventTypeKey, typeSInt32, &event->type, sizeof(int)); 

	return AESend(event->appleEvent, NULL, kAENoReply, kAENormalPriority, kNoTimeOut, NULL, NULL); 
}

OSErr dec_event_send_sync(DecEvent* event, AppleEvent* replyEvent)
{
	if (event == NULL)
		return noErr; 
	if (event->appleEvent == NULL)
		return noErr; 
	
	/* set type */ 
	AEPutParamPtr(event->appleEvent, kDecEventTypeKey, typeSInt32, &event->type, sizeof(int)); 

	/* decide if we should pass our own reply event or if we just take 
	 * the one passed to us. We do allow passing of NULL there, Apple 
	 * does not... */ 
	if (replyEvent == NULL)
	{
		AppleEvent	oReplyEvent; 
		OSErr		iError; 
		
		iError = AESend(event->appleEvent, &oReplyEvent, kAEWaitReply, kAENormalPriority, 500, NULL, NULL); 
		if (iError) 
			return iError; 
		
		int replyError = 0; 
		AEGetParamPtr(&oReplyEvent, keyErrorNumber, typeSInt32, NULL, &replyError, sizeof(int), NULL); 
		
		
		/* yes, we do not call this function in error cases on purpose, according to 
			* Apple, we should not do this */ 
		AEDisposeDesc(&oReplyEvent); 
		return iError; 
	}
	
	return AESend(event->appleEvent, replyEvent, kAEWaitReply, kAENormalPriority, /* kNoTimeOut */ 500, NULL, NULL); 
}