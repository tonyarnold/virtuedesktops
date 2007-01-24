#import "VTVerticallyCentredTextFieldCell.h"

@interface NSColor (JaguarAPI)
+ (NSColor *)alternateSelectedControlColor;
+ (NSColor *)alternateSelectedControlTextColor;
@end

@implementation VTVerticallyCentredTextFieldCell
// Init and dealloc

- (id)init;
{
  if ([super initTextCell:@""] == nil)
    return nil;
  
  [self setEditable:YES];
  [self setDrawsHighlight:YES];
  [self setScrollable:YES];
  
  return self;
}

- (void)dealloc;
{
  
  [super dealloc];
}

// NSCopying protocol

- (id)copyWithZone:(NSZone *)zone;
{
  VTVerticallyCentredTextFieldCell *copy = [super copyWithZone:zone];
  
  copy->_vtTfFlags.drawsHighlight = _vtTfFlags.drawsHighlight;
  
  return copy;
}

// NSCell Subclass

#define TEXT_VERTICAL_OFFSET (-1.0)
#define FLIP_VERTICAL_OFFSET (-9.0)
#define BORDER_BETWEEN_EDGE_AND_IMAGE (2.0)
#define BORDER_BETWEEN_IMAGE_AND_TEXT (3.0)
#define SIZE_OF_TEXT_FIELD_BORDER (1.0)

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
{
  if (!_vtTfFlags.drawsHighlight)
    return nil;
  else
    return [super highlightColorWithFrame:cellFrame inView:controlView];
}

- (NSColor *)textColor;
{
  if (_vtTfFlags.settingUpFieldEditor)
    return [NSColor blackColor];
  else if (!_vtTfFlags.drawsHighlight && _cFlags.highlighted)
    return [NSColor textBackgroundColor];
  else
    return [super textColor];
}

#define CELL_SIZE_FUDGE_FACTOR 10.0

- (NSSize)cellSize;
{
  NSSize cellSize = [super cellSize];
  // TODO: WJS 1/31/04 -- I REALLY don't think this next line is accurate. It appears to not be used much, anyways, but still...
  cellSize.width += (BORDER_BETWEEN_IMAGE_AND_TEXT * 2.0) + (SIZE_OF_TEXT_FIELD_BORDER * 2.0) + CELL_SIZE_FUDGE_FACTOR;
  return cellSize;
}

#define _calculateDrawingRectsAndSizes \
NSRectEdge rectEdge;  \
NSSize imageSize; \
\
rectEdge =  NSMaxXEdge; \
imageSize = NSZeroSize; \
\
NSRect cellFrame = aRect, ignored; \
if (imageSize.width > 0) \
NSDivideRect(cellFrame, &ignored, &cellFrame, BORDER_BETWEEN_EDGE_AND_IMAGE, rectEdge); \
\
NSRect imageRect, textRect; \
NSDivideRect(cellFrame, &imageRect, &textRect, imageSize.width, rectEdge); \
\
if (imageSize.width > 0) \
NSDivideRect(textRect, &ignored, &textRect, BORDER_BETWEEN_IMAGE_AND_TEXT, rectEdge); \
\
textRect.origin.y += 1.0;


- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
{  
  NSSize contentSize = [self cellSize];
  cellFrame.origin.y += (cellFrame.size.height - contentSize.height) / 2.0;
  cellFrame.size.height = contentSize.height;
    
  // Draw the text
  NSMutableAttributedString *label = [[NSMutableAttributedString alloc] initWithAttributedString:[self attributedStringValue]];
  NSRange labelRange = NSMakeRange(0, [label length]);
  if ([NSColor respondsToSelector:@selector(alternateSelectedControlColor)]) {
    NSColor *highlightColor = [self highlightColorWithFrame:cellFrame inView:controlView];
    BOOL highlighted = [self isHighlighted];
    
    if (highlighted && [highlightColor isEqual:[NSColor alternateSelectedControlColor]]) {
      // add the alternate text color attribute.
      [label addAttribute:NSForegroundColorAttributeName value:[NSColor alternateSelectedControlTextColor] range:labelRange];
    }
  }
  
  [label drawInRect: cellFrame];
  [label release];
}

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag;
{
  return [super trackMouse:theEvent inRect:cellFrame ofView:controlView untilMouseUp:flag];
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent;
{
  _vtTfFlags.settingUpFieldEditor = YES;
  [super editWithFrame:aRect inView:controlView editor:textObj delegate:anObject event:theEvent];
  _vtTfFlags.settingUpFieldEditor = NO;
}
- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength;
{
  _calculateDrawingRectsAndSizes;
  
  /* This puts us off by a single pixel vertically in OmniWeb's workspace panel. - WJS 1/31/04
  if ([controlView isFlipped])
  textRect.origin.y += TEXT_VERTICAL_OFFSET; // Move it up a pixel so we don't draw off the bottom
  else
  textRect.origin.y -= (textRect.size.height + FLIP_VERTICAL_OFFSET);
  */
  textRect.size.height -= 3.0f;
  _vtTfFlags.settingUpFieldEditor = YES;
  [super selectWithFrame:textRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
  _vtTfFlags.settingUpFieldEditor = NO;
}

- (void)setObjectValue:(id <NSObject, NSCopying>)obj;
{
  if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSAttributedString class]]) {
    [super setObjectValue:obj];
    return;
  } else if ([obj isKindOfClass:[NSDictionary class]]) {
    NSDictionary *dictionary = (NSDictionary *)obj;
  }
}

// API

- (BOOL)drawsHighlight;
{
  return _vtTfFlags.drawsHighlight;
}

- (void)setDrawsHighlight:(BOOL)flag;
{
  _vtTfFlags.drawsHighlight = flag;
}

- (NSRect)textRectForFrame:(NSRect)aRect inView:(NSView *)controlView;
{
  _calculateDrawingRectsAndSizes;
  
  return textRect;
}


@end
