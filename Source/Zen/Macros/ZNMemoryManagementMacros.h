//
//  ZNMemoryManagementMacros.h
//  Zen framework
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  

#define	ZEN_ASSIGN(aTarget, aSource)	\
if (aTarget != nil)						\
[	aTarget autorelease];			    \
aTarget = [aSource retain];

#define ZEN_ASSIGN_COPY(aTarget, aSource)	\
if (aTarget != nil)							\
	[aTarget autorelease];					\
aTarget = [aSource copy];

#define ZEN_RELEASE(aTarget)			\
if (aTarget != nil)						\
{										\
	id zen_old = aTarget;				\
	aTarget = nil;						\
	[zen_old release];					\
}
