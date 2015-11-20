//
//  UILabel+Clipboard.h
//  linphone
//
//  Created by Zack Matthews on 11/20/15.
//
//

#import <UIKit/UIKit.h>

@interface UILabel (Clipboard)
- (BOOL) canBecomeFirstResponder;
- (void) enableClipboard: (BOOL) enabled;
@end
