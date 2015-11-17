#import "SDPNegotiationService.h"

@implementation SDPNegotiationService


struct codec_name_pref_table{
    const char *name;
    int rate;
    const char *prefname;
};

struct codec_name_pref_table codec_pref_table[]={
    { "speex", 8000, "speex_8k_preference" },
    { "speex", 16000, "speex_16k_preference" },
    { "silk", 24000, "silk_24k_preference" },
    { "silk", 16000, "silk_16k_preference" },
    { "amr", 8000, "amr_preference" },
    { "gsm", 8000, "gsm_preference" },
    { "ilbc", 8000, "ilbc_preference"},
    { "pcmu", 8000, "pcmu_preference"},
    { "pcma", 8000, "pcma_preference"},
    { "g722", 8000, "g722_preference"},
    { "g729", 8000, "g729_preference"},
    { "mp4v-es", 90000, "mp4v-es_preference"},
    { "h264", 90000, "h264_preference"},
    { "h263", 90000, "h263_preference"},
    { "vp8", 90000, "vp8_preference"},
    { "mpeg4-generic", 16000, "aaceld_16k_preference"},
    { "mpeg4-generic", 22050, "aaceld_22k_preference"},
    { "mpeg4-generic", 32000, "aaceld_32k_preference"},
    { "mpeg4-generic", 44100, "aaceld_44k_preference"},
    { "mpeg4-generic", 48000, "aaceld_48k_preference"},
    { "opus", 48000, "opus_preference"},
    { NULL,0,Nil }
};

+ (SDPNegotiationService *)sharedInstance
{
    static SDPNegotiationService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SDPNegotiationService alloc] init];
    });
    
    return sharedInstance;
}

+ (NSString *)getPreferenceForCodec: (const char*) name withRate: (int) rate{
    int i;
    for(i=0;codec_pref_table[i].name!=NULL;++i){
        if (strcasecmp(codec_pref_table[i].name,name)==0 && codec_pref_table[i].rate==rate)
            return [NSString stringWithUTF8String:codec_pref_table[i].prefname];
    }
    return Nil;
}

+ (NSSet *)unsupportedCodecs {
    NSMutableSet *set = [NSMutableSet set];
    for(int i=0;codec_pref_table[i].name!=NULL;++i) {
        PayloadType* available = linphone_core_find_payload_type([LinphoneManager getLc],
                                                                 codec_pref_table[i].name,
                                                                 codec_pref_table[i].rate,
                                                                 LINPHONE_FIND_PAYLOAD_IGNORE_CHANNELS);
        if( (available == NULL)
           // these two codecs should not be hidden, even if not supported
           && strcmp(codec_pref_table[i].prefname, "h264_preference") != 0
           )
        {
            [set addObject:[NSString stringWithUTF8String:codec_pref_table[i].prefname]];
        }
    }
    return set;
}
+ (NSSet *)supportedCodecs {
    NSMutableSet *set = [NSMutableSet set];
    for(int i=0;codec_pref_table[i].name!=NULL;++i) {
        PayloadType* available = linphone_core_find_payload_type([LinphoneManager getLc],
                                                                 codec_pref_table[i].name,
                                                                 codec_pref_table[i].rate,
                                                                 LINPHONE_FIND_PAYLOAD_IGNORE_CHANNELS);
        if((available != NULL))
        {
            [set addObject:[NSString stringWithUTF8String:codec_pref_table[i].prefname]];
        }
    }
    return set;
}

- (id) init {
    self = [super init];
    return self;
}

PayloadType *h264_1;

-(void) initializeSDP: (LinphoneCore*) lc{
        if(linphone_core_video_enabled(lc)){
            PayloadType *pt=linphone_core_find_payload_type(lc,"H264", 90000, -1);
            
            if(pt){
                if(h264_1 == NULL){
                    h264_1 = payload_type_clone(pt);
                }
                payload_type_set_send_fmtp(h264_1, "packetization-mode=1;");
                payload_type_set_recv_fmtp(h264_1, "packetization-mode=1;");
                linphone_core_set_payload_type_number(lc, h264_1, 97);
                
                if(!linphone_core_payload_type_enabled(lc, h264_1)){
                    //linphone_core_create_duplicate_payload_type_with_params(lc, pt, h264_1);
                    NSLog(@"Mode 1 added");
                }
                
                else{
                    NSLog(@"H264 mode 1 enabled");
                }

                
                payload_type_set_send_fmtp(pt, "packetization-mode=0;");
                payload_type_set_recv_fmtp(pt, "packetization-mode=0;");

                linphone_core_enable_payload_type(lc, h264_1, TRUE);
                linphone_core_enable_payload_type(lc, pt, TRUE);
                
            }
            //         ***** KEEP FOR FUTURE AVPF FIXES *******
            
            //        if(pt && linphone_core_get_avpf_mode(lc) == LinphoneAVPFEnabled){
            //            PayloadTypeAvpfParams params;
            //            params.features = PAYLOAD_TYPE_AVPF_FIR | PAYLOAD_TYPE_AVPF_PLI  | PAYLOAD_TYPE_AVPF_RPSI | PAYLOAD_TYPE_AVPF_SLI;
            //            params.rpsi_compatibility = TRUE;
            //            params.trr_interval = 3;
            //            payload_type_set_avpf_params(pt, params);
            //
            //            payload_type_set_recv_fmtp(pt, "CIF=1;QCIF=1");
            //            payload_type_set_send_fmtp(pt, "CIF=1;QCIF=1");
            //
            //            linphone_core_enable_payload_type([LinphoneManager getLc],pt,TRUE);
            //        }
            
            pt=linphone_core_find_payload_type(lc,"H263", 90000, -1);
            if (pt) {
                payload_type_set_recv_fmtp(pt, "CIF=1;QCIF=1");
                payload_type_set_send_fmtp(pt, "CIF=1;QCIF=1");
                linphone_core_enable_payload_type([LinphoneManager getLc],pt,TRUE);
            }
    }
}

@end
