/* Utils.m
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

#import "Utils.h"
#include "linphone/linphonecore.h"
#import <CommonCrypto/CommonDigest.h>
#import <sys/utsname.h>
#import "LinphoneAppDelegate.h"

@implementation LinphoneLogger

+ (void)log:(OrtpLogLevel)severity file:(const char *)file line:(int)line format:(NSString *)format, ... {
	va_list args;
	va_start(args, format);
	NSString *str = [[NSString alloc] initWithFormat:format arguments:args];
	const char *utf8str = [str cStringUsingEncoding:NSString.defaultCStringEncoding];
	int filesize = 20;
	const char *filename = strchr(file, '/') ? strrchr(file, '/') + 1 : file;
	if (severity <= ORTP_DEBUG) {
		// lol: ortp_debug(XXX) can be disabled at compile time, but ortp_log(ORTP_DEBUG, xxx) will always be valid even
		//      not in debug build...
		ortp_debug("%*s:%3d - %s", filesize, filename + MAX((int)strlen(filename) - filesize, 0), line, utf8str);
	} else {
		ortp_log(severity, "%*s:%3d - %s", filesize, filename + MAX((int)strlen(filename) - filesize, 0), line,
				 utf8str);
	}
	va_end(args);
}

#pragma mark - Logs Functions callbacks

void linphone_iphone_log_handler(const char *domain, OrtpLogLevel lev, const char *fmt, va_list args) {
	NSString *format = [[NSString alloc] initWithUTF8String:fmt];
	NSString *formatedString = [[NSString alloc] initWithFormat:format arguments:args];
	char levelC = 'I';
    switch ((OrtpLogLevel)lev) {
        case ORTP_FATAL:
            levelC = 'F';
            break;
        case ORTP_ERROR:
            levelC = 'E';
            break;
        case ORTP_WARNING:
            levelC = 'W';
            break;
        case ORTP_MESSAGE:
            levelC = 'I';
            break;
        case ORTP_TRACE:
        case ORTP_DEBUG:
            levelC = 'D';
            break;
        case ORTP_LOGLEV_END:
            return;
    }
	// since \r are interpreted like \n, avoid double new lines when logging packets
    NSLog(@"%c %@, %@ Core %s", levelC, [formatedString stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
          linphone_core_get_version());
    
    NSString *line = [[[[[[[NSString stringWithFormat:@"%c", levelC] stringByAppendingString:@"-"] stringByAppendingString:[formatedString stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"]] stringByAppendingString:@"-"] stringByAppendingString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]] stringByAppendingString:@" - "] stringByAppendingString:[NSString stringWithUTF8String:linphone_core_get_version()]];
    
    NSString *enterLine = [line stringByAppendingString:@"\n"];
    
    @try {
         [[(LinphoneAppDelegate *)[UIApplication sharedApplication].delegate logFileArray] addObject:enterLine];
        
        if ([(LinphoneAppDelegate *)[UIApplication sharedApplication].delegate logFileArray].count > 1000 ) {
            int last1000ElementsIndex = (int)([(LinphoneAppDelegate *)[UIApplication sharedApplication].delegate logFileArray].count - 1000);
            NSMutableArray * last1000ElementsOfLogArray = [[[(LinphoneAppDelegate *)[UIApplication sharedApplication].delegate logFileArray] subarrayWithRange:NSMakeRange(last1000ElementsIndex, 1000)] mutableCopy];
            [(LinphoneAppDelegate *)[UIApplication sharedApplication].delegate setLogArray:last1000ElementsOfLogArray];
        }
    }
    @catch (NSException *exception) { }
}

@end

@implementation LinphoneUtils

+ (BOOL)findAndResignFirstResponder:(UIView *)view {
	if (view.isFirstResponder) {
		[view resignFirstResponder];
		return YES;
	}
	for (UIView *subView in view.subviews) {
		if ([LinphoneUtils findAndResignFirstResponder:subView])
			return YES;
	}
	return NO;
}

+ (void)adjustFontSize:(UIView *)view mult:(float)mult {
	if ([view isKindOfClass:[UILabel class]]) {
		UILabel *label = (UILabel *)view;
		UIFont *font = [label font];
		[label setFont:[UIFont fontWithName:font.fontName size:font.pointSize * mult]];
	} else if ([view isKindOfClass:[UITextField class]]) {
		UITextField *label = (UITextField *)view;
		UIFont *font = [label font];
		[label setFont:[UIFont fontWithName:font.fontName size:font.pointSize * mult]];
	} else if ([view isKindOfClass:[UIButton class]]) {
		UIButton *button = (UIButton *)view;
		UIFont *font = button.titleLabel.font;
		[button.titleLabel setFont:[UIFont fontWithName:font.fontName size:font.pointSize * mult]];
	} else {
		for (UIView *subView in [view subviews]) {
			[LinphoneUtils adjustFontSize:subView mult:mult];
		}
	}
}

+ (void)buttonFixStates:(UIButton *)button {
	// Set selected+over title: IB lack !
	[button setTitle:[button titleForState:UIControlStateSelected]
			forState:(UIControlStateHighlighted | UIControlStateSelected)];

	// Set selected+over titleColor: IB lack !
	[button setTitleColor:[button titleColorForState:UIControlStateHighlighted]
				 forState:(UIControlStateHighlighted | UIControlStateSelected)];

	// Set selected+disabled title: IB lack !
	[button setTitle:[button titleForState:UIControlStateSelected]
			forState:(UIControlStateDisabled | UIControlStateSelected)];

	// Set selected+disabled titleColor: IB lack !
	[button setTitleColor:[button titleColorForState:UIControlStateDisabled]
				 forState:(UIControlStateDisabled | UIControlStateSelected)];
}

+ (void)buttonFixStatesForTabs:(UIButton *)button {
	// Set selected+over title: IB lack !
	[button setTitle:[button titleForState:UIControlStateSelected]
			forState:(UIControlStateHighlighted | UIControlStateSelected)];

	// Set selected+over titleColor: IB lack !
	[button setTitleColor:[button titleColorForState:UIControlStateSelected]
				 forState:(UIControlStateHighlighted | UIControlStateSelected)];

	// Set selected+disabled title: IB lack !
	[button setTitle:[button titleForState:UIControlStateSelected]
			forState:(UIControlStateDisabled | UIControlStateSelected)];

	// Set selected+disabled titleColor: IB lack !
	[button setTitleColor:[button titleColorForState:UIControlStateDisabled]
				 forState:(UIControlStateDisabled | UIControlStateSelected)];
}

+ (void)buttonMultiViewAddAttributes:(NSMutableDictionary *)attributes button:(UIButton *)button {
	[LinphoneUtils addDictEntry:attributes item:[button titleForState:UIControlStateNormal] key:@"title-normal"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button titleForState:UIControlStateHighlighted]
							key:@"title-highlighted"];
	[LinphoneUtils addDictEntry:attributes item:[button titleForState:UIControlStateDisabled] key:@"title-disabled"];
	[LinphoneUtils addDictEntry:attributes item:[button titleForState:UIControlStateSelected] key:@"title-selected"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button titleForState:UIControlStateDisabled | UIControlStateHighlighted]
							key:@"title-disabled-highlighted"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button titleForState:UIControlStateSelected | UIControlStateHighlighted]
							key:@"title-selected-highlighted"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button titleForState:UIControlStateSelected | UIControlStateDisabled]
							key:@"title-selected-disabled"];

	[LinphoneUtils addDictEntry:attributes
						   item:[button titleColorForState:UIControlStateNormal]
							key:@"title-color-normal"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button titleColorForState:UIControlStateHighlighted]
							key:@"title-color-highlighted"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button titleColorForState:UIControlStateDisabled]
							key:@"title-color-disabled"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button titleColorForState:UIControlStateSelected]
							key:@"title-color-selected"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button titleColorForState:UIControlStateDisabled | UIControlStateHighlighted]
							key:@"title-color-disabled-highlighted"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button titleColorForState:UIControlStateSelected | UIControlStateHighlighted]
							key:@"title-color-selected-highlighted"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button titleColorForState:UIControlStateSelected | UIControlStateDisabled]
							key:@"title-color-selected-disabled"];

	[LinphoneUtils addDictEntry:attributes item:NSStringFromUIEdgeInsets([button titleEdgeInsets]) key:@"title-edge"];
	[LinphoneUtils addDictEntry:attributes
						   item:NSStringFromUIEdgeInsets([button contentEdgeInsets])
							key:@"content-edge"];
	[LinphoneUtils addDictEntry:attributes item:NSStringFromUIEdgeInsets([button imageEdgeInsets]) key:@"image-edge"];

	[LinphoneUtils addDictEntry:attributes item:[button imageForState:UIControlStateNormal] key:@"image-normal"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button imageForState:UIControlStateHighlighted]
							key:@"image-highlighted"];
	[LinphoneUtils addDictEntry:attributes item:[button imageForState:UIControlStateDisabled] key:@"image-disabled"];
	[LinphoneUtils addDictEntry:attributes item:[button imageForState:UIControlStateSelected] key:@"image-selected"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button imageForState:UIControlStateDisabled | UIControlStateHighlighted]
							key:@"image-disabled-highlighted"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button imageForState:UIControlStateSelected | UIControlStateHighlighted]
							key:@"image-selected-highlighted"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button imageForState:UIControlStateSelected | UIControlStateDisabled]
							key:@"image-selected-disabled"];

	[LinphoneUtils addDictEntry:attributes
						   item:[button backgroundImageForState:UIControlStateNormal]
							key:@"background-normal"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button backgroundImageForState:UIControlStateHighlighted]
							key:@"background-highlighted"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button backgroundImageForState:UIControlStateDisabled]
							key:@"background-disabled"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button backgroundImageForState:UIControlStateSelected]
							key:@"background-selected"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button backgroundImageForState:UIControlStateDisabled | UIControlStateHighlighted]
							key:@"background-disabled-highlighted"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button backgroundImageForState:UIControlStateSelected | UIControlStateHighlighted]
							key:@"background-selected-highlighted"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button backgroundImageForState:UIControlStateSelected | UIControlStateDisabled]
							key:@"background-selected-disabled"];
}

+ (void)buttonMultiViewApplyAttributes:(NSDictionary *)attributes button:(UIButton *)button {
	[button setTitle:[LinphoneUtils getDictEntry:attributes key:@"title-normal"] forState:UIControlStateNormal];
	[button setTitle:[LinphoneUtils getDictEntry:attributes key:@"title-highlighted"]
			forState:UIControlStateHighlighted];
	[button setTitle:[LinphoneUtils getDictEntry:attributes key:@"title-disabled"] forState:UIControlStateDisabled];
	[button setTitle:[LinphoneUtils getDictEntry:attributes key:@"title-selected"] forState:UIControlStateSelected];
	[button setTitle:[LinphoneUtils getDictEntry:attributes key:@"title-disabled-highlighted"]
			forState:UIControlStateDisabled | UIControlStateHighlighted];
	[button setTitle:[LinphoneUtils getDictEntry:attributes key:@"title-selected-highlighted"]
			forState:UIControlStateSelected | UIControlStateHighlighted];
	[button setTitle:[LinphoneUtils getDictEntry:attributes key:@"title-selected-disabled"]
			forState:UIControlStateSelected | UIControlStateDisabled];

	[button setTitleColor:[LinphoneUtils getDictEntry:attributes key:@"title-color-normal"]
				 forState:UIControlStateNormal];
	[button setTitleColor:[LinphoneUtils getDictEntry:attributes key:@"title-color-highlighted"]
				 forState:UIControlStateHighlighted];
	[button setTitleColor:[LinphoneUtils getDictEntry:attributes key:@"title-color-disabled"]
				 forState:UIControlStateDisabled];
	[button setTitleColor:[LinphoneUtils getDictEntry:attributes key:@"title-color-selected"]
				 forState:UIControlStateSelected];
	[button setTitleColor:[LinphoneUtils getDictEntry:attributes key:@"title-color-disabled-highlighted"]
				 forState:UIControlStateDisabled | UIControlStateHighlighted];
	[button setTitleColor:[LinphoneUtils getDictEntry:attributes key:@"title-color-selected-highlighted"]
				 forState:UIControlStateSelected | UIControlStateHighlighted];
	[button setTitleColor:[LinphoneUtils getDictEntry:attributes key:@"title-color-selected-disabled"]
				 forState:UIControlStateSelected | UIControlStateDisabled];

	[button setTitleEdgeInsets:UIEdgeInsetsFromString([LinphoneUtils getDictEntry:attributes key:@"title-edge"])];
	[button setContentEdgeInsets:UIEdgeInsetsFromString([LinphoneUtils getDictEntry:attributes key:@"content-edge"])];
	[button setImageEdgeInsets:UIEdgeInsetsFromString([LinphoneUtils getDictEntry:attributes key:@"image-edge"])];

	[button setImage:[LinphoneUtils getDictEntry:attributes key:@"image-normal"] forState:UIControlStateNormal];
	[button setImage:[LinphoneUtils getDictEntry:attributes key:@"image-highlighted"]
			forState:UIControlStateHighlighted];
	[button setImage:[LinphoneUtils getDictEntry:attributes key:@"image-disabled"] forState:UIControlStateDisabled];
	[button setImage:[LinphoneUtils getDictEntry:attributes key:@"image-selected"] forState:UIControlStateSelected];
	[button setImage:[LinphoneUtils getDictEntry:attributes key:@"image-disabled-highlighted"]
			forState:UIControlStateDisabled | UIControlStateHighlighted];
	[button setImage:[LinphoneUtils getDictEntry:attributes key:@"image-selected-highlighted"]
			forState:UIControlStateSelected | UIControlStateHighlighted];
	[button setImage:[LinphoneUtils getDictEntry:attributes key:@"image-selected-disabled"]
			forState:UIControlStateSelected | UIControlStateDisabled];

	[button setBackgroundImage:[LinphoneUtils getDictEntry:attributes key:@"background-normal"]
					  forState:UIControlStateNormal];
	[button setBackgroundImage:[LinphoneUtils getDictEntry:attributes key:@"background-highlighted"]
					  forState:UIControlStateHighlighted];
	[button setBackgroundImage:[LinphoneUtils getDictEntry:attributes key:@"background-disabled"]
					  forState:UIControlStateDisabled];
	[button setBackgroundImage:[LinphoneUtils getDictEntry:attributes key:@"background-selected"]
					  forState:UIControlStateSelected];
	[button setBackgroundImage:[LinphoneUtils getDictEntry:attributes key:@"background-disabled-highlighted"]
					  forState:UIControlStateDisabled | UIControlStateHighlighted];
	[button setBackgroundImage:[LinphoneUtils getDictEntry:attributes key:@"background-selected-highlighted"]
					  forState:UIControlStateSelected | UIControlStateHighlighted];
	[button setBackgroundImage:[LinphoneUtils getDictEntry:attributes key:@"background-selected-disabled"]
					  forState:UIControlStateSelected | UIControlStateDisabled];
}

+ (void)addDictEntry:(NSMutableDictionary *)dict item:(id)item key:(id)key {
	if (item != nil && key != nil) {
		[dict setObject:item forKey:key];
	}
}

+ (id)getDictEntry:(NSDictionary *)dict key:(id)key {
	if (key != nil) {
		return [dict objectForKey:key];
	}
	return nil;
}

+ (NSString *)deviceName {
	struct utsname systemInfo;
	uname(&systemInfo);

	return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

+ (NSString*)phoneNumberFromURI:(NSString*)sipURI {

    NSString *sipWordString = nil;
    NSString *remainParthString = nil;
    NSArray *numbersAndDomain = [NSArray new];
    
    if (sipURI.length > 4) {
        sipWordString = [sipURI substringToIndex:4];
        if ([sipWordString isEqualToString:@"sip:"]) {
            remainParthString = [sipURI substringFromIndex:4];
            numbersAndDomain = [remainParthString componentsSeparatedByString:@"@"];
            if (numbersAndDomain.count > 1) {
                return [numbersAndDomain firstObject];
            }
        } else {
            numbersAndDomain = [sipURI componentsSeparatedByString:@"@"];
            
            return [numbersAndDomain firstObject];
        }
    }
    
    return sipURI;
}

+ (BOOL)isInternationalPhoneNumber:(NSString*)phoneNumber {
    
    NSString *internationalPhoneNumber = nil;
    NSString *firstTwoNumbers = nil;
    NSString *remainParthNumbers = nil;
    if (phoneNumber.length > 2) {
        firstTwoNumbers = [phoneNumber substringToIndex:2];
        remainParthNumbers = [phoneNumber substringFromIndex:2];
    }
    
    if ([firstTwoNumbers isEqualToString:@"00"]) {
        internationalPhoneNumber = [@"+" stringByAppendingString:remainParthNumbers];
    } else {
        internationalPhoneNumber = phoneNumber;
    }

    NSString *expression = @"^\\+(?:[0-9] ?){6,14}[0-9]$";
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:expression options:NSRegularExpressionCaseInsensitive error:&error];
    NSTextCheckingResult *match = [regex firstMatchInString:internationalPhoneNumber options:0 range:NSMakeRange(0, [internationalPhoneNumber length])];
    if (match) {
        return YES;
    }
    
    return NO;
}
+ (NSDictionary*)normalizeServerDictionary:(NSDictionary*)jsonDictionary
{
    NSMutableDictionary* newDictionary = [[NSMutableDictionary alloc] init];
    for (id key in jsonDictionary)
    {
        //        NSLog(@"key=%@ value=%@", key, [myDict objectForKey:key]);
        NSObject* object = [jsonDictionary objectForKey:key];
        if ([object isKindOfClass:[NSString class]])
        {
            NSString* value = [self normalizeServerString:[[NSMutableString alloc] initWithString:(NSString*)object]];
            [newDictionary setValue:value forKey:key];
        }
        else if ([object isKindOfClass:[NSArray class]])
        {
            [newDictionary setValue:[self normalizeServerArray:(NSArray*)object] forKey:key];
        }
        else if ([object isKindOfClass:[NSDictionary class]])
        {
            [newDictionary setValue:[self normalizeServerDictionary:(NSDictionary*)object] forKey:key];
        }
        else
        {
            [newDictionary setValue:object forKey:key];
        }
    }
    return [newDictionary copy];
}

+ (NSArray*)normalizeServerArray:(NSArray*)arrayOfObjects
{
    NSMutableArray* newArray = [[NSMutableArray alloc] init];
    for (NSObject* object in arrayOfObjects)
    {
        //        NSLog(@"key=%@ value=%@", key, [myDict objectForKey:key]);
        if ([object isKindOfClass:[NSString class]])
        {
            [newArray addObject:[self normalizeServerString:[[NSMutableString alloc] initWithString:(NSString*)object]]];
        }
        else if ([object isKindOfClass:[NSArray class]])
        {
            [newArray addObject:[self normalizeServerArray:(NSArray*)object]];
        }
        else if ([object isKindOfClass:[NSDictionary class]])
        {
            [newArray addObject:[self normalizeServerDictionary:(NSDictionary*)object]];
        }
        else
        {
            [newArray addObject:object];
        }
    }
    return [newArray copy];
    
}

// if null or empty (including single of double quotes only) return empty string.
// if starts and ends with quotes, remove them.
+(NSString*) normalizeServerString:(NSString*)value
{
    if ((value == nil) || ([value length] == 0) || [value isEqualToString:@"\""] || [value isEqualToString:@"\"\""])
    {
        return @"";
    }
    
    NSMutableString* valueOut = [[NSMutableString alloc] initWithString:value];
    if ([value hasPrefix:@"\""])
    {
        valueOut = [[NSMutableString alloc] initWithString:[valueOut substringFromIndex:1]];
    }
    if ([valueOut hasSuffix:@"\""])
    {
        valueOut = [[NSMutableString alloc] initWithString:[valueOut substringToIndex:([valueOut length] - 1)]];
    }
    return valueOut;
}

+ (NSString*)cardDAVRealmName {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"carddav_realm"];
}

+ (NSString*)cardDAVServerPath {
    
    NSString *serverPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"carddav_path"];
    if ([serverPath length] <= 7) {
        return @"";
    } else {
        NSString *withoutHTTP = [serverPath substringFromIndex:7];
        NSArray* separatedStrings = [withoutHTTP componentsSeparatedByString:@"/"];
        NSString *serverName = [separatedStrings objectAtIndex:0];
        return serverName;
    }
    
    return serverPath;
}

@end

@implementation NSNumber (HumanReadableSize)

- (NSString *)toHumanReadableSize {
	float floatSize = [self floatValue];
	if (floatSize < 1023)
		return ([NSString stringWithFormat:@"%1.0f bytes", floatSize]);
	floatSize = floatSize / 1024;
	if (floatSize < 1023)
		return ([NSString stringWithFormat:@"%1.1f KB", floatSize]);
	floatSize = floatSize / 1024;
	if (floatSize < 1023)
		return ([NSString stringWithFormat:@"%1.1f MB", floatSize]);
	floatSize = floatSize / 1024;

	return ([NSString stringWithFormat:@"%1.1f GB", floatSize]);
}

@end

@implementation NSString (md5)

- (NSString *)md5 {
	const char *ptr = [self UTF8String];
	unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
	CC_MD5(ptr, (unsigned int)strlen(ptr), md5Buffer);
	NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
	for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
		[output appendFormat:@"%02x", md5Buffer[i]];
	}

	return output;
}

@end
