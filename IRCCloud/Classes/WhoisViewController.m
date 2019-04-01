//
//  WhoisViewController.m
//
//  Copyright (C) 2013 IRCCloud, Ltd.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "WhoisViewController.h"
#import "ColorFormatter.h"
#import "AppDelegate.h"
#import "UIColor+IRCCloud.h"

@implementation WhoisViewController

-(id)init {
    self = [super init];
    if (self) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
        
        self->_scrollView = [[UIScrollView alloc] init];
        self->_scrollView.backgroundColor = [UIColor contentBackgroundColor];
        self->_label = [[LinkTextView alloc] init];
        self->_label.linkDelegate = self;
        self->_label.editable = NO;
        self->_label.scrollEnabled = NO;
        self->_label.backgroundColor = [UIColor clearColor];
        self->_label.textColor = [UIColor messageTextColor];
        self->_label.textContainerInset = UIEdgeInsetsZero;
        
        [self->_scrollView addSubview:self->_label];
    }
    return self;
}

-(void)setData:(IRCCloudJSONObject *)object {
    self.navigationItem.title = [object objectForKey:@"nick"];

    Server *s = [[ServersDataSource sharedInstance] getServer:[[object objectForKey:@"cid"] intValue]];
    
    NSArray *matches;
    NSMutableArray *links = [[NSMutableArray alloc] init];
    NSMutableAttributedString *data = [[NSMutableAttributedString alloc] init];
    
    NSString *actualHost = @"";
    if([object objectForKey:@"actual_host"])
        actualHost = [NSString stringWithFormat:@"/%@", [object objectForKey:@"actual_host"]];
    [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@%c (%@%c%@%c)", [object objectForKey:@"user_realname"], CLEAR, [object objectForKey:@"user_mask"], CLEAR, actualHost, CLEAR] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
    
    if([[object objectForKey:@"user_logged_in_as"] length]) {
        [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@" is authed as %@", [object objectForKey:@"user_logged_in_as"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
    }
    
    [data appendAttributedString:[ColorFormatter format:@"\n" defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:nil links:nil]];
    
    if([object objectForKey:@"away"]) {
        NSString *away = @"Away";
        if(![[object objectForKey:@"away"] isEqualToString:@"away"])
            away = [away stringByAppendingFormat:@": %@", [object objectForKey:@"away"]];
        
        [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@\n", away] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
    }
    
    if([[object objectForKey:@"signon_time"] intValue]) {
        [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"Online for about %@", [self duration:([[NSDate date] timeIntervalSince1970] - [[object objectForKey:@"signon_time"] doubleValue])]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
        
        if([[object objectForKey:@"idle_secs"] intValue]) {
            [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@" (idle for %@)", [self duration:[[object objectForKey:@"idle_secs"] intValue]]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
        }
        
        [data appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    }
    
    if([[object objectForKey:@"op_nick"] length]) {
        [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ %@\n", [object objectForKey:@"op_nick"], [object objectForKey:@"op_msg"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
    }
    
    if([[object objectForKey:@"opername"] length]) {
        [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ %@\n", [object objectForKey:@"nick"], [object objectForKey:@"opername"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
    }
    
    if([[object objectForKey:@"userip"] length]) {
        [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ %@\n", [object objectForKey:@"nick"], [object objectForKey:@"userip"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
    }
    
    if([[object objectForKey:@"bot_msg"] length]) {
        [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ %@\n", [object objectForKey:@"nick"], [object objectForKey:@"bot_msg"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
    }
    
    if([[object objectForKey:@"server_addr"] length]) {
        [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ is connected via: %@", [object objectForKey:@"nick"], [object objectForKey:@"server_addr"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
    }
    
    if([[object objectForKey:@"server_extra"] length]) {
        [data appendAttributedString:[ColorFormatter format:@" (" defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:nil links:nil]];
        NSUInteger offset = data.length;
        [data appendAttributedString:[ColorFormatter format:[object objectForKey:@"server_extra"] defaultColor:[UIColor messageTextColor] mono:NO linkify:YES server:s links:&matches]];
        [data appendAttributedString:[ColorFormatter format:@")" defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:nil links:nil]];
        for(NSTextCheckingResult *result in matches) {
            NSURL *u;
            if(result.resultType == NSTextCheckingTypeLink) {
                u = result.URL;
            } else {
                NSString *url = [[data attributedSubstringFromRange:NSMakeRange(result.range.location+offset, result.range.length)] string];
                if(![url hasPrefix:@"irc"])
                    url = [[NSString stringWithFormat:@"irc%@://%@:%i/%@", (s.ssl==1)?@"s":@"", s.hostname, s.port, url] stringByReplacingOccurrencesOfString:@"#" withString:@"%23"];
                u = [NSURL URLWithString:url];
                
            }
            [links addObject:[NSTextCheckingResult linkCheckingResultWithRange:NSMakeRange(result.range.location+offset, result.range.length) URL:u]];
        }
    }
    
    [data appendAttributedString:[ColorFormatter format:@"\n" defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:nil links:nil]];
    
    if([[object objectForKey:@"host"] length]) {
        [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ %@\n", [object objectForKey:@"nick"], [object objectForKey:@"host"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
    }
    
    [self addChannels:[object objectForKey:@"channels_oper"] forGroup:@"Oper" attributedString:data links:links server:s];
    [self addChannels:[object objectForKey:@"channels_owner"] forGroup:@"Owner" attributedString:data links:links server:s];
    [self addChannels:[object objectForKey:@"channels_admin"] forGroup:@"Admin" attributedString:data links:links server:s];
    [self addChannels:[object objectForKey:@"channels_op"] forGroup:@"Operator" attributedString:data links:links server:s];
    [self addChannels:[object objectForKey:@"channels_halfop"] forGroup:@"Half-Operator" attributedString:data links:links server:s];
    [self addChannels:[object objectForKey:@"channels_voiced"] forGroup:@"Voiced" attributedString:data links:links server:s];
    [self addChannels:[object objectForKey:@"channels_member"] forGroup:@"Member" attributedString:data links:links server:s];
    
    if([[object objectForKey:@"secure"] length]) {
        [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ %@\n", [object objectForKey:@"nick"], [object objectForKey:@"secure"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
    }
    
    if([[object objectForKey:@"client_cert"] length]) {
        [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ %@\n", [object objectForKey:@"nick"], [object objectForKey:@"client_cert"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
    }
    
    if([[object objectForKey:@"cgi"] length]) {
        [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ %@\n", [object objectForKey:@"nick"], [object objectForKey:@"cgi"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
    }
    
    if([[object objectForKey:@"help"] length]) {
        [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ %@\n", [object objectForKey:@"nick"], [object objectForKey:@"help"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
    }
    
    if([[object objectForKey:@"vworld"] length]) {
        [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ %@\n", [object objectForKey:@"nick"], [object objectForKey:@"vworld"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
    }
    
    if([[object objectForKey:@"modes"] length]) {
        [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ %@\n", [object objectForKey:@"nick"], [object objectForKey:@"modes"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
    }
    
    if([[object objectForKey:@"stats_dline"] length]) {
        [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ %@\n", [object objectForKey:@"nick"], [object objectForKey:@"stats_dline"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
    }
    
    
    self->_label.attributedText = data;
    self->_label.linkAttributes = [UIColor linkAttributes];
    for(NSTextCheckingResult *result in links)
        [self->_label addLinkWithTextCheckingResult:result];
}

-(SupportedOrientationsReturnType)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

-(void)addChannels:(NSArray *)channels forGroup:(NSString *)group attributedString:(NSMutableAttributedString *)data links:(NSMutableArray *)links server:(Server *)s {
    if(channels.count) {
        [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:[group isEqualToString:@"Member"]?@"%@ of:\n":@"%@ in:\n", group] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:nil links:nil]];
        for(NSString *channel in channels) {
            NSUInteger offset = data.length;
            [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@" • %@\n", channel] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
            CFStringRef url_escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)channel, NULL, (CFStringRef)@"&+/?=[]();:^", kCFStringEncodingUTF8);
            if(url_escaped != NULL) {
                [links addObject:[NSTextCheckingResult linkCheckingResultWithRange:NSMakeRange(offset + 3, data.length - offset - 3) URL:[NSURL URLWithString:[NSString stringWithFormat:@"irc://%i/%@", s.cid, url_escaped]]]];
                CFRelease(url_escaped);
            }
        }
    }
}

-(NSString *)duration:(int)seconds {
    int minutes = seconds / 60;
    int hours = minutes / 60;
    int days = hours / 24;
    if(days) {
        if(days == 1)
            return [NSString stringWithFormat:@"%i day", days];
        else
            return [NSString stringWithFormat:@"%i days", days];
    } else if(hours) {
        if(hours == 1)
            return [NSString stringWithFormat:@"%i hour", hours];
        else
            return [NSString stringWithFormat:@"%i hours", hours];
    } else if(minutes) {
        if(minutes == 1)
            return [NSString stringWithFormat:@"%i minute", minutes];
        else
            return [NSString stringWithFormat:@"%i minutes", minutes];
    } else {
        if(seconds == 1)
            return [NSString stringWithFormat:@"%i second", seconds];
        else
            return [NSString stringWithFormat:@"%i seconds", seconds];
    }
}

-(void)loadView {
    [super loadView];
    self.navigationController.navigationBar.clipsToBounds = YES;
    self->_label.frame = CGRectMake(12,2,self.view.bounds.size.width-24, [LinkTextView heightOfString:self->_label.attributedText constrainedToWidth:self.view.bounds.size.width-24]+12);
    self->_scrollView.frame = self.view.frame;
    self->_scrollView.contentSize = self->_label.frame.size;
    self.view = self->_scrollView;
}

-(void)doneButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)LinkTextView:(LinkTextView *)label didSelectLinkWithTextCheckingResult:(NSTextCheckingResult *)result {
    [(AppDelegate *)([UIApplication sharedApplication].delegate) launchURL:result.URL];
    if([result.URL.scheme hasPrefix:@"irc"])
        [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
