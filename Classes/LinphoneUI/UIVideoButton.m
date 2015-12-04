/* UIToggleVideoButton.m
 *
 * Copyright (C) 2011  Belledonne Comunications, Grenoble, France
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

#import "UIVideoButton.h"
#include "LinphoneManager.h"

@implementation UIVideoButton {
	BOOL last_update_state;
}

@synthesize waitView;

- (void)initUIVideoButton {
	last_update_state = FALSE;
}

- (id)init {
	self = [super init];
	if (self) {
		[self initUIVideoButton];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	if (self) {
		[self initUIVideoButton];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self initUIVideoButton];
	}
	return self;
}

- (void)onOn {
	LinphoneCore *lc = [LinphoneManager getLc];

	if (!linphone_core_video_enabled(lc))
		return;

	LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
	if (call) {
		LinphoneCallAppData *callAppData = (__bridge LinphoneCallAppData *)linphone_call_get_user_pointer(call);
		callAppData->videoRequested =
			TRUE; /* will be used later to notify user if video was not activated because of the linphone core*/
        linphone_call_enable_camera(call, TRUE);
	} else {
		LOGW(@"Cannot toggle video button, because no current call");
	}
}

- (void)onOff {
	LinphoneCore *lc = [LinphoneManager getLc];

	if (!linphone_core_video_enabled(lc))
		return;

	LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
	if (call) {
        linphone_call_enable_camera(call, FALSE);
	} else {
		LOGW(@"Cannot toggle video button, because no current call");
	}
}

- (bool)onUpdate {
	bool camera_enabled = false;
	LinphoneCore *lc = [LinphoneManager getLc];
	LinphoneCall *currentCall = linphone_core_get_current_call(lc);
	if (linphone_core_video_supported(lc)) {
		if (linphone_core_video_enabled(lc) && currentCall && linphone_call_camera_enabled(currentCall) &&
			linphone_call_get_state(currentCall) == LinphoneCallStreamsRunning) {
			camera_enabled = TRUE;
		}
	}
	return camera_enabled;
}

@end
