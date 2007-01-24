/* VTVerticallyCentredTextFieldCell */

#import <Cocoa/Cocoa.h>

@interface VTVerticallyCentredTextFieldCell : NSTextFieldCell
{
  struct {
    unsigned int drawsHighlight:1;
    unsigned int settingUpFieldEditor:1;
  } _vtTfFlags;
}

- (BOOL)drawsHighlight;
- (void)setDrawsHighlight:(BOOL)flag;

- (NSRect)textRectForFrame:(NSRect)cellFrame inView:(NSView *)controlView;
@end
