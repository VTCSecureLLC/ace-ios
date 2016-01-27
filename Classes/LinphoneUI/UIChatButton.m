/* UIPauseButton.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "UIChatButton.h"
#import "LinphoneManager.h"
#import "InCallViewController.h"

@implementation UIChatButton

UIAlertView *alert;
#pragma mark - Lifecycle Functions

- (void)initUIChatButton {
	type = UIChatButtonType_CurrentCall;
}

- (id)init {
	self = [super init];
	if (self) {
		[self initUIChatButton];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	if (self) {
		[self initUIChatButton];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self initUIChatButton];
	}
	return self;
}

#pragma mark - Static Functions

+ (bool)isInConference:(LinphoneCall *)call {
	if (!call)
		return false;
	return linphone_call_is_in_conference(call);
}

+ (int)notInConferenceCallCount:(LinphoneCore *)lc {
	int count = 0;
	const MSList *calls = linphone_core_get_calls(lc);

	while (calls != 0) {
		if (![UIChatButton isInConference:(LinphoneCall *)calls->data]) {
			count++;
		}
		calls = calls->next;
	}
	return count;
}

+ (LinphoneCall *)getCall {
	LinphoneCore *lc = [LinphoneManager getLc];
	LinphoneCall *currentCall = linphone_core_get_current_call(lc);
	if (currentCall == nil && linphone_core_get_calls_nb(lc) == 1) {
		currentCall = (LinphoneCall *)linphone_core_get_calls(lc)->data;
	}
	return currentCall;
}

#pragma mark -

- (void)setType:(UIChatButtonType)atype call:(LinphoneCall *)acall {
	type = atype;
	call = acall;
}

#pragma mark - UIToggleButtonDelegate Functions

- (void)onOn {
    //Chat mode enabled
   
}


- (BOOL) toggleKeyboard{
    if([[InCallViewController sharedInstance] isFirstResponder]){
        [self dismissKeyboard];
    }
    else{
        [self showKeyboard];
        return YES;
    }
    return NO;
}

-(BOOL) dismissKeyboard{
    [[InCallViewController sharedInstance] resignFirstResponder];
    [InCallViewController sharedInstance].isChatMode = NO;
    return NO;
}

-(BOOL) showKeyboard{
    if([InCallViewController sharedInstance]){
        if(![[InCallViewController sharedInstance] isRTTEnabled]){
            [self displayRTTDisabledMessage];
        }
        else{
            [[InCallViewController sharedInstance] becomeFirstResponder];
            [InCallViewController sharedInstance].isChatMode = YES;
        }
    }
    return YES;
}
-(void) displayRTTDisabledMessage{
    if(!alert){
        alert =[[UIAlertView alloc] initWithTitle:@"RTT"
                                          message:@"RTT has been disabled for this session"
                                         delegate:nil
                                cancelButtonTitle:nil
                                otherButtonTitles:nil];
    }
    if(![alert isVisible]){
        [alert show];
        int duration = 1; // duration in seconds
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [alert dismissWithClickedButtonIndex:0 animated:YES];
        });
    }
}
- (void)onOff {
    //Chat mode disabled
}

- (bool)onUpdate {
    return  [self toggleKeyboard];
}

@end
