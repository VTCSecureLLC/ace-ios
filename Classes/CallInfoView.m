//
//  CallInfoView.m
//  linphone
//
//  Created by Ruben Semerjyan on 3/15/16.
//
//

#import "CallInfoView.h"
#import "LinphoneManager.h"
#import "FastAddressBook.h"
#import "UICallCellDataNew.h"

#define kAnimationDuration 0.5f

@interface CallInfoView ()

@property (nonatomic, strong) IBOutlet UIImageView *avatarImage;
@property (nonatomic, strong) IBOutlet UIView *avatarView;
@property (nonatomic, strong) IBOutlet UIView *audioStatsView;
@property (nonatomic, strong) IBOutlet UILabel *audioCodecLabel;
@property (nonatomic, strong) IBOutlet UILabel *audioCodecHeaderLabel;
@property (nonatomic, strong) IBOutlet UILabel *audioUploadBandwidthLabel;
@property (nonatomic, strong) IBOutlet UILabel *audioUploadBandwidthHeaderLabel;
@property (nonatomic, strong) IBOutlet UILabel *audioDownloadBandwidthLabel;
@property (nonatomic, strong) IBOutlet UILabel *audioDownloadBandwidthHeaderLabel;
@property (nonatomic, strong) IBOutlet UILabel *audioIceConnectivityLabel;
@property (nonatomic, strong) IBOutlet UILabel *audioIceConnectivityHeaderLabel;
@property (nonatomic, strong) IBOutlet UIView *videoStatsView;
@property (nonatomic, strong) IBOutlet UILabel *videoCodecLabel;
@property (nonatomic, strong) IBOutlet UILabel *videoCodecHeaderLabel;
@property (strong, nonatomic) IBOutlet UILabel *videoSentSizeFPSHeaderLabel;
@property (strong, nonatomic) IBOutlet UILabel *videoSentSizeFPSLabel;
@property (strong, nonatomic) IBOutlet UILabel *videoRecvSizeFPSHeaderLabel;
@property (strong, nonatomic) IBOutlet UILabel *videoRecvSizeFPSLabel;
@property (nonatomic, strong) IBOutlet UILabel *videoUploadBandwidthLabel;
@property (nonatomic, strong) IBOutlet UILabel *videoUploadBandwidthHeaderLabel;
@property (nonatomic, strong) IBOutlet UILabel *videoDownloadBandwidthLabel;
@property (nonatomic, strong) IBOutlet UILabel *videoDownloadBandwidthHeaderLabel;
@property (nonatomic, strong) IBOutlet UILabel *videoIceConnectivityLabel;
@property (nonatomic, strong) IBOutlet UILabel *videoIceConnectivityHeaderLabel;
@property (nonatomic, strong) IBOutlet UIView *backgroundView;
@property (nonatomic, strong) IBOutlet UISwipeGestureRecognizer *detailsLeftSwipeGestureRecognizer;
@property (nonatomic, strong) IBOutlet UISwipeGestureRecognizer *detailsRightSwipeGestureRecognizer;
@property (nonatomic, strong) NSTimer *updateTimer;

@end

@implementation CallInfoView

#pragma mark - Lifecycle Functions
- (void)awakeFromNib {
    
    [self setupView];
}


#pragma mark - Instance Methods
- (void)setupView {
    
    [self.avatarView setHidden:NO];
    [self.audioStatsView setHidden:YES];
    [self.videoStatsView setHidden:YES];
    
    if ([LinphoneManager runningOnIpad]) {
        [LinphoneUtils adjustFontSize:self.audioStatsView mult:2.22];
        [LinphoneUtils adjustFontSize:self.videoStatsView mult:2.22];
    }
}

- (void)updateData {
    
    [self stopDataUpdating];
    
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.f
                                                        target:self
                                                      selector:@selector(update)
                                                      userInfo:nil
                                                       repeats:YES];
}

- (void)stopDataUpdating {
    
    [self.updateTimer invalidate];
    self.updateTimer = nil;
}

- (void)dealloc {
    
    [self.updateTimer invalidate];
    self.updateTimer = nil;
}


