/******************************************************************************
* 
* DockExtension Bundle
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2007, Tony Arnold tony@tonyarnold.com
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#include <stdlib.h>
#include <unistd.h>
/* CGS Private stuff */ 
#include "CGSPrivate.h" 
/* Decomm */ 
#include "DEComm.h" 

#include "DEEventHandlers.h"

/* Current version is 1.1 */ 
#define kDeVersionMajor	1
#define kDeVersionMinor	1


void DEHandleAlphaEvent(DecEvent* event);
void DEHandleLevelEvent(DecEvent* event); 
void DEHandleOrderEvent(DecEvent* event); 
void DEHandleTagsEvent(DecEvent* event); 
void DEHandlePropertyEvent(DecEvent* event); 
void DEHandleDesktopEvent(DecEvent* event); 
void DEHandleInfoEvent(DecEvent* event, AppleEvent* replyEvent); 


void DEHandleAlphaEvent(DecEvent* event)
{
	DecEventAlpha* eventAlpha = dec_event_alpha_new(event); 
	if (eventAlpha == NULL)
		return; 
	
	int* eventTargets		= dec_event_targets_get(event); 
	int	 eventTargetsSize	= dec_event_targets_size_get(event); 
	
	if (eventTargets == NULL || eventTargetsSize == 0) {
		dec_event_alpha_free(eventAlpha); 
		return; 
	}
	
	float eventStartValue	= dec_event_alpha_startvalue_get(eventAlpha);
	float eventEndValue		= dec_event_alpha_endvalue_get(eventAlpha);
	float animateSeconds	= dec_event_alpha_duration_get(eventAlpha);
	
	/* @todo Implement animation parameter */ 
	CGSConnection iConnection;
	
	/* Correct input parameter ranges */ 
	if (eventEndValue < 0.0)
		eventEndValue = 0.0; 
	if (eventEndValue > 1.0)
		eventEndValue = 1.0;
	
	if (eventStartValue < 0.0)
		eventStartValue = 0.0; 
	if (eventStartValue > 1.0)
		eventStartValue = 1.0;

	
	/* Get the default connection for our process */ 
	iConnection = _CGSDefaultConnection(); 
	
	if (animateSeconds == 0) {
		CGSSetWindowListAlpha(iConnection, eventTargets, eventTargetsSize, eventEndValue);
	} else {
		/* Animate */
		CGSSetWindowListAlpha(iConnection, eventTargets, eventTargetsSize, eventEndValue);
// Not ready yet
//		if ( eventStartValue > eventEndValue) {
//			for (eventStartValue; eventStartValue <= eventEndValue; eventEndValue += 0.05) {
//				CGSSetWindowListAlpha(iConnection, eventTargets, eventTargetsSize, eventEndValue);
//				usleep(10000);
//			}
//		} else if ( eventStartValue < eventEndValue ) {
//			for (eventStartValue; eventStartValue >= eventEndValue; eventEndValue -= 0.05) {
//				CGSSetWindowListAlpha(iConnection, eventTargets, eventTargetsSize, eventEndValue);
//				usleep(10000);
//			}
//		} else {
//			CGSSetWindowListAlpha(iConnection, eventTargets, eventTargetsSize, eventEndValue);
//		}
		
	}
	
	
	 
	
	/* get rid of the event */ 
	dec_event_alpha_free(eventAlpha); 
}

void DEHandleLevelEvent(DecEvent* event)
{	
	DecEventLevel* eventLevel = dec_event_level_new(event); 
	if (eventLevel == NULL)
		return; 
	
	int* eventTargets		= dec_event_targets_get(event); 
	int	 eventTargetsSize	= dec_event_targets_size_get(event); 
	
	if (eventTargets == NULL || eventTargetsSize == 0) {
		dec_event_level_free(eventLevel); 
		return; 
	}
	
	CGSConnection iConnection; 
	iConnection = _CGSDefaultConnection(); 
	
	int i; 
	OSErr iError; 
	int level = dec_event_level_value_get(eventLevel); 
	
	/* we have to do the list operation on our own, as CGS does not provide an 
	   equivalent */ 
	for (i = 0; i < eventTargetsSize; i++) {
		iError = CGSSetWindowLevel(iConnection, eventTargets[i], &level); 
/* 
		if (iError) 
			printf("DEHandleLevelEvent - CGSSetWindowLevel failed [%i]\n", iError); 
 */ 
	}
	
	dec_event_level_free(eventLevel); 
}

