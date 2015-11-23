//
//  UILabel+Clipboard.m
//  linphone
//


#import "UILabel+Clipboard.h"

@implementation UILabel (Clipboard)

BOOL isClipboardEnabled = NO;
- (BOOL) canBecomeFirstResponder
{
    return YES;
}

- (void) attachTapHandler
{
    [self setUserInteractionEnabled:YES];
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
                                   initWithTarget:self action:@selector(handleTap:)];
    [longPress setCancelsTouchesInView:TRUE];
    longPress.delaysTouchesEnded = TRUE;
    longPress.minimumPressDuration = 0.5;
    [self addGestureRecognizer:longPress];
}

#pragma mark Clipboard

- (void) copy: (id) sender
{
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    pb.string = self.text;
    NSLog(@"Copy handler, label: “%@”.", self.text);
}

- (BOOL) canPerformAction: (SEL) action withSender: (id) sender
{
    if(action == @selector(copy:)){
        if(isClipboardEnabled)
            return YES;
    }
    
    return [super canPerformAction:action withSender:sender];
}

- (void) handleTap: (UIGestureRecognizer*) recognizer
{
    [self becomeFirstResponder];
    
    if(isClipboardEnabled){
        UIMenuController *menu = [UIMenuController sharedMenuController];
        [menu setTargetRect:self.frame inView:self.superview];
        [menu setMenuVisible:YES animated:YES];
    }
}

- (void) enableClipboard: (BOOL) enabled{
    isClipboardEnabled = enabled;
    if(isClipboardEnabled){
        [self attachTapHandler];
    }
}

@end