#pragma mark - Properties Functions
- (void)setData:(UICallCellDataNew *)adata {
    
    if (adata == _data) {
        return;
    }
    if (_data != nil) {
        _data = nil;
    }
    if (adata != nil) {
        _data = adata;
    }
}


#pragma mark - Static Functions
+ (NSString *)iceToString:(LinphoneIceState)state {
    
    switch (state) {
        case LinphoneIceStateNotActivated:
            return NSLocalizedString(@"Not activated", @"ICE has not been activated for this call");
            break;
        case LinphoneIceStateFailed:
            return NSLocalizedString(@"Failed", @"ICE processing has failed");
            break;
        case LinphoneIceStateInProgress:
            return NSLocalizedString(@"In progress", @"ICE process is in progress");
            break;
        case LinphoneIceStateHostConnection:
            return NSLocalizedString(@"Direct connection", @"ICE has established a direct connection to the remote host");
            break;
        case LinphoneIceStateReflexiveConnection:
            return NSLocalizedString(@"NAT(s) connection",
                                     @"ICE has established a connection to the remote host through one or several NATs");
            break;
        case LinphoneIceStateRelayConnection:
            return NSLocalizedString(@"Relay connection", @"ICE has established a connection through a relay");
            break;
    }
}

#pragma mark - Animations

- (void)showWithAnimation:(BOOL)animation completion:(void(^)())completion {
    
    self.viewState = VS_Animating;
    NSTimeInterval duration = animation ? kAnimationDuration : 0;
    [self updateData];
    [UIView animateWithDuration:duration
                     animations:^{
                         
                         self.alpha = 1;
                     } completion:^(BOOL finished) {
                         
                         self.viewState = VS_Opened;
                         if (completion && finished) {
                             completion();
                         }
                     }];
}

