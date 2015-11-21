//
//  UILabel+Clipboard.h
//  linphone
//

#import <UIKit/UIKit.h>

@interface UILabel (Clipboard)
- (BOOL) canBecomeFirstResponder;
- (void) enableClipboard: (BOOL) enabled;
@end
