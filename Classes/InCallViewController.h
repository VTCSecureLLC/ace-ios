/* InCallViewController.h
 *
 * Copyright (C) 2009  Belledonne Comunications, Grenoble, France
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

#import <UIKit/UIKit.h>

#import "VideoZoomHandler.h"
#import "UICamSwitch.h"

#import "UICompositeViewController.h"
#import "InCallTableViewController.h"
#import "ExtenableTextField.h"

@class VideoViewController;

@interface InCallViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, UICompositeViewDelegate, UIKeyInput> {
    @private
    UITapGestureRecognizer* singleFingerTap;
    NSTimer* hideControlsTimer;
    BOOL videoShown;
    VideoZoomHandler* videoZoomHandler;
}

@property (nonatomic, strong) IBOutlet InCallTableViewController* callTableController;
@property (nonatomic, strong) IBOutlet UITableView* callTableView;

@property (nonatomic, strong) IBOutlet UIView* videoGroup;
@property (nonatomic, strong) IBOutlet UIView* videoView;
#ifdef TEST_VIDEO_VIEW_CHANGE
@property (nonatomic, retain) IBOutlet UIView* testVideoView;
#endif
@property (nonatomic, strong) IBOutlet UIView* videoPreview;
@property (nonatomic, strong) IBOutlet UICamSwitch* videoCameraSwitch;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView* videoWaitingForFirstImage;


@property (nonatomic) BOOL isChatMode;
+(InCallViewController*) sharedInstance;

@end
