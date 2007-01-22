//
//  PNDesktopScripting.m
//  Peony framework
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  

#import "PNDesktopScripting.h"


@implementation PNDesktop(PNScripting)

- (PNTransitionType) typeToNative: (unsigned int) scriptingType {
	switch (scriptingType) {
		case FOUR_CHAR_CODE('TTny'): 
			return kPnTransitionAny; 
		case FOUR_CHAR_CODE('TTcb'):
			return kPnTransitionCube; 
		case FOUR_CHAR_CODE('TTfd'): 
			return kPnTransitionFade; 
		case FOUR_CHAR_CODE('TTno'): 
			return kPnTransitionNone; 
		case FOUR_CHAR_CODE('TTrl'): 
			return kPnTransitionReveal; 
		case FOUR_CHAR_CODE('TTsl'): 
			return kPnTransitionSlide; 
		case FOUR_CHAR_CODE('TTsw'): 
			return kPnTransitionSwap; 
		case FOUR_CHAR_CODE('TTzm'):
			return kPnTransitionZoom; 
		case FOUR_CHAR_CODE('TTwf'): 
			return kPnTransitionWarpFade; 
		case FOUR_CHAR_CODE('TTws'):
			return kPnTransitionWarpSwitch; 
		case FOUR_CHAR_CODE('TTfl'):
			return kPnTransitionFlip;
	}; 
	
	return kPnTransitionNone; 
}

- (PNTransitionOption) optionToNative: (unsigned int) scriptingOption {
	
	switch (scriptingOption) {
		case FOUR_CHAR_CODE('TOay'):
			return kPnOptionAny; 
		case FOUR_CHAR_CODE('TObl'):
			return kPnOptionBottomLeft; 
		case FOUR_CHAR_CODE('TObr'):
			return kPnOptionBottomRight; 
		case FOUR_CHAR_CODE('TOd '): 
			return kPnOptionDown; 
		case FOUR_CHAR_CODE('Tdtr'):
			return kPnOptionDownTopRight; 
		case FOUR_CHAR_CODE('TOib'):
			return kPnOptionInBottom; 
		case FOUR_CHAR_CODE('Tibr'):
			return kPnOptionInBottomRight; 
		case FOUR_CHAR_CODE('TOio'):
			return kPnOptionInOut; 
		case FOUR_CHAR_CODE('TOir'):
			return kPnOptionInRight; 
		case FOUR_CHAR_CODE('TOl '): 
			return kPnOptionLeft; 
		case FOUR_CHAR_CODE('Tlbr'):
			return kPnOptionLeftBottomRight; 
		case FOUR_CHAR_CODE('TOr '): 
			return kPnOptionRight; 
		case FOUR_CHAR_CODE('Trbl'):
			return kPnOptionRightBottomLeft; 
		case FOUR_CHAR_CODE('TOtl'):
			return kPnOptionTopLeft;
		case FOUR_CHAR_CODE('TOtr'):
			return kPnOptionTopRight; 
		case FOUR_CHAR_CODE('TOu '): 
			return kPnOptionUp; 
		case FOUR_CHAR_CODE('Tupr'): 
			return kPnOptionUpBottomRight; 
	}; 
	
	return kPnOptionAny; 
}


@end
