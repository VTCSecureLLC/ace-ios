/* UIConferenceHeader.m
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
 *  GNU Library General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "UIConferenceHeader.h"

#import "LinphoneManager.h"

@implementation UIConferenceHeader

@synthesize stateImage;
@synthesize chatButton;

#pragma mark - Lifecycle Functions

- (id)init {
	return [super initWithNibName:@"UIConferenceHeader" bundle:[NSBundle mainBundle]];
}

#pragma mark - ViewController Functions

- (void)viewDidLoad {
	[super viewDidLoad];
	// Set selected+over background: IB lack !
	[chatButton setImage:[UIImage imageNamed:@"chat_selected.png"]
				 forState:(UIControlStateHighlighted | UIControlStateSelected)];
//	[chatButton setType:UIChatButtonType_Conference call:nil];
}

#pragma mark - Static size Functions

+ (int)getHeight {
	return 50;
}

#pragma mark -

- (void)update {
	[self view]; // Force view load
	[stateImage setHidden:true];
	[chatButton update];
}

@end
