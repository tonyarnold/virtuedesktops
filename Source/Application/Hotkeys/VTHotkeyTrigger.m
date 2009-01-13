/******************************************************************************
* 
* VirtueDesktops 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller <playback@users.sourceforge.net>
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import "VTHotkeyTrigger.h"
#import <Zen/Zen.h>

#define kVtCodingKeyCode			@"keyCode"
#define kVtCodingKeyModifiers	@"keyModifiers"

#pragma mark -
@interface VTHotkeyTrigger(Conversion)
- (NSString*) unicodeToString: (unichar) unicodeChar; 
- (NSString*) charCodeToString: (UInt32) charCode fromKeyCode: (int) keyCode; 
@end 

#pragma mark -
@implementation VTHotkeyTrigger

#pragma mark -
#pragma mark Lifetime 

+ (id) hotkeyWithKeyCode: (int) keyCode andModifiers: (int) modifiers {
	return [[[VTHotkeyTrigger alloc] initWithKeyCode: keyCode andModifiers: modifiers] autorelease]; 
} 

#pragma mark -
- (id) copyWithZone: (NSZone*) zone {
	VTHotkeyTrigger* hotkey = [[VTHotkeyTrigger allocWithZone: zone] initWithKeyCode: mKeyCode andModifiers: mKeyModifiers]; 
	
	// set attributes
	hotkey->mHotkeyRef		= mHotkeyRef; 
	hotkey->mStringValue	= [mStringValue copyWithZone: zone]; 
	
	return hotkey;
}

#pragma mark -
- (id) init {
	return [self initWithKeyCode: -1 andModifiers: 0]; 
}

- (id) initWithKeyCode: (int) keyCode andModifiers: (int) keyModifiers {
	if (self = [super init]) {
		// initialize attributes 
		mKeyCode		= keyCode; 
		mKeyModifiers   = keyModifiers; 
		mHotkeyRef		= 0; 

		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	// unregister if needed 
	if (mRegistered)
		[self unregisterTrigger]; 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Coding
- (void) encodeToDictionary: (NSMutableDictionary*) dictionary {
	[super encodeToDictionary: dictionary]; 
	
	[dictionary setObject: [NSNumber numberWithInt: mKeyCode] forKey: kVtCodingKeyCode]; 
	[dictionary setObject: [NSNumber numberWithInt: mKeyModifiers] forKey: kVtCodingKeyModifiers]; 
}

- (id) decodeFromDictionary: (NSDictionary*) dictionary {
	if (self = [super decodeFromDictionary: dictionary]) {	
		// check if this dictionary contains the stuff we need and return nil if 
		// it does not 
		if ([dictionary objectForKey: kVtCodingKeyCode] == nil) {
			[self autorelease]; 
			return nil; 
		}
	
		mKeyCode      = [[dictionary objectForKey: kVtCodingKeyCode] intValue]; 
		mKeyModifiers	= [[dictionary objectForKey: kVtCodingKeyModifiers] intValue]; 
    	
		return self; 
	}
	
	return nil; 
}

#pragma mark -
#pragma mark Attributes  

- (int) keyCode {
	return mKeyCode; 
}

- (void) setKeyCode: (int) keyCode {
	if (keyCode == mKeyCode)
		return; 
	
	if (mRegistered)
		[self unregisterTrigger]; 
	
	mKeyCode = keyCode; 
	// this operation invalidates the string representation, so we reset it 
	ZEN_RELEASE(mStringValue); 
}

#pragma mark -
- (int) keyModifiers {
	return mKeyModifiers; 
}

- (int) keyCarbonModifiers {
    int cmod = 0;
	
    if (mKeyModifiers & NSCommandKeyMask) { cmod |= cmdKey; }
    if (mKeyModifiers & NSAlternateKeyMask) { cmod |= optionKey; }
    if (mKeyModifiers & NSShiftKeyMask) { cmod |= shiftKey; }
    if (mKeyModifiers & NSControlKeyMask) { cmod |= controlKey; }
    
    return cmod;
}

- (void) setKeyModifiers: (int) keyModifiers {
	if (keyModifiers == mKeyModifiers)
		return; 
	if (mRegistered)
		[self unregisterTrigger]; 
	
	mKeyModifiers = keyModifiers; 
	// this operation invalidates the string representation, so we reset it 
	ZEN_RELEASE(mStringValue); 
} 

#pragma mark -
- (EventHotKeyRef) hotkeyRef {
	return mHotkeyRef; 
}

#pragma mark -

/**
 * @brief	Returns string representation of the Hotkey 
 *
 * @note	Code partially taken from DesktopManager by Rich Wareham 
 *			http://wsmanager.sourceforge.net
 *
 */ 
