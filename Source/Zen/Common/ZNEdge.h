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

#import <Cocoa/Cocoa.h>

typedef enum {
	ZNEdgeAny			= -1,
	ZNEdgeTop			=  0,
	ZNEdgeLeft			=  1,
	ZNEdgeBottom		=  2,
	ZNEdgeRight			=  3,
	ZNEdgeTopLeft		=  4,
	ZNEdgeTopRight		=  5,
	ZNEdgeBottomLeft	=  6,
	ZNEdgeBottomRight	=  7,
} ZNEdge; 