void DEHandleOrderEvent(DecEvent* event)
{	
	DecEventOrder* eventOrder = dec_event_order_new(event); 
	if (eventOrder == NULL)
		return; 
	
	int* eventTargets		= dec_event_targets_get(event); 
	int	 eventTargetsSize	= dec_event_targets_size_get(event); 
	
	if (eventTargets == NULL || eventTargetsSize == 0) {
		dec_event_order_free(eventOrder); 
		return; 
	}
	
	CGSConnection iConnection; 
	
	int place		= dec_event_order_place_get(eventOrder); 
	int reference	= dec_event_order_reference_get(eventOrder); 
	
	/* sanity check on the passed parameters */ 
	if (place < -1 || place > 1)
		return; 
	
	/* fetch the connection */ 
	iConnection = _CGSDefaultConnection(); 
	
	/* carry out operation */
	int i; 
	for (i=0; i<eventTargetsSize; i++) {
		CGSOrderWindow(iConnection, eventTargets[i], place, reference); 
		CGSFlushWindow(iConnection, eventTargets[i], 0); 
	}

	dec_event_order_free(eventOrder); 
}

void DEHandleTagsEvent(DecEvent* event)
{
	DecEventTags* eventTags = dec_event_tags_new(event); 
	if (eventTags == NULL)
		return; 
	
	int* eventTargets		= dec_event_targets_get(event); 
	int	 eventTargetsSize	= dec_event_targets_size_get(event); 
	
	if (eventTargets == NULL || eventTargetsSize == 0) {
		dec_event_tags_free(eventTags); 
		return; 
	}
	
	int i; 
	
	CGSConnection	cgConnection = _CGSDefaultConnection(); 
	CGSWindowTag	cgWindowTags[2] = { 0, 0 };
	
	int					tags = dec_event_tags_value_get(eventTags); 
	DecTagsType	type = dec_event_tags_type_get(eventTags); 
	
	/* I would not feel good about setting the tags for all windows at 
	   once as I do not know what [1] = 0 means for clearing / setting 
	 */ 
  
	for (i = 0; i < eventTargetsSize; i++) {
		OSStatus oResult = CGSGetWindowTags(cgConnection, eventTargets[i], cgWindowTags, 32);
		if (oResult) 
			continue; 
	
		cgWindowTags[0] = tags;
        
		if (type == kDecTagsClear) {
			CGSClearWindowTags( cgConnection, eventTargets[i], cgWindowTags, 32 );
		} else {
			CGSSetWindowTags( cgConnection, eventTargets[i], cgWindowTags, 32 ); 
		}
	}
	
	dec_event_tags_free(eventTags); 
}