- (NSString*) stringValue {
	if (mStringValue != nil)
		return mStringValue; 
	
	if (mKeyCode < 0) {
		mStringValue = @""; 
		return mStringValue; 
	}
	
	// what we have to do is convert the virtual key code to the raw character
	// code and then translate that to the resulting string that we return 
	
	KeyboardLayoutRef   kbdLayout;
        Handle	            kchrHandle;

	UInt32              state = 0;
        UniChar             charCode = 0;
        UniCharCount        length;

	KLGetCurrentKeyboardLayout(&kbdLayout);
        KLGetKeyboardLayoutProperty(kbdLayout, kKLKCHRData, (const void**) &kchrHandle);
        if (kchrHandle) {
            // non-Unicode keyboard
            charCode = KeyTranslate(kchrHandle, mKeyCode, &state);
        } else {
            KLGetKeyboardLayoutProperty(kbdLayout, kKLuchrData, (const void**) &kchrHandle);
            if (kchrHandle) {
                // unicode keyboard
                OSErr err = UCKeyTranslate(kchrHandle, mKeyCode,
                                           kUCKeyActionDisplay, 0,
                                           LMGetKbdType(),
                                           kUCKeyTranslateNoDeadKeysMask,
                                           &state, 1, &length, &charCode);
            } else {
                return @"";
            }
        }

        NSMutableString * stringValue = [NSMutableString string];

        // handle modifiers and append them to the resulting string representation
        if (mKeyModifiers & NSControlKeyMask) 
            [stringValue appendString: [self unicodeToString: kControlUnicode]]; 
        if (mKeyModifiers & NSShiftKeyMask) 
            [stringValue appendString: [self unicodeToString: kShiftUnicode]]; 			
        if (mKeyModifiers & NSAlternateKeyMask) 
            [stringValue appendString: [self unicodeToString: kOptionUnicode]]; 			
        if (mKeyModifiers & NSCommandKeyMask) 
            [stringValue appendString: [self unicodeToString: kCommandUnicode]]; 			

        [stringValue appendString: @" "]; 
        [stringValue appendString: [self charCodeToString: charCode fromKeyCode: mKeyCode]]; 
		
        mStringValue = [[NSString stringWithString: stringValue] retain]; 

        return mStringValue;
}

#pragma mark -
#pragma mark Registration

- (void) registerTrigger {
	if (mRegistered) 
		return; 
	
	if (mKeyCode < 0)
		return; 
	
	if (mHotkeyRef != 0)
		[self unregisterTrigger]; 
				
    EventHotKeyID   hotKeyID;
    EventHotKeyRef  hotkeyRef;
    hotKeyID.id = (int)self; 
	
    OSStatus oResult = RegisterEventHotKey([self keyCode], [self keyCarbonModifiers], hotKeyID, GetApplicationEventTarget(), 0, &hotkeyRef);
	if (oResult)
		return; 
	
    mHotkeyRef	= hotkeyRef;	
	mRegistered	= YES; 
}

- (void) unregisterTrigger {
	if (mHotkeyRef == 0)
		return; 
	
    UnregisterEventHotKey(mHotkeyRef);
	
    mRegistered	= NO;
	mHotkeyRef	= 0; 
}

- (BOOL) canRegister {
	return ([self keyCode] >= 0); 
}


#pragma mark -
- (BOOL) isEqual: (id) other {
	if ([other isKindOfClass: [VTHotkeyTrigger class]] == NO)
		return false; 
	
	VTHotkeyTrigger* hotkey = (VTHotkeyTrigger*)other; 
	
	return ((mKeyCode == hotkey->mKeyCode) && (mKeyModifiers == hotkey->mKeyModifiers)); 
}

@end


#pragma mark -
@implementation VTHotkeyTrigger(Conversion)

#pragma mark -
- (NSString*) unicodeToString: (unichar) unicodeChar {
	return [NSString stringWithCharacters: &unicodeChar length: 1]; 
}

- (NSString*) charCodeToString: (UInt32) charCode fromKeyCode: (int) keyCode {
	switch (charCode) {
		// function keys 
		case kFunctionKeyCharCode:
			switch(keyCode) {
				case 122:
					return @"F1";
				case 120:
					return @"F2";
				case 99:
					return @"F3";
				case 118:
					return @"F4";
				case 96:
					return @"F5";
				case 97: 
					return @"F6"; 
				case 98:
					return @"F7";
				case 100:
					return @"F8";
				case 101:
					return @"F9";
				case 109:
					return @"F10";
				case 103:
					return @"F11";
				case 111:
					return @"F12";
				case 105:
					return @"F13";
			}
			break;
			
		case kRightArrowCharCode:
			return [self unicodeToString: 0x2192];
		case kLeftArrowCharCode:
			return [self unicodeToString: 0x2190];
		case kUpArrowCharCode:
			return [self unicodeToString: 0x2191];
		case kDownArrowCharCode:
			return [self unicodeToString: 0x2193];
		case kBackspaceCharCode:
			return [self unicodeToString: 0x232b];
		case kHomeCharCode:
			return [self unicodeToString: 0x2196];
		case kSpaceCharCode:
			return [self unicodeToString: 0x2423];
		case kTabCharCode: 
			return [self unicodeToString: 0x21e5];
		case kReturnCharCode:
			return [self unicodeToString: 0x23ce];
		case kEscapeCharCode:
			return [self unicodeToString: 0x238b];
	}
	
	return [[self unicodeToString: charCode] uppercaseString];
}; 

@end 
