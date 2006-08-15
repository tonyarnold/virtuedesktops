/******************************************************************************
* 
* Zen 
*
* A foundations framework 
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2005-2006, Tony Arnold tony@tonyarnold.com
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#define	ZEN_ASSIGN(aTarget, aSource)		\
	if (aTarget != nil)						\
		[aTarget autorelease];				\
	aTarget = [aSource retain];

#define ZEN_ASSIGN_COPY(aTarget, aSource)	\
	if (aTarget != nil)						\
		[aTarget autorelease];				\
	aTarget = [aSource copy];

#define ZEN_RELEASE(aTarget)				\
	if (aTarget != nil)						\
	{										\
		[aTarget release];					\
		aTarget = nil;						\
	}