void DEHandlePropertyEvent(DecEvent* event)
{
	DecEventProperty* eventProp = dec_event_property_new(event); 
	if (eventProp == NULL)
		return; 
	
	int* eventTargets		= dec_event_targets_get(event); 
	int	 eventTargetsSize	= dec_event_targets_size_get(event); 
	
	if (eventTargets == NULL || eventTargetsSize == 0) {
		dec_event_property_free(eventProp); 
		return; 
	}
	
	char*			key		= dec_event_property_key_get(eventProp); 
	char*			value	= dec_event_property_value_get(eventProp); 
	DecPropertyType	type	= dec_event_property_type_get(eventProp); 
	
	
	CGSValue keyObject		= (int)CFStringCreateCopy(kCFAllocatorDefault, (CFStringRef)key);
	CGSValue valueObject	= (int)NULL; 
	if (value)
		valueObject = (int)value;
		valueObject = (int)CFStringCreateCopy(kCFAllocatorDefault, (CFStringRef)value);
	
	CGSConnection iConnection = _CGSDefaultConnection(); 
	OSErr iError = noErr; 
	int i; 
	
	/* Have to iterate on our own as there is no CGS equivalent there */ 
	for (i = 0; i < eventTargetsSize; i++) {
		if (type == kDecPropertySet) 
			iError = CGSSetWindowProperty(iConnection, eventTargets[i], keyObject, &valueObject); 
		else
/*			
			CGSDeleteWindowProperty(iConnection, eventTargets[i], keyObject); 
*/
			/* NOP */;
		
		if (iError)
			printf("DEHandlePropertyEvent - Accessing window property failed [%i]\n", iError); 
	}
	
	CGSReleaseGenericObj(&keyObject); 
	if (value)
		CGSReleaseGenericObj(&valueObject); 
}

void DEHandleDesktopEvent(DecEvent* event) 
{
	DecEventDesktop* desktopEvent = dec_event_desktop_new(event); 
	if (desktopEvent == NULL)
		return; 
	
	int* eventTargets		= dec_event_targets_get(event); 
	int	 eventTargetsSize	= dec_event_targets_size_get(event); 
	
	if (eventTargets == NULL || eventTargetsSize == 0) {
		dec_event_desktop_free(desktopEvent); 
		return; 
	}	
	
	CGSConnection oConnection = _CGSDefaultConnection(); 
	
	/* carry out operation */ 
	CGSMoveWorkspaceWindowList(oConnection, dec_event_targets_get(event), dec_event_targets_size_get(event), dec_event_desktop_value_get(desktopEvent));	
	dec_event_desktop_free(desktopEvent); 
}

void DEHandleInfoEvent(DecEvent* event, AppleEvent* appleReplyEvent)
{
	/* TODO: 
	 * Find out how to check if the received event wants a reply. 
	 * Message to Apple: Please provide a bit more documentation about AppleEvent event
	 * handling, as I did not manage to find out anything about reply event sending. 
	 */ 
	
	DecEvent* replyEvent = dec_event_new(); 
	dec_event_apple_event_attach(replyEvent, appleReplyEvent); 
	DecEventInfo* eventInfo = dec_event_info_new(replyEvent); 

	/* fill the reply event structure */ 
	dec_event_info_version_major_set(eventInfo, kDeVersionMajor); 
	dec_event_info_version_minor_set(eventInfo, kDeVersionMinor); 

	dec_event_info_free(eventInfo); 
	dec_event_free(replyEvent); 
}


OSErr DEHandleEvent(const AppleEvent* appleEvent, AppleEvent* appleReplyEvent, SInt32 handlerRefCon)
{
	DecEvent* event = dec_event_new();

	/* read the event from the received apple event */ 
	dec_event_apple_event_attach(event, appleEvent); 
	
	/* choose correct handler by type */ 
	DecEventType eventType = dec_event_type_get(event); 
	switch (eventType) {
	case kDecEventAlpha: 
		DEHandleAlphaEvent(event); 
		break; 
	case kDecEventOrder: 
		DEHandleOrderEvent(event); 
		break; 
	case kDecEventLevel: 
		DEHandleLevelEvent(event); 
		break; 
	case kDecEventDesktop: 
		DEHandleDesktopEvent(event); 
		break; 
	case kDecEventTags: 
		DEHandleTagsEvent(event); 
		break; 
	case kDecEventProperty: 
		DEHandlePropertyEvent(event); 
		break; 
	case kDecEventInfo: 
		DEHandleInfoEvent(event, appleReplyEvent); 
		break; 
		
	default: 
		printf("DockExtension invalid/unknown event type - ignoring [Type: %i]", eventType); 
	};
	
	/* and free the event */ 
	dec_event_free(event); 
	
	return noErr; 
}

