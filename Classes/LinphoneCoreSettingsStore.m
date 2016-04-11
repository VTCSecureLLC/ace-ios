/* LinphoneCoreSettingsStore.m
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

#import "LinphoneCoreSettingsStore.h"
#import "SDPNegotiationService.h"
#import "DTAlertView.h"

#include "linphone/lpconfig.h"

extern void linphone_iphone_log_handler(const char *domain, OrtpLogLevel lev, const char *fmt, va_list args);

@implementation LinphoneCoreSettingsStore

- (id)init {
	self = [super init];
	if (self) {
		dict = [[NSMutableDictionary alloc] init];
		changedDict = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)setCString:(const char *)value forKey:(NSString *)key {
	id obj = Nil;
	if (value)
		obj = [[NSString alloc] initWithCString:value encoding:[NSString defaultCStringEncoding]];
	[self setObject:obj forKey:key];
}

- (NSString *)stringForKey:(NSString *)key {
	return [self objectForKey:key];
}

- (void)setObject:(id)value forKey:(NSString *)key {
	[dict setValue:value forKey:key];
	[changedDict setValue:[NSNumber numberWithBool:TRUE] forKey:key];
}

- (id)objectForKey:(NSString *)key {
	return [dict valueForKey:key];
}

- (BOOL)valueChangedForKey:(NSString *)key {
	return [[changedDict valueForKey:key] boolValue];
}

+ (int)validPort:(int)port {
	if (port < 0) {
		return 0;
	}
	if (port > 65535) {
		return 65535;
	}
	return port;
}

+ (BOOL)parsePortRange:(NSString *)text minPort:(int *)minPort maxPort:(int *)maxPort {
	NSError *error = nil;
	*minPort = -1;
	*maxPort = -1;
	NSRegularExpression *regex =
		[NSRegularExpression regularExpressionWithPattern:@"([0-9]+)(([^0-9]+)([0-9]+))?" options:0 error:&error];
	if (error != NULL)
		return FALSE;
	NSArray *matches = [regex matchesInString:text options:0 range:NSMakeRange(0, [text length])];
	if ([matches count] == 1) {
		NSTextCheckingResult *match = [matches objectAtIndex:0];
		bool range = [match rangeAtIndex:2].length > 0;
		if (!range) {
			NSRange rangeMinPort = [match rangeAtIndex:1];
			*minPort = [LinphoneCoreSettingsStore validPort:[[text substringWithRange:rangeMinPort] intValue]];
			*maxPort = *minPort;
			return TRUE;
		} else {
			NSRange rangeMinPort = [match rangeAtIndex:1];
			*minPort = [LinphoneCoreSettingsStore validPort:[[text substringWithRange:rangeMinPort] intValue]];
			NSRange rangeMaxPort = [match rangeAtIndex:4];
			*maxPort = [LinphoneCoreSettingsStore validPort:[[text substringWithRange:rangeMaxPort] intValue]];
			if (*minPort > *maxPort) {
				*minPort = *maxPort;
			}
			return TRUE;
		}
	}
	return FALSE;
}

- (void)transformCodecsToKeys:(const MSList *)codecs {
    LinphoneCore *lc = [LinphoneManager getLc];
	const MSList *elem = codecs;
	for (; elem != NULL; elem = elem->next) {
		PayloadType *pt = (PayloadType *)elem->data;
		NSString *pref = [SDPNegotiationService getPreferenceForCodec:pt->mime_type withRate:pt->clock_rate];
		if (pref) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            if(![[[defaults dictionaryRepresentation] allKeys] containsObject:pref]){
                [defaults setBool:TRUE forKey:pref];
                [defaults synchronize];
            }
            linphone_core_enable_payload_type(lc, pt, [defaults boolForKey:pref]);
			[self setBool:[defaults boolForKey:pref] forKey:pref];
		} else {
			LOGW(@"Codec %s/%i supported by core is not shown in iOS app config view.", pt->mime_type, pt->clock_rate);
		}
	}
}

-(void) setRtcpFbMode: (BOOL)overwrite{
    NSString *rtcpFeedbackMode = [[NSUserDefaults standardUserDefaults] objectForKey:@"rtcp_feedback_pref"];
    if(overwrite){
        [self setObject:rtcpFeedbackMode forKey:@"rtcp_feedback_pref"];
    }
    
    if([rtcpFeedbackMode isEqualToString:@"Implicit"]){
        linphone_core_set_avpf_mode([LinphoneManager getLc], LinphoneAVPFDisabled);
        [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"avpf_preference"];
        if(overwrite){
            [self setBool:FALSE forKey:@"avpf_preference"];
        }
        LinphoneProxyConfig *defaultProxy = linphone_core_get_default_proxy_config([LinphoneManager getLc]);
        if(defaultProxy){
            linphone_proxy_config_enable_avpf(defaultProxy, FALSE);
            linphone_proxy_config_set_avpf_rr_interval(defaultProxy, 3);
            linphone_core_set_avpf_rr_interval([LinphoneManager getLc], 3);
        }
        lp_config_set_int([[LinphoneManager instance] configDb],  "rtp", "rtcp_fb_implicit_rtcp_fb", 1);
    }
    else if([rtcpFeedbackMode isEqualToString:@"Explicit"]){
        linphone_core_set_avpf_mode([LinphoneManager getLc], LinphoneAVPFEnabled);
        [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"avpf_preference"];
        if(overwrite){
            [self setBool:TRUE forKey:@"avpf_preference"];
        }
        LinphoneProxyConfig *defaultProxy = linphone_core_get_default_proxy_config([LinphoneManager getLc]);
        if(defaultProxy){
            linphone_proxy_config_enable_avpf(defaultProxy, TRUE);
            linphone_proxy_config_set_avpf_rr_interval(defaultProxy, 3);
            linphone_core_set_avpf_rr_interval([LinphoneManager getLc], 3);
        }
        lp_config_set_int([[LinphoneManager instance] configDb],  "rtp", "rtcp_fb_implicit_rtcp_fb", 1);
    }
    else{
        linphone_core_set_avpf_mode([LinphoneManager getLc], LinphoneAVPFDisabled);
        [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"avpf_preference"];
        if(overwrite){
            [self setBool:FALSE forKey:@"avpf_preference"];
        }
        LinphoneProxyConfig *defaultProxy = linphone_core_get_default_proxy_config([LinphoneManager getLc]);
        if(defaultProxy){
            linphone_proxy_config_enable_avpf(defaultProxy, FALSE);
            linphone_proxy_config_set_avpf_rr_interval(defaultProxy, 3);
            linphone_core_set_avpf_rr_interval([LinphoneManager getLc], 3);
        }
        lp_config_set_int([[LinphoneManager instance] configDb],  "rtp", "rtcp_fb_implicit_rtcp_fb", 0);
    }
    
}
- (void)transformLinphoneCoreToKeys {
	LinphoneManager *lm = [LinphoneManager instance];
	LinphoneCore *lc = [LinphoneManager getLc];
    
    // Save RTT option.
    BOOL rtt = [lm lpConfigBoolForKey:@"rtt" withDefault:YES];
    [self setBool:rtt forKey:@"enable_rtt"];
    
	// root section
	{
		LinphoneProxyConfig *cfg = NULL;
		linphone_core_get_default_proxy(lc, &cfg);
		if (cfg) {
			const char *identity = linphone_proxy_config_get_identity(cfg);
			LinphoneAddress *addr = linphone_address_new(identity);
			if (addr) {
				const char *proxy = linphone_proxy_config_get_addr(cfg);
				LinphoneAddress *proxy_addr = linphone_address_new(proxy);
				int port = linphone_address_get_port(proxy_addr);

				[self setCString:linphone_address_get_username(addr) forKey:@"username_preference"];
				[self setCString:linphone_address_get_domain(addr) forKey:@"domain_preference"];
				if (strcmp(linphone_address_get_domain(addr), linphone_address_get_domain(proxy_addr)) != 0 ||
					port > 0) {
					char tmp[256] = {0};
					if (port > 0) {
						snprintf(tmp, sizeof(tmp) - 1, "%s:%i", linphone_address_get_domain(proxy_addr), port);
					} else
						snprintf(tmp, sizeof(tmp) - 1, "%s", linphone_address_get_domain(proxy_addr));
					[self setCString:tmp forKey:@"proxy_preference"];
				}
				const char *tname = "tcp";
				switch (linphone_address_get_transport(proxy_addr)) {
				case LinphoneTransportTls:
					tname = "tls";
					break;
				default:
					break;
				}
				linphone_address_destroy(addr);
				linphone_address_destroy(proxy_addr);

				[self setCString:tname forKey:@"transport_preference"];
				[self setBool:(linphone_proxy_config_get_route(cfg) != NULL)forKey:@"outbound_proxy_preference"];
				[self setBool:true forKey:@"enable_video_preference"];
				[self setBool:[LinphoneManager.instance lpConfigBoolForKey:@"auto_answer"]
					   forKey:@"enable_auto_answer_preference"];
                
                [self setRtcpFbMode: FALSE];
				// actually in Advanced section but proxy config dependent
				[self setInteger:linphone_proxy_config_get_expires(cfg) forKey:@"expire_preference"];
				// actually in Call section but proxy config dependent
				[self setCString:linphone_proxy_config_get_dial_prefix(cfg) forKey:@"prefix_preference"];
				// actually in Call section but proxy config dependent
				[self setBool:linphone_proxy_config_get_dial_escape_plus(cfg) forKey:@"substitute_+_by_00_preference"];
			}
		} else {
			[self setObject:@"" forKey:@"username_preference"];
			[self setObject:@"" forKey:@"password_preference"];
			[self setObject:@"" forKey:@"domain_preference"];
			[self setObject:@"" forKey:@"proxy_preference"];
			[self setCString:"tcp" forKey:@"transport_preference"];
			[self setBool:FALSE forKey:@"outbound_proxy_preference"];
			[self setBool:FALSE forKey:@"avpf_preference"];
			// actually in Advanced section but proxy config dependent
			[self setInteger:[lm lpConfigIntForKey:@"reg_expires" forSection:@"default_values" withDefault:600]
					  forKey:@"expire_preference"];
		}

		LinphoneAuthInfo *ai;
		const MSList *elem = linphone_core_get_auth_info_list(lc);
		if (elem && (ai = (LinphoneAuthInfo *)elem->data)) {
			[self setCString:linphone_auth_info_get_userid(ai) forKey:@"userid_preference"];
			[self setCString:linphone_auth_info_get_passwd(ai) forKey:@"password_preference"];
			// hidden but useful if provisioned
			[self setCString:linphone_auth_info_get_ha1(ai) forKey:@"ha1_preference"];
		}
		[self setBool:[lm lpConfigBoolForKey:@"advanced_account_preference"] forKey:@"advanced_account_preference"];
	}

	// audio section
	{
		[self transformCodecsToKeys:linphone_core_get_audio_codecs(lc)];
		[self setFloat:linphone_core_get_playback_gain_db(lc) forKey:@"playback_gain_preference"];
		[self setFloat:linphone_core_get_mic_gain_db(lc) forKey:@"microphone_gain_preference"];
		[self setInteger:[lm lpConfigIntForKey:@"codec_bitrate_limit"
									forSection:@"audio"
								   withDefault:kLinphoneAudioVbrCodecDefaultBitrate]
				  forKey:@"audio_codec_bitrate_limit_preference"];
		[self setInteger:[lm lpConfigIntForKey:@"voiceproc_preference" withDefault:1] forKey:@"voiceproc_preference"];
		[self setInteger:[lm lpConfigIntForKey:@"eq_active" forSection:@"sound" withDefault:0] forKey:@"eq_active"];
	}

	// video section
	{
		[self transformCodecsToKeys:linphone_core_get_video_codecs(lc)];

		const LinphoneVideoPolicy *pol;
		pol = linphone_core_get_video_policy(lc);
		[self setBool:(pol->automatically_initiate) forKey:@"start_video_preference"];
		[self setBool:(pol->automatically_accept) forKey:@"accept_video_preference"];
		[self setBool:linphone_core_self_view_enabled(lc) forKey:@"self_video_preference"];
		BOOL previewEnabled = [lm lpConfigBoolForKey:@"preview_preference" withDefault:YES];
		[self setBool:previewEnabled forKey:@"preview_preference"];

		const char *preset = linphone_core_get_video_preset(lc);
        if(!preset){
            preset = "high-fps";
            linphone_core_set_video_preset(lc, preset);
        }
		[self setCString:preset ? preset : "high-fps" forKey:@"video_preset_preference"];
        MSVideoSize vsize;
        
        linphone_core_set_adaptive_rate_algorithm(lc, "Stateful");
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if(![[[defaults dictionaryRepresentation] allKeys] containsObject:@"video_preferred_size_preference"]){
            [defaults setObject:@"cif" forKey:@"video_preferred_size_preference"];
        }
        [self setObject:[defaults objectForKey:@"video_preferred_size_preference"] forKey:@"video_preferred_size_preference"];
        
        if([[defaults objectForKey:@"video_preferred_size_preference"] isEqualToString:@"vga"]){
            MS_VIDEO_SIZE_ASSIGN(vsize, VGA);
        }
        if([[defaults objectForKey:@"video_preferred_size_preference"] isEqualToString:@"cif"]){
            MS_VIDEO_SIZE_ASSIGN(vsize, CIF);
        }
        if([[defaults objectForKey:@"video_preferred_size_preference"] isEqualToString:@"qvga"]){
            MS_VIDEO_SIZE_ASSIGN(vsize, QVGA);
        }
       
        linphone_core_set_preferred_video_size(lc, vsize);
		[self setInteger:linphone_core_get_preferred_framerate(lc) forKey:@"video_preferred_fps_preference"];
		[self setInteger:linphone_core_get_download_bandwidth(lc) forKey:@"download_bandwidth_preference"];
       
        [self setRtcpFbMode: TRUE];
    }
    //Speaker mute
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isSpeakerMuted = [defaults boolForKey:@"mute_speaker_preference"];
    
    if(![[[defaults dictionaryRepresentation] allKeys] containsObject:@"mute_speaker_preference"]){
        isSpeakerMuted = NO;
    }

    [self setBool:isSpeakerMuted forKey:@"mute_speaker_preference"];
    //Mic mute
    BOOL isMicMuted = [defaults boolForKey:@"mute_microphone_preference"];
    
    if(![[[defaults dictionaryRepresentation] allKeys] containsObject:@"mute_microphone_preference"]){
        isMicMuted = NO;
    }
    [self setBool:isMicMuted forKey:@"mute_microphone_preference"];

	// call section
	{
		[self setBool:linphone_core_get_use_info_for_dtmf(lc) forKey:@"sipinfo_dtmf_preference"];
		[self setBool:linphone_core_get_use_rfc2833_for_dtmf(lc) forKey:@"rfc_dtmf_preference"];

		[self setInteger:linphone_core_get_inc_timeout(lc) forKey:@"incoming_call_timeout_preference"];
		[self setInteger:linphone_core_get_in_call_timeout(lc) forKey:@"in_call_timeout_preference"];

		[self setBool:[lm lpConfigBoolForKey:@"repeat_call_notification"]
			   forKey:@"repeat_call_notification_preference"];
	}

	// network section
	{
		[self setBool:[lm lpConfigBoolForKey:@"edge_opt_preference" withDefault:NO] forKey:@"edge_opt_preference"];
		[self setBool:[lm lpConfigBoolForKey:@"wifi_only_preference" withDefault:NO] forKey:@"wifi_only_preference"];
		[self setCString:linphone_core_get_stun_server(lc) forKey:@"stun_preference"];
		[self setBool:linphone_core_get_firewall_policy(lc) == LinphonePolicyUseIce forKey:@"ice_preference"];
		int random_port_preference = [lm lpConfigIntForKey:@"random_port_preference" withDefault:1];
		[self setInteger:random_port_preference forKey:@"random_port_preference"];
		int port = [lm lpConfigIntForKey:@"port_preference" withDefault:5060];
		[self setInteger:port forKey:@"port_preference"];
		{
			int minPort, maxPort;
			linphone_core_get_audio_port_range(lc, &minPort, &maxPort);
			if (minPort != maxPort)
				[self setObject:[NSString stringWithFormat:@"%d-%d", minPort, maxPort] forKey:@"audio_port_preference"];
			else
				[self setObject:[NSString stringWithFormat:@"%d", minPort] forKey:@"audio_port_preference"];
		}
		{
			int minPort, maxPort;
			linphone_core_get_video_port_range(lc, &minPort, &maxPort);
			if (minPort != maxPort)
				[self setObject:[NSString stringWithFormat:@"%d-%d", minPort, maxPort] forKey:@"video_port_preference"];
			else
				[self setObject:[NSString stringWithFormat:@"%d", minPort] forKey:@"video_port_preference"];
		}
		[self setBool:[lm lpConfigBoolForKey:@"use_ipv6" withDefault:YES] forKey:@"use_ipv6"];
		LinphoneMediaEncryption menc = linphone_core_get_media_encryption(lc);
		const char *val;
		switch (menc) {
		case LinphoneMediaEncryptionSRTP:
			val = "SRTP";
			break;
		case LinphoneMediaEncryptionZRTP:
			val = "ZRTP";
			break;
		case LinphoneMediaEncryptionDTLS:
			val = "DTLS";
			break;
		case LinphoneMediaEncryptionNone:
			val = "None";
			break;
		}
		[self setCString:val forKey:@"media_encryption_preference"];
		[self setBool:[lm lpConfigBoolForKey:@"pushnotification_preference" withDefault:NO]
			   forKey:@"pushnotification_preference"];
		[self setInteger:linphone_core_get_upload_bandwidth(lc) forKey:@"upload_bandwidth_preference"];
		[self setInteger:linphone_core_get_download_bandwidth(lc) forKey:@"download_bandwidth_preference"];
		[self setBool:linphone_core_adaptive_rate_control_enabled(lc) forKey:@"adaptive_rate_control_preference"];
	}

	// tunnel section
	if (linphone_core_tunnel_available()) {
		LinphoneTunnel *tunnel = linphone_core_get_tunnel([LinphoneManager getLc]);
		[self setObject:[lm lpConfigStringForKey:@"tunnel_mode_preference" withDefault:@"off"]
				 forKey:@"tunnel_mode_preference"];
		const MSList *configs = linphone_tunnel_get_servers(tunnel);
		if (configs != NULL) {
			LinphoneTunnelConfig *ltc = (LinphoneTunnelConfig *)configs->data;
			[self setCString:linphone_tunnel_config_get_host(ltc) forKey:@"tunnel_address_preference"];
			[self setInteger:linphone_tunnel_config_get_port(ltc) forKey:@"tunnel_port_preference"];
		} else {
			[self setCString:"" forKey:@"tunnel_address_preference"];
			[self setInteger:443 forKey:@"tunnel_port_preference"];
		}
	}

	// advanced section
	{
		[self setBool:[lm lpConfigBoolForKey:@"debugenable_preference" withDefault:NO]
			   forKey:@"debugenable_preference"];
		[self setBool:[lm lpConfigBoolForKey:@"animations_preference" withDefault:NO] forKey:@"animations_preference"];
		[self setBool:[lm lpConfigBoolForKey:@"backgroundmode_preference" withDefault:NO]
			   forKey:@"backgroundmode_preference"];
		[self setBool:[lm lpConfigBoolForKey:@"start_at_boot_preference" withDefault:NO]
			   forKey:@"start_at_boot_preference"];
		[self setBool:[lm lpConfigBoolForKey:@"autoanswer_notif_preference" withDefault:NO]
			   forKey:@"autoanswer_notif_preference"];
        [self setQoSInitialValues];
        [self set508ForceInitialValue];
       		[self setBool:[lm lpConfigBoolForKey:@"enable_first_login_view_preference" withDefault:NO]
			   forKey:@"enable_first_login_view_preference"];
		LinphoneAddress *parsed = linphone_core_get_primary_contact_parsed(lc);
		if (parsed != NULL) {
			[self setCString:linphone_address_get_display_name(parsed) forKey:@"primary_displayname_preference"];
			[self setCString:linphone_address_get_username(parsed) forKey:@"primary_username_preference"];
		}
		linphone_address_destroy(parsed);
		[self setCString:linphone_core_get_file_transfer_server(lc) forKey:@"file_transfer_server_url_preference"];
	}

	changedDict = [[NSMutableDictionary alloc] init];

	// Post event
	NSDictionary *eventDic = [NSDictionary dictionaryWithObject:self forKey:@"settings"];
	[[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneLogsUpdate object:self userInfo:eventDic];
}

- (void)alertAccountError:(NSString *)error {
	UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
														message:error
													   delegate:nil
											  cancelButtonTitle:NSLocalizedString(@"OK", nil)
											  otherButtonTitles:nil];
	[alertview show];
}

- (void)setQoSInitialValues {
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"QoS"]) {
        // First time
        [self setBool:YES forKey:@"QoS"];
    } else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"QoS"] integerValue] == 1) {
        // Turned On
        int signalValue = 24;
        int audioValue = 46;
        int videoValue = 46;
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"signaling_preference"] ||
            [[NSUserDefaults standardUserDefaults] objectForKey:@"audio_preference"] ||
            [[NSUserDefaults standardUserDefaults] objectForKey:@"video_preference"]) {
            signalValue = [[[NSUserDefaults standardUserDefaults] objectForKey:@"signaling_preference"] intValue];
            audioValue = [[[NSUserDefaults standardUserDefaults] objectForKey:@"audio_preference"] intValue];
            videoValue = [[[NSUserDefaults standardUserDefaults] objectForKey:@"video_preference"] intValue];
        }
        linphone_core_set_sip_dscp([LinphoneManager getLc], signalValue);
        linphone_core_set_audio_dscp([LinphoneManager getLc], audioValue);
        linphone_core_set_video_dscp([LinphoneManager getLc], videoValue);
        
        [self setInteger:signalValue forKey:@"signaling_preference"];
        [self setInteger:audioValue forKey:@"audio_preference"];
        [self setInteger:videoValue forKey:@"video_preference"];
        [self setBool:YES forKey:@"QoS"];
    } else {
        // Turned Off
        linphone_core_set_sip_dscp([LinphoneManager getLc], 0);
        linphone_core_set_audio_dscp([LinphoneManager getLc], 0);
        linphone_core_set_video_dscp([LinphoneManager getLc], 0);
        [self setInteger:0 forKey:@"signaling_preference"];
        [self setInteger:0 forKey:@"audio_preference"];
        [self setInteger:0 forKey:@"video_preference"];
        [self setBool:NO forKey:@"QoS"];
    }
}

- (void)set508ForceInitialValue {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"force508"]) {
        // First time
        [self setBool:YES forKey:@"force_508_preference"];
    } else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"force508"] integerValue] == 1) {
        [self setBool:YES forKey:@"force_508_preference"];
    } else {
        [self setBool:NO forKey:@"force_508_preference"];
    }
}

- (void)synchronizeAccount {
	LinphoneManager *lm = [LinphoneManager instance];
	LinphoneCore *lc = [LinphoneManager getLc];
	LinphoneProxyConfig *proxyCfg = NULL;
	BOOL isEditing = FALSE;
	NSString *error = nil;

	int port_preference = [self integerForKey:@"port_preference"];

	BOOL random_port_preference = [self boolForKey:@"random_port_preference"];
	[lm lpConfigSetInt:random_port_preference forKey:@"random_port_preference"];
	if (random_port_preference) {
		port_preference = -1;
	}

	LCSipTransports transportValue = {port_preference, port_preference, -1, -1};

	// will also update the sip_*_port section of the config
	if (linphone_core_set_sip_transports(lc, &transportValue)) {
		LOGE(@"cannot set transport");
	}

	port_preference = linphone_core_get_sip_port(lc);
	[self setInteger:port_preference forKey:@"port_preference"]; // Update back preference

	BOOL enable_ipv6 = [self boolForKey:@"use_ipv6"];
	[lm lpConfigSetBool:enable_ipv6 forKey:@"use_ipv6" forSection:@"sip"];
	if (linphone_core_ipv6_enabled(lc) != enable_ipv6) {
		LOGD(@"%@ IPV6", enable_ipv6 ? @"ENABLING" : @"DISABLING");
		linphone_core_enable_ipv6(lc, enable_ipv6);
	}

	// configure sip account

	// mandatory parameters
	NSString *username = [self stringForKey:@"username_preference"];
	NSString *userID = [self stringForKey:@"userid_preference"];
	NSString *domain = [self stringForKey:@"domain_preference"];
	NSString *transport = [self stringForKey:@"transport_preference"];
	NSString *accountHa1 = [self stringForKey:@"ha1_preference"];
	NSString *accountPassword = [self stringForKey:@"password_preference"];
	bool isOutboundProxy = [self boolForKey:@"outbound_proxy_preference"];

	if (username && [username length] > 0 && domain && [domain length] > 0) {
		int expire = [self integerForKey:@"expire_preference"];
		BOOL isWifiOnly = [self boolForKey:@"wifi_only_preference"];
		BOOL pushnotification = [self boolForKey:@"pushnotification_preference"];
		NSString *prefix = [self stringForKey:@"prefix_preference"];
		NSString *proxyAddress = [self stringForKey:@"proxy_preference"];

		LinphoneAuthInfo *info = NULL;
		const char *route = NULL;

		if (isWifiOnly && [LinphoneManager instance].connectivity == wwan)
			expire = 0;

		if ((!proxyAddress || [proxyAddress length] < 1) && domain) {
			proxyAddress = domain;
		}

		if (![proxyAddress hasPrefix:@"sip:"] && ![proxyAddress hasPrefix:@"sips:"]) {
			proxyAddress = [NSString stringWithFormat:@"sip:%@", proxyAddress];
		}

		char *proxy = ms_strdup(proxyAddress.UTF8String);
		LinphoneAddress *proxy_addr = linphone_address_new(proxy);

		if (proxy_addr) {
			LinphoneTransportType type = LinphoneTransportTcp;
			if ([transport isEqualToString:@"tls"])
				type = LinphoneTransportTls;

			linphone_address_set_transport(proxy_addr, type);
			ms_free(proxy);
			proxy = linphone_address_as_string_uri_only(proxy_addr);
		}

		// possible valid config detected, try to modify current proxy or create new one if none existing
		linphone_core_get_default_proxy(lc, &proxyCfg);
		if (proxyCfg == NULL) {
			proxyCfg = linphone_core_create_proxy_config(lc);
		} else {
			isEditing = TRUE;
			linphone_proxy_config_edit(proxyCfg);
		}

		char normalizedUserName[256];
		LinphoneAddress *linphoneAddress = linphone_address_new("sip:user@domain.com");
		linphone_proxy_config_normalize_number(proxyCfg, username.UTF8String, normalizedUserName,
											   sizeof(normalizedUserName));
		linphone_address_set_username(linphoneAddress, normalizedUserName);
		linphone_address_set_domain(linphoneAddress, [domain UTF8String]);

		const char *identity = linphone_address_as_string_uri_only(linphoneAddress);
		const char *password = [accountPassword UTF8String];
		const char *ha1 = [accountHa1 UTF8String];
    
		if (linphone_proxy_config_set_identity(proxyCfg, identity) == -1) {
			error = NSLocalizedString(@"Invalid username or domain", nil);
			goto bad_proxy;
		}
		// use proxy as route if outbound_proxy is enabled
		route = isOutboundProxy ? proxy : NULL;
		if (linphone_proxy_config_set_server_addr(proxyCfg, proxy) == -1) {
			error = NSLocalizedString(@"Invalid proxy address", nil);
			goto bad_proxy;
		}
		if (linphone_proxy_config_set_route(proxyCfg, route) == -1) {
			error = NSLocalizedString(@"Invalid route", nil);
			goto bad_proxy;
		}

		if ([prefix length] > 0) {
			linphone_proxy_config_set_dial_prefix(proxyCfg, [prefix UTF8String]);
		}

		if ([self objectForKey:@"substitute_+_by_00_preference"]) {
			bool substitute_plus_by_00 = [self boolForKey:@"substitute_+_by_00_preference"];
			linphone_proxy_config_set_dial_escape_plus(proxyCfg, substitute_plus_by_00);
		}

		[lm lpConfigSetInt:pushnotification forKey:@"pushnotification_preference"];
		[[LinphoneManager instance] configurePushTokenForProxyConfig:proxyCfg];

		linphone_proxy_config_enable_register(proxyCfg, true);
        
		linphone_proxy_config_set_expires(proxyCfg, expire);

		// setup auth info
		if (linphone_core_get_auth_info_list(lc)) {
			info = linphone_auth_info_clone(linphone_core_get_auth_info_list(lc)->data);
			linphone_auth_info_set_username(info, username.UTF8String);
			if (password) {
				linphone_auth_info_set_passwd(info, password);
				linphone_auth_info_set_ha1(info, NULL);
			}
			linphone_auth_info_set_domain(info, linphone_proxy_config_get_domain(proxyCfg));
		} else {
			LinphoneAddress *from = linphone_address_new(identity);
			if (from) {
				const char *userid_str = (userID != nil) ? [userID UTF8String] : NULL;
				info = linphone_auth_info_new(
					linphone_address_get_username(from), userid_str, password ? password : NULL, password ? NULL : ha1,
					linphone_proxy_config_get_realm(proxyCfg), linphone_proxy_config_get_domain(proxyCfg));
				linphone_address_destroy(from);
			}
		}

		// We reached here without hitting the goto: the new settings are correct, so replace the previous ones.

		// setup new proxycfg
		if (isEditing) {
			linphone_proxy_config_done(proxyCfg);
		} else {
			// was a new proxy config, add it
			linphone_core_add_proxy_config(lc, proxyCfg);
			linphone_core_set_default_proxy_config(lc, proxyCfg);
		}

		// add auth info only after finishing editting the proxy config, so that
		// UNREGISTER succeed
		linphone_core_clear_all_auth_info(lc);
		if (info) {
			linphone_core_add_auth_info(lc, info);
		}

	bad_proxy:
		if (linphoneAddress)
			linphone_address_destroy(linphoneAddress);
		if (proxy)
			ms_free(proxy);
		if (info)
			linphone_auth_info_destroy(info);

		// in case of error, show an alert to the user
		if (error != nil) {
			if (isEditing)
				linphone_proxy_config_done(proxyCfg);
			else
				linphone_proxy_config_destroy(proxyCfg);

			[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
										message:error
									   delegate:nil
							  cancelButtonTitle:NSLocalizedString(@"OK", nil)
							  otherButtonTitles:nil] show];
		}
	}
	// reload address book to prepend proxy config domain to contacts' phone number
	[[[LinphoneManager instance] fastAddressBook] reload];
}

- (void)synchronizeCodecs:(const MSList *)codecs {
	LinphoneCore *lc = [LinphoneManager getLc];
	PayloadType *pt;
	const MSList *elem;

	for (elem = codecs; elem != NULL; elem = elem->next) {
		pt = (PayloadType *)elem->data;
		NSString *pref = [SDPNegotiationService getPreferenceForCodec:pt->mime_type withRate:pt->clock_rate];
        if(pref){
            linphone_core_enable_payload_type(lc, pt, [self boolForKey:pref]);
        }
	}
}

- (BOOL)synchronize {
	LinphoneManager *lm = [LinphoneManager instance];
	LinphoneCore *lc = [LinphoneManager getLc];
	// root section
	{
		BOOL account_changed =
			[self valueChangedForKey:@"username_preference"] || [self valueChangedForKey:@"password_preference"] ||
			[self valueChangedForKey:@"domain_preference"] || [self valueChangedForKey:@"expire_preference"] ||
			[self valueChangedForKey:@"proxy_preference"] || [self valueChangedForKey:@"outbound_proxy_preference"] ||
			[self valueChangedForKey:@"transport_preference"] || [self valueChangedForKey:@"port_preference"] ||
			[self valueChangedForKey:@"random_port_preference"] || [self valueChangedForKey:@"prefix_preference"] ||
			[self valueChangedForKey:@"substitute_+_by_00_preference"] || [self valueChangedForKey:@"use_ipv6"] ||
			[self valueChangedForKey:@"avpf_preference"] || [self valueChangedForKey:@"pushnotification_preference"];
		if (account_changed)
			[self synchronizeAccount];

		bool enableVideo = [self boolForKey:@"enable_video_preference"];
		linphone_core_enable_video(lc, enableVideo, enableVideo);

		bool enableAutoAnswer = [self boolForKey:@"enable_auto_answer_preference"];
		[LinphoneManager.instance lpConfigSetBool:enableAutoAnswer forKey:@"auto_answer"];
	}

	// audio section
	{
		[self synchronizeCodecs:linphone_core_get_audio_codecs(lc)];

		float playback_gain = [self floatForKey:@"playback_gain_preference"];
		linphone_core_set_playback_gain_db(lc, playback_gain);

		float mic_gain = [self floatForKey:@"microphone_gain_preference"];
		linphone_core_set_mic_gain_db(lc, mic_gain);

		[lm lpConfigSetInt:[self integerForKey:@"audio_codec_bitrate_limit_preference"]
					forKey:@"codec_bitrate_limit"
				forSection:@"audio"];

		BOOL voice_processing = [self boolForKey:@"voiceproc_preference"];
		[lm lpConfigSetInt:voice_processing forKey:@"voiceproc_preference"];

		BOOL equalizer = [self boolForKey:@"eq_active"];
		[lm lpConfigSetBool:equalizer forKey:@"eq_active" forSection:@"sound"];

		[[LinphoneManager instance] configureVbrCodecs];

		NSString *au_device = @"AU: Audio Unit Receiver";
		if (!voice_processing) {
			au_device = @"AU: Audio Unit NoVoiceProc";
		}
		linphone_core_set_capture_device(lc, [au_device UTF8String]);
		linphone_core_set_playback_device(lc, [au_device UTF8String]);
	}

	// video section
	{
		[self synchronizeCodecs:linphone_core_get_video_codecs(lc)];

		LinphoneVideoPolicy policy;
		policy.automatically_initiate = [self boolForKey:@"start_video_preference"];
		policy.automatically_accept = [self boolForKey:@"accept_video_preference"];
		linphone_core_set_video_policy(lc, &policy);
		linphone_core_enable_self_view(lc, [self boolForKey:@"self_video_preference"]);
		BOOL preview_preference = [self boolForKey:@"preview_preference"];
		[lm lpConfigSetInt:preview_preference forKey:@"preview_preference"];

		NSString *videoPreset = [self stringForKey:@"video_preset_preference"];
        if(!videoPreset){
            videoPreset = @"high-fps";
        }
		linphone_core_set_video_preset(lc, [videoPreset UTF8String]);
		MSVideoSize vsize;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        //[self setObject:[defaults objectForKey:@"video_preferred_size_preference"] forKey:@"video_preferred_size_preference"];
        if([[defaults objectForKey:@"video_preferred_size_preference"] isEqualToString:@"vga"]){
            MS_VIDEO_SIZE_ASSIGN(vsize, VGA);
        }
        if([[defaults objectForKey:@"video_preferred_size_preference"] isEqualToString:@"cif"]){
            MS_VIDEO_SIZE_ASSIGN(vsize, CIF);
        }
        if([[defaults objectForKey:@"video_preferred_size_preference"] isEqualToString:@"qvga"]){
            MS_VIDEO_SIZE_ASSIGN(vsize, QVGA);
        }
		linphone_core_set_preferred_video_size(lc, vsize);
		if (![videoPreset isEqualToString:@"custom"]) {
			[self setInteger:30 forKey:@"video_preferred_fps_preference"];
		}
		linphone_core_set_preferred_framerate(lc, [self integerForKey:@"video_preferred_fps_preference"]);
		linphone_core_set_download_bandwidth(lc, [self integerForKey:@"download_bandwidth_preference"]);
		linphone_core_set_upload_bandwidth(lc, [self integerForKey:@"download_bandwidth_preference"]);
        
        [self setRtcpFbMode: FALSE];
	}

	// call section
	{
		linphone_core_set_use_rfc2833_for_dtmf(lc, [self boolForKey:@"rfc_dtmf_preference"]);
		linphone_core_set_use_info_for_dtmf(lc, [self boolForKey:@"sipinfo_dtmf_preference"]);
		linphone_core_set_inc_timeout(lc, [self integerForKey:@"incoming_call_timeout_preference"]);
		linphone_core_set_in_call_timeout(lc, [self integerForKey:@"in_call_timeout_preference"]);
		[lm lpConfigSetString:[self stringForKey:@"voice_mail_uri_preference"] forKey:@"voice_mail_uri"];
		[lm lpConfigSetBool:[self boolForKey:@"repeat_call_notification_preference"]
					 forKey:@"repeat_call_notification"];
	}

	// network section
	{
		BOOL edgeOpt = [self boolForKey:@"edge_opt_preference"];
		[lm lpConfigSetInt:edgeOpt forKey:@"edge_opt_preference"];

		BOOL wifiOnly = [self boolForKey:@"wifi_only_preference"];
		[lm lpConfigSetInt:wifiOnly forKey:@"wifi_only_preference"];
		if ([self valueChangedForKey:@"wifi_only_preference"]) {
			[[LinphoneManager instance] setupNetworkReachabilityCallback];
		}

		NSString *stun_server = [self stringForKey:@"stun_preference"];
		if ([stun_server length] > 0) {
			linphone_core_set_stun_server(lc, [stun_server UTF8String]);
			BOOL ice_preference = [self boolForKey:@"ice_preference"];
			if (ice_preference) {
				linphone_core_set_firewall_policy(lc, LinphonePolicyUseIce);
			} else {
				linphone_core_set_firewall_policy(lc, LinphonePolicyUseStun);
			}
		} else {
			linphone_core_set_stun_server(lc, NULL);
			linphone_core_set_firewall_policy(lc, LinphonePolicyNoFirewall);
		}

		{
			NSString *audio_port_preference = [self stringForKey:@"audio_port_preference"];
			int minPort, maxPort;
			[LinphoneCoreSettingsStore parsePortRange:audio_port_preference minPort:&minPort maxPort:&maxPort];
			linphone_core_set_audio_port_range(lc, minPort, maxPort);
		}
		{
			NSString *video_port_preference = [self stringForKey:@"video_port_preference"];
			int minPort, maxPort;
			[LinphoneCoreSettingsStore parsePortRange:video_port_preference minPort:&minPort maxPort:&maxPort];
			linphone_core_set_video_port_range(lc, minPort, maxPort);
		}

		NSString *menc = [self stringForKey:@"media_encryption_preference"];
		if (menc && [menc compare:@"SRTP"] == NSOrderedSame)
			linphone_core_set_media_encryption(lc, LinphoneMediaEncryptionSRTP);
		else if (menc && [menc compare:@"ZRTP"] == NSOrderedSame)
			linphone_core_set_media_encryption(lc, LinphoneMediaEncryptionZRTP);
		else if (menc && [menc compare:@"DTLS"] == NSOrderedSame)
			linphone_core_set_media_encryption(lc, LinphoneMediaEncryptionDTLS);
		else
			linphone_core_set_media_encryption(lc, LinphoneMediaEncryptionNone);

		linphone_core_enable_adaptive_rate_control(lc, [self boolForKey:@"adaptive_rate_control_preference"]);
	}

	// tunnel section
	{
		if (linphone_core_tunnel_available()) {
			NSString *lTunnelPrefMode = [self stringForKey:@"tunnel_mode_preference"];
			NSString *lTunnelPrefAddress = [self stringForKey:@"tunnel_address_preference"];
			int lTunnelPrefPort = [self integerForKey:@"tunnel_port_preference"];
			LinphoneTunnel *tunnel = linphone_core_get_tunnel([LinphoneManager getLc]);
			TunnelMode mode = tunnel_off;
			int lTunnelPort = 443;
			if (lTunnelPrefPort) {
				lTunnelPort = lTunnelPrefPort;
			}

			linphone_tunnel_clean_servers(tunnel);
			if (lTunnelPrefAddress && [lTunnelPrefAddress length]) {
				LinphoneTunnelConfig *ltc = linphone_tunnel_config_new();
				linphone_tunnel_config_set_host(ltc, [lTunnelPrefAddress UTF8String]);
				linphone_tunnel_config_set_port(ltc, lTunnelPort);
				linphone_tunnel_add_server(tunnel, ltc);

				if ([lTunnelPrefMode isEqualToString:@"off"]) {
					mode = tunnel_off;
				} else if ([lTunnelPrefMode isEqualToString:@"on"]) {
					mode = tunnel_on;
				} else if ([lTunnelPrefMode isEqualToString:@"wwan"]) {
					mode = tunnel_wwan;
				} else if ([lTunnelPrefMode isEqualToString:@"auto"]) {
					mode = tunnel_auto;
				} else {
					LOGE(@"Unexpected tunnel mode [%s]", [lTunnelPrefMode UTF8String]);
				}
			}

			[lm lpConfigSetString:lTunnelPrefMode forKey:@"tunnel_mode_preference"];
			[[LinphoneManager instance] setTunnelMode:mode];
		}
	}

	// advanced section
	{
		BOOL debugmode = [self boolForKey:@"debugenable_preference"];
		[lm lpConfigSetInt:debugmode forKey:@"debugenable_preference"];
		[[LinphoneManager instance] setLogsEnabled:debugmode];

		BOOL animations = [self boolForKey:@"animations_preference"];
		[lm lpConfigSetInt:animations forKey:@"animations_preference"];

		UIDevice *device = [UIDevice currentDevice];
		bool backgroundSupported =
			[device respondsToSelector:@selector(isMultitaskingSupported)] && [device isMultitaskingSupported];
		BOOL isbackgroundModeEnabled = backgroundSupported && [self boolForKey:@"backgroundmode_preference"];
		[lm lpConfigSetInt:isbackgroundModeEnabled forKey:@"backgroundmode_preference"];

		[lm lpConfigSetInt:[self integerForKey:@"start_at_boot_preference"] forKey:@"start_at_boot_preference"];
		[lm lpConfigSetInt:[self integerForKey:@"autoanswer_notif_preference"] forKey:@"autoanswer_notif_preference"];
        [lm lpConfigSetInt:[self integerForKey:@"QoS"] forKey:@"QoS"];

		BOOL firstloginview = [self boolForKey:@"enable_first_login_view_preference"];
		[lm lpConfigSetInt:firstloginview forKey:@"enable_first_login_view_preference"];

		NSString *displayname = [self stringForKey:@"primary_displayname_preference"];
		NSString *username = [self stringForKey:@"primary_username_preference"];
		LinphoneAddress *parsed = linphone_core_get_primary_contact_parsed(lc);
		if (parsed != NULL) {
			linphone_address_set_display_name(parsed, [displayname UTF8String]);
			linphone_address_set_username(parsed, [username UTF8String]);
			char *contact = linphone_address_as_string(parsed);
			linphone_core_set_primary_contact(lc, contact);
			ms_free(contact);
			linphone_address_destroy(parsed);
		}

		[lm lpConfigSetInt:[self integerForKey:@"advanced_account_preference"] forKey:@"advanced_account_preference"];

		linphone_core_set_file_transfer_server(lc,
											   [[self stringForKey:@"file_transfer_server_url_preference"] UTF8String]);
	}

	changedDict = [[NSMutableDictionary alloc] init];

	// Post event
	NSDictionary *eventDic = [NSDictionary dictionaryWithObject:self forKey:@"settings"];
	[[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneSettingsUpdate object:self userInfo:eventDic];

	return YES;
}

@end