//Hides view
- (void)hideWithAnimation:(BOOL)animation completion:(void(^)())completion {
    
    self.viewState = VS_Animating;
    NSTimeInterval duration = animation ? kAnimationDuration : 0;
    
    [UIView animateWithDuration:duration
                     animations:^{
                         
                         self.alpha = 0;
                         [self layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         
                         self.viewState = VS_Closed;
                         [self stopDataUpdating];
                         if (completion && finished) {
                             completion();
                         }
                     }];
}


- (void)update {
    
    if(self.data == nil || self.data.call == NULL) {
        LOGW(@"Cannot update call cell: null call or data");
        return;
    }
    
    [self.avatarImage setImage:self.data.image];
    [self updateStats];
    
    [self updateDetailsView];
}

- (void)updateStats {
    
    if (self.data == nil || self.data.call == NULL) {
        LOGW(@"Cannot update call cell: null call or data");
        return;
    }
    LinphoneCall *call = self.data.call;
    
    const LinphoneCallParams *params = linphone_call_get_current_params(call);
    {
        const PayloadType *payload = linphone_call_params_get_used_audio_codec(params);
        if (payload != NULL) {
            [self.audioCodecLabel setText:[NSString stringWithFormat:@"%s/%i/%i", payload->mime_type, payload->clock_rate,
                                      payload->channels]];
        } else {
            [self.audioCodecLabel setText:NSLocalizedString(@"No codec", nil)];
        }
        const LinphoneCallStats *stats = linphone_call_get_audio_stats(call);
        if (stats != NULL) {
            [self.audioUploadBandwidthLabel setText:[NSString stringWithFormat:@"%1.1f kbits/s", stats->upload_bandwidth]];
            [self.audioDownloadBandwidthLabel
             setText:[NSString stringWithFormat:@"%1.1f kbits/s", stats->download_bandwidth]];
            [self.audioIceConnectivityLabel setText:[CallInfoView iceToString:stats->ice_state]];
        } else {
            [self.audioUploadBandwidthLabel setText:@""];
            [self.audioDownloadBandwidthLabel setText:@""];
            [self.audioIceConnectivityLabel setText:@""];
        }
    }
    
    {
        const PayloadType *payload = linphone_call_params_get_used_video_codec(params);
        if (payload != NULL) {
            [self.videoCodecLabel setText:[NSString stringWithFormat:@"%s/%i", payload->mime_type, payload->clock_rate]];
        } else {
            [self.videoCodecLabel setText:NSLocalizedString(@"No codec", nil)];
        }
        
        const LinphoneCallStats *stats = linphone_call_get_video_stats(call);
        
        if (stats != NULL && linphone_call_params_video_enabled(params)) {
            MSVideoSize sentSize = linphone_call_params_get_sent_video_size(params);
            MSVideoSize recvSize = linphone_call_params_get_received_video_size(params);
            float sentFPS = linphone_call_params_get_sent_framerate(params);
            float recvFPS = linphone_call_params_get_received_framerate(params);
            
            [self.videoUploadBandwidthLabel setText:[NSString stringWithFormat:@"%1.1f kbits/s", stats->upload_bandwidth]];
            [self.videoDownloadBandwidthLabel
             setText:[NSString stringWithFormat:@"%1.1f kbits/s", stats->download_bandwidth]];
            [self.videoIceConnectivityLabel setText:[CallInfoView iceToString:stats->ice_state]];
            [self.videoSentSizeFPSLabel
             setText:[NSString stringWithFormat:@"%dx%d (%.1fFPS)", sentSize.width, sentSize.height, sentFPS]];
            [self.videoRecvSizeFPSLabel
             setText:[NSString stringWithFormat:@"%dx%d (%.1fFPS)", recvSize.width, recvSize.height, recvFPS]];
        } else {
            [self.videoUploadBandwidthLabel setText:@""];
            [self.videoDownloadBandwidthLabel setText:@""];
            [self.videoIceConnectivityLabel setText:@""];
            [self.videoSentSizeFPSLabel setText:@"0x0"];
            [self.videoRecvSizeFPSLabel setText:@"0x0"];
        }
    }
}

- (void)updateDetailsView {
    
    if (self.data == nil || self.data.call == NULL) {
        LOGW(@"Cannot update call cell: null call or data");
        return;
    }
    if (self.data.view == UICallCellOtherView_Avatar && self.avatarView.isHidden) {
        [self.avatarView setHidden:FALSE];
        [self.audioStatsView setHidden:TRUE];
        [self.videoStatsView setHidden:TRUE];
    } else if (self.data.view == UICallCellOtherView_AudioStats && self.audioStatsView.isHidden) {
        [self.avatarView setHidden:TRUE];
        [self.audioStatsView setHidden:FALSE];
        [self.videoStatsView setHidden:TRUE];
    } else if (self.data.view == UICallCellOtherView_VideoStats && self.videoStatsView.isHidden) {
        [self.avatarView setHidden:TRUE];
        [self.audioStatsView setHidden:TRUE];
        [self.videoStatsView setHidden:FALSE];
    }
}


#pragma mark - Action Methods
- (IBAction)doDetailsSwipe:(UISwipeGestureRecognizer *)sender {
    
    CATransition *trans = nil;
    if (self.data != nil) {
        if (sender.direction == UISwipeGestureRecognizerDirectionLeft) {
            if (self.data.view == UICallCellOtherView_MAX - 1) {
                self.data.view = 0;
            } else {
                ++self.data.view;
            }
            trans = [CATransition animation];
            [trans setType:kCATransitionPush];
            [trans setDuration:0.35];
            [trans setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
            [trans setSubtype:kCATransitionFromRight];
        } else if (sender.direction == UISwipeGestureRecognizerDirectionRight) {
            if (self.data.view == 0) {
                self.data.view = UICallCellOtherView_MAX - 1;
            } else {
                --self.data.view;
            }
            trans = [CATransition animation];
            [trans setType:kCATransitionPush];
            [trans setDuration:0.35];
            [trans setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
            [trans setSubtype:kCATransitionFromLeft];
        }
        if (trans) {
            [self.backgroundView.layer removeAnimationForKey:@"transition"];
            [self.backgroundView.layer addAnimation:trans forKey:@"transition"];
            [self updateDetailsView];
        }
    }
}


@end
