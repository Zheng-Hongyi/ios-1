//
//  CollapsedEvents.m
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


#import "CollapsedEvents.h"
#import "ColorFormatter.h"
#import "NetworkConnection.h"
#import "UIColor+IRCCloud.h"

@implementation CollapsedEvent
-(NSComparisonResult)compare:(CollapsedEvent *)aEvent {
    if(self->_type == aEvent.type) {
        if(self->_eid < aEvent.eid)
            return NSOrderedAscending;
        else
            return NSOrderedDescending;
    } else if(self->_type < aEvent.type) {
        return NSOrderedAscending;
    } else {
        return NSOrderedDescending;
    }
}
-(NSString *)description {
    return [NSString stringWithFormat:@"{type: %i, chan: %@, nick: %@, oldNick: %@, hostmask: %@, fromMode: %@, targetMode: %@, modes: %@, msg: %@}", _type, _chan, _nick, _oldNick, _hostname, _fromMode, _targetMode, [self modes:YES mode_modes:nil], _msg];
}
-(BOOL)addMode:(NSString *)mode server:(Server *)server {
    if([mode rangeOfString:server?server.MODE_OPER.lowercaseString:@"y"].location != NSNotFound)
        self->_operIsLower = YES;
    mode = mode.lowercaseString;
    
    if([mode rangeOfString:server?server.MODE_OPER.lowercaseString:@"y"].location != NSNotFound) {
        if(self->_modes[kCollapsedModeDeOper])
            self->_modes[kCollapsedModeDeOper] = false;
        else
            self->_modes[kCollapsedModeOper] = true;
    } else if([mode rangeOfString:server?server.MODE_OWNER.lowercaseString:@"q"].location != NSNotFound) {
        if(self->_modes[kCollapsedModeDeOwner])
            self->_modes[kCollapsedModeDeOwner] = false;
        else
            self->_modes[kCollapsedModeOwner] = true;
    } else if([mode rangeOfString:server?server.MODE_ADMIN.lowercaseString:@"a"].location != NSNotFound) {
        if(self->_modes[kCollapsedModeDeAdmin])
            self->_modes[kCollapsedModeDeAdmin] = false;
        else
            self->_modes[kCollapsedModeAdmin] = true;
    } else if([mode rangeOfString:server?server.MODE_OP.lowercaseString:@"o"].location != NSNotFound) {
        if(self->_modes[kCollapsedModeDeOp])
            self->_modes[kCollapsedModeDeOp] = false;
        else
            self->_modes[kCollapsedModeOp] = true;
    } else if([mode rangeOfString:server?server.MODE_HALFOP.lowercaseString:@"h"].location != NSNotFound) {
        if(self->_modes[kCollapsedModeDeHalfOp])
            self->_modes[kCollapsedModeDeHalfOp] = false;
        else
            self->_modes[kCollapsedModeHalfOp] = true;
    } else if([mode rangeOfString:server?server.MODE_VOICED.lowercaseString:@"v"].location != NSNotFound) {
        if(self->_modes[kCollapsedModeDeVoice])
            self->_modes[kCollapsedModeDeVoice] = false;
        else
            self->_modes[kCollapsedModeVoice] = true;
    } else {
        return NO;
    }

    if([self modeCount] == 0)
        return [self addMode:mode server:server];
    return YES;
}
-(BOOL)removeMode:(NSString *)mode server:(Server *)server {
    mode = mode.lowercaseString;
    
    if([mode rangeOfString:server?server.MODE_OPER.lowercaseString:@"y"].location != NSNotFound) {
        if(self->_modes[kCollapsedModeOper])
            self->_modes[kCollapsedModeOper] = false;
        else
            self->_modes[kCollapsedModeDeOper] = true;
    } else if([mode rangeOfString:server?server.MODE_OWNER.lowercaseString:@"q"].location != NSNotFound) {
        if(self->_modes[kCollapsedModeOwner])
            self->_modes[kCollapsedModeOwner] = false;
        else
            self->_modes[kCollapsedModeDeOwner] = true;
    } else if([mode rangeOfString:server?server.MODE_ADMIN.lowercaseString:@"a"].location != NSNotFound) {
        if(self->_modes[kCollapsedModeAdmin])
            self->_modes[kCollapsedModeAdmin] = false;
        else
            self->_modes[kCollapsedModeDeAdmin] = true;
    } else if([mode rangeOfString:server?server.MODE_OP.lowercaseString:@"o"].location != NSNotFound) {
        if(self->_modes[kCollapsedModeOp])
            self->_modes[kCollapsedModeOp] = false;
        else
            self->_modes[kCollapsedModeDeOp] = true;
    } else if([mode rangeOfString:server?server.MODE_HALFOP.lowercaseString:@"h"].location != NSNotFound) {
        if(self->_modes[kCollapsedModeHalfOp])
            self->_modes[kCollapsedModeHalfOp] = false;
        else
            self->_modes[kCollapsedModeDeHalfOp] = true;
    } else if([mode rangeOfString:server?server.MODE_VOICED.lowercaseString:@"v"].location != NSNotFound) {
        if(self->_modes[kCollapsedModeVoice])
            self->_modes[kCollapsedModeVoice] = false;
        else
            self->_modes[kCollapsedModeDeVoice] = true;
    } else {
        return NO;
    }
    if([self modeCount] == 0)
        return [self removeMode:mode server:server];
    return YES;
}
-(void)_copyModes:(BOOL *)to {
    for(int i = 0; i < sizeof(self->_modes); i++) {
        to[i] = self->_modes[i];
    }
}
-(void)copyModes:(CollapsedEvent *)from {
    [from _copyModes:self->_modes];
    self->_operIsLower = from.operIsLower;
}
-(NSString *)modes:(BOOL)showSymbol mode_modes:(NSArray *)mode_modes {
    static NSString *mode_msgs[] = {
        @"promoted to oper",
        @"promoted to owner",
        @"promoted to admin",
        @"opped",
        @"halfopped",
        @"voiced",
        @"demoted from oper",
        @"demoted from owner",
        @"demoted from admin",
        @"de-opped",
        @"de-halfopped",
        @"de-voiced"
    };
    static NSString *mode_colors[] = {
        @"E02305",
        @"E7AA00",
        @"6500A5",
        @"BA1719",
        @"B55900",
        @"25B100"
    };
    NSString *output = nil;
    if(!mode_modes) {
        mode_modes = @[
            self->_operIsLower?@"+y":@"+Y",
            @"+q",
            @"+a",
            @"+o",
            @"+h",
            @"+v",
            self->_operIsLower?@"-y":@"-Y",
            @"-q",
            @"-a",
            @"-o",
            @"-h",
            @"-v"
        ];
    }
    
    if([self modeCount]) {
        output = @"";
        for(int i = 0; i < sizeof(self->_modes); i++) {
            if(self->_modes[i]) {
                if(output.length)
                    output = [output stringByAppendingString:@", "];
                output = [output stringByAppendingString:mode_msgs[i]];
                if(showSymbol) {
                    output = [output stringByAppendingFormat:@" (%c%@%@%c%@)", COLOR_RGB, mode_colors[i%6], mode_modes[i], COLOR_RGB, [UIColor messageTextColor].toHexString];
                }
            }
        }
    }
    
    return output;
}
-(int)modeCount {
    int count = 0;
    for(int i = 0; i < sizeof(self->_modes); i++) {
        if(self->_modes[i])
            count++;
    }
    return count;
}
@end

@implementation CollapsedEvents
-(id)init {
    self = [super init];
    if(self) {
        self->_data = [[NSMutableArray alloc] init];
        [self setServer:nil];
    }
    return self;
}
-(void)clear {
    @synchronized(self->_data) {
        [self->_data removeAllObjects];
    }
}
-(void)setServer:(Server *)server {
    self->_server = server;
    if(server) {
        self->_mode_modes = @[
            [NSString stringWithFormat:@"+%@", server.MODE_OPER],
            [NSString stringWithFormat:@"+%@", server.MODE_OWNER],
            [NSString stringWithFormat:@"+%@", server.MODE_ADMIN],
            [NSString stringWithFormat:@"+%@", server.MODE_OP],
            [NSString stringWithFormat:@"+%@", server.MODE_HALFOP],
            [NSString stringWithFormat:@"+%@", server.MODE_VOICED],
            [NSString stringWithFormat:@"-%@", server.MODE_OPER],
            [NSString stringWithFormat:@"-%@", server.MODE_OWNER],
            [NSString stringWithFormat:@"-%@", server.MODE_ADMIN],
            [NSString stringWithFormat:@"-%@", server.MODE_OP],
            [NSString stringWithFormat:@"-%@", server.MODE_HALFOP],
            [NSString stringWithFormat:@"-%@", server.MODE_VOICED],
        ];
    } else {
        self->_mode_modes = nil;
    }
}
-(CollapsedEvent *)findEvent:(NSString *)nick chan:(NSString *)chan {
    @synchronized(self->_data) {
        for(CollapsedEvent *event in _data) {
            if([[event.nick lowercaseString] isEqualToString:[nick lowercaseString]] && (chan == nil || event.chan == nil || [[event.chan lowercaseString] isEqualToString:[chan lowercaseString]]))
                return event;
        }
        return nil;
    }
}
-(void)addCollapsedEvent:(CollapsedEvent *)event {
    @synchronized(self->_data) {
        CollapsedEvent *e = nil;
        
        if(event.type < kCollapsedEventNickChange) {
            if(self->_showChan) {
                if(event.type == kCollapsedEventQuit) {
                    BOOL found = NO;
                    for(e in _data) {
                        if(e.type == kCollapsedEventJoin) {
                            e.type = kCollapsedEventPopIn;
                            found = YES;
                        }
                    }
                    if(found)
                        return;
                } else if(event.type == kCollapsedEventJoin) {
                    for(e in _data) {
                        if(e.type == kCollapsedEventQuit) {
                            [self->_data removeObject:e];
                            event.type = kCollapsedEventPopOut;
                            break;
                        } else if(e.type == kCollapsedEventPopOut) {
                            event.type = kCollapsedEventPopOut;
                            break;
                        }
                    }
                }
                e = nil;
            }
            if(event.oldNick.length > 0 && event.type != kCollapsedEventMode) {
                e = [self findEvent:event.oldNick chan:event.chan];
                if(e)
                    e.nick = event.nick;
            }
            
            if(!e)
                e = [self findEvent:event.nick chan:event.chan];
            
            if(e) {
                if(e.type == kCollapsedEventMode) {
                    e.type = event.type;
                    e.msg = event.msg;
                    if(event.fromMode)
                        e.fromMode = event.fromMode;
                    if(event.targetMode)
                        e.targetMode = event.targetMode;
                    e.hostname = event.hostname;
                } else if(e.type == kCollapsedEventNickChange) {
                    e.type = event.type;
                    e.msg = event.msg;
                    e.fromMode = event.fromMode;
                    e.fromNick = event.fromNick;
                } else if(event.type == kCollapsedEventMode) {
                    e.fromMode = event.targetMode;
                } else if(event.type == e.type) {
                } else if(event.type == kCollapsedEventJoin) {
                    if(e.type == kCollapsedEventPopIn)
                        e.type = kCollapsedEventJoin;
                    else
                        e.type = kCollapsedEventPopOut;
                    e.fromMode = event.fromMode;
                    e.msg = nil;
                } else if(e.type == kCollapsedEventPopOut) {
                    e.type = event.type;
                } else {
                    e.type = kCollapsedEventPopIn;
                }
                e.eid = event.eid;
                if(event.type == kCollapsedEventPart || event.type == kCollapsedEventQuit)
                    e.msg = event.msg;
                [e copyModes:event];
            } else {
                [self->_data addObject:event];
            }
        } else {
            if(event.type == kCollapsedEventNickChange) {
                for(CollapsedEvent *e1 in _data) {
                    if(e1.type == kCollapsedEventNickChange && [[e1.nick lowercaseString] isEqualToString:[event.oldNick lowercaseString]]) {
                        if([[e1.oldNick lowercaseString] isEqualToString:[event.nick lowercaseString]]) {
                            [self->_data removeObject:e1];
                        } else {
                            e1.eid = event.eid;
                            e1.nick = event.nick;
                        }
                        return;
                    }
                    if((e1.type == kCollapsedEventJoin || e1.type == kCollapsedEventPopOut) && [[e1.nick lowercaseString] isEqualToString:[event.oldNick lowercaseString]]) {
                        e1.eid = event.eid;
                        e1.oldNick = event.oldNick;
                        e1.nick = event.nick;
                        for(CollapsedEvent *e2 in _data) {
                            if((e2.type == kCollapsedEventQuit || e2.type == kCollapsedEventPart) && [[e2.nick lowercaseString] isEqualToString:[event.nick lowercaseString]]) {
                                e1.type = kCollapsedEventPopOut;
                                [self->_data removeObject:e2];
                                break;
                            }
                        }
                        return;
                    }
                    if((e1.type == kCollapsedEventQuit || e1.type == kCollapsedEventPart) && [[e1.nick lowercaseString] isEqualToString:[event.oldNick lowercaseString]]) {
                        e1.eid = event.eid;
                        e1.type = kCollapsedEventPopOut;
                        for(CollapsedEvent *e2 in _data) {
                            if(e2.type == kCollapsedEventJoin && [[e2.nick lowercaseString] isEqualToString:[event.oldNick lowercaseString]]) {
                                [self->_data removeObject:e2];
                                break;
                            }
                        }
                        return;
                    }
                }
                [self->_data addObject:event];
            } else if(event.type == kCollapsedEventConnectionStatus) {
                for(CollapsedEvent *e1 in _data) {
                    if([e1.msg isEqualToString:event.msg]) {
                        e1.count++;
                        return;
                    }
                }
                [self->_data addObject:event];
            } else {
                [self->_data addObject:event];
            }
        }
    }
}
-(BOOL)addEvent:(Event *)event {
    @synchronized(self->_data) {
        CollapsedEvent *c;
        if([event.type hasSuffix:@"user_channel_mode"]) {
            c = [self findEvent:event.nick chan:event.chan];
            if(!c) {
                c = [[CollapsedEvent alloc] init];
                c.type = kCollapsedEventMode;
                c.eid = event.eid;
            }
            if(event.ops) {
                for(NSDictionary *op in [event.ops objectForKey:@"add"]) {
                    if(![c addMode:[op objectForKey:@"mode"] server:self->_server])
                        return NO;
                    if(c.type == kCollapsedEventMode) {
                        c.nick = [op objectForKey:@"param"];
                        if(event.from.length) {
                            c.fromNick = event.from;
                            c.fromMode = event.fromMode;
                        } else if(event.server.length) {
                            c.fromNick = event.server;
                            c.fromMode = @"__the_server__";
                        }
                        c.hostname = event.hostmask;
                        c.targetMode = event.targetMode;
                        c.chan = event.chan;
                        [self addCollapsedEvent:c];
                    } else {
                        c.fromMode = event.targetMode;
                    }
                }
                for(NSDictionary *op in [event.ops objectForKey:@"remove"]) {
                    if(![c removeMode:[op objectForKey:@"mode"] server:self->_server])
                        return NO;
                    if(c.type == kCollapsedEventMode) {
                        c.nick = [op objectForKey:@"param"];
                        if(event.from.length) {
                            c.fromNick = event.from;
                            c.fromMode = event.fromMode;
                        } else if(event.server.length) {
                            c.fromNick = event.server;
                            c.fromMode = @"__the_server__";
                        }
                        c.hostname = event.hostmask;
                        c.targetMode = event.targetMode;
                        c.chan = event.chan;
                        [self addCollapsedEvent:c];
                    } else {
                        c.fromMode = event.targetMode;
                    }
                }
            }
        } else {
            c = [[CollapsedEvent alloc] init];
            c.eid = event.eid;
            if(event.from.length)
                c.nick = event.from;
            else
                c.nick = event.nick;
            c.hostname = event.hostmask;
            c.fromMode = event.fromMode;
            c.chan = event.chan;
            c.count = 1;
            if([event.type hasSuffix:@"joined_channel"]) {
                c.type = kCollapsedEventJoin;
            } else if([event.type hasSuffix:@"parted_channel"]) {
                c.type = kCollapsedEventPart;
                c.msg = event.msg;
            } else if([event.type hasSuffix:@"quit"]) {
                c.type = kCollapsedEventQuit;
                c.msg = event.msg;
                if([[NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^(?:[^\\s:\\/.]+\\.)+[a-z]{2,} (?:[^\\s:\\/.]+\\.)+[a-z]{2,}$"] evaluateWithObject:event.msg]) {
                    NSArray *parts = [event.msg componentsSeparatedByString:@" "];
                    if(parts.count > 1 && ![[parts objectAtIndex:0] isEqualToString:[parts objectAtIndex:1]]) {
                        BOOL match = NO;
                        for(CollapsedEvent *ce in _data) {
                            if(ce.type == kCollapsedEventNetSplit && [ce.msg isEqualToString:event.msg])
                                match = YES;
                        }
                        if(!match && _data.count > 0) {
                            CollapsedEvent *e = [[CollapsedEvent alloc] init];
                            e.type = kCollapsedEventNetSplit;
                            e.msg = event.msg;
                            [self->_data addObject:e];
                        }
                    }
                }
            } else if([event.type hasSuffix:@"nickchange"]) {
                c.type = kCollapsedEventNickChange;
                c.oldNick = event.oldNick;
            } else if([event.type isEqualToString:@"socket_closed"] || [event.type isEqualToString:@"connecting_failed"] || [event.type isEqualToString:@"connecting_cancelled"]) {
                c.type = kCollapsedEventConnectionStatus;
                c.msg = event.msg;
            } else {
                return NO;
            }
            [self addCollapsedEvent:c];
        }
        return YES;
    }
}
-(NSString *)was:(CollapsedEvent *)e {
    NSString *output = @"";
    NSString *modes = [e modes:NO mode_modes:self->_mode_modes];
    
    if(e.oldNick && e.type != kCollapsedEventMode && e.type != kCollapsedEventNickChange)
        output = [NSString stringWithFormat:@"was %@", e.oldNick];
    if(modes.length) {
        if(output.length > 0)
            output = [output stringByAppendingString:@"; "];
        output = [output stringByAppendingString:modes];
    }
    
    if(output.length)
        output = [NSString stringWithFormat:@" (%c%@%@%c)", COLOR_RGB, [UIColor collapsedRowNickColor].toHexString, output, CLEAR];
    
    return output;
}
-(NSString *)collapse {
    @synchronized(self->_data) {
        NSString *output;
        
        if(self->_data.count == 0)
            return nil;
        
        if(self->_data.count == 1 && [[self->_data objectAtIndex:0] modeCount] < ((((CollapsedEvent*)[self->_data objectAtIndex:0]).type == kCollapsedEventMode)?2:1)) {
            CollapsedEvent *e = [self->_data objectAtIndex:0];
            switch(e.type) {
                case kCollapsedEventNetSplit:
                    output = [e.msg stringByReplacingOccurrencesOfString:@" " withString:@" ↮ "];
                    break;
                case kCollapsedEventMode:
                    output = [NSString stringWithFormat:@"%c%@%@%c %c%@was %@", COLOR_RGB, [UIColor collapsedRowNickColor].toHexString, [self formatNick:e.nick mode:e.targetMode colorize:NO defaultColor:[UIColor collapsedRowNickColor].toHexString bold:NO displayName:nil], CLEAR, COLOR_RGB, [UIColor messageTextColor].toHexString, [e modes:YES mode_modes:self->_mode_modes]];
                    if(e.fromNick) {
                        if([e.fromMode isEqualToString:@"__the_server__"])
                            output = [output stringByAppendingFormat:@" by the server %c%@%@%c", COLOR_RGB, [UIColor collapsedRowNickColor].toHexString, e.fromNick, CLEAR];
                        else
                            output = [output stringByAppendingFormat:@" by%c %@", CLEAR, [self formatNick:e.fromNick mode:e.fromMode colorize:NO defaultColor:[UIColor collapsedRowNickColor].toHexString bold:NO displayName:nil]];
                    }
                    break;
                case kCollapsedEventJoin:
                    if(self->_showChan)
                        output = [NSString stringWithFormat:@"%c%@→\U0000FE0E\u00a0%@%c%@ joined %@", COLOR_RGB, [UIColor collapsedRowNickColor].toHexString, [self formatNick:e.nick mode:e.fromMode colorize:NO defaultColor:[UIColor collapsedRowNickColor].toHexString bold:NO displayName:nil], CLEAR, [self was:e], e.chan];
                    else
                        output = [NSString stringWithFormat:@"%c%@→\U0000FE0E\u00a0%@%c%@ joined", COLOR_RGB, [UIColor collapsedRowNickColor].toHexString, [self formatNick:e.nick mode:e.fromMode colorize:NO defaultColor:[UIColor collapsedRowNickColor].toHexString bold:NO displayName:nil], CLEAR, [self was:e]];
                    if(!_server.isSlack)
                        output = [output stringByAppendingFormat:@" (%@)", self->_noColor ? e.hostname.stripIRCFormatting : e.hostname];
                    break;
                case kCollapsedEventPart:
                    if(self->_showChan)
                        output = [NSString stringWithFormat:@"%c%@←\U0000FE0E\u00a0%@%c%@ left %@", COLOR_RGB, [UIColor collapsedRowNickColor].toHexString, [self formatNick:e.nick mode:e.fromMode colorize:NO defaultColor:[UIColor collapsedRowNickColor].toHexString bold:NO displayName:nil], CLEAR, [self was:e], e.chan];
                    else
                        output = [NSString stringWithFormat:@"%c%@←\U0000FE0E\u00a0%@%c%@ left", COLOR_RGB, [UIColor collapsedRowNickColor].toHexString, [self formatNick:e.nick mode:e.fromMode colorize:NO defaultColor:[UIColor collapsedRowNickColor].toHexString bold:NO displayName:nil], CLEAR, [self was:e]];
                    if(!_server.isSlack)
                        output = [output stringByAppendingFormat:@" (%@)", self->_noColor ? e.hostname.stripIRCFormatting : e.hostname];
                    if(e.msg.length > 0)
                        output = [output stringByAppendingFormat:@": %@", self->_noColor ? e.msg.stripIRCFormatting : e.msg];
                    break;
                case kCollapsedEventQuit:
                    output = [NSString stringWithFormat:@"%c%@⇐\U0000FE0E\u00a0%@%c%@ quit", COLOR_RGB, [UIColor collapsedRowNickColor].toHexString, [self formatNick:e.nick mode:e.fromMode colorize:NO defaultColor:[UIColor collapsedRowNickColor].toHexString bold:NO displayName:nil], CLEAR, [self was:e]];
                    if(!_server.isSlack && e.hostname.length > 0)
                        output = [output stringByAppendingFormat:@" (%@)", self->_noColor ? e.hostname.stripIRCFormatting : e.hostname];
                    if(e.msg.length > 0)
                        output = [output stringByAppendingFormat:@": %@", self->_noColor ? e.msg.stripIRCFormatting : e.msg];
                    break;
                case kCollapsedEventNickChange:
                    output = [NSString stringWithFormat:@"%@ %c%@→\U0000FE0E\u00a0%@%c", e.oldNick, COLOR_RGB, [UIColor collapsedRowNickColor].toHexString, [self formatNick:e.nick mode:e.fromMode colorize:NO defaultColor:[UIColor collapsedRowNickColor].toHexString bold:NO displayName:nil], CLEAR];
                    break;
                case kCollapsedEventPopIn:
                    output = [NSString stringWithFormat:@"%c%@↔\U0000FE0E\u00a0%@%c%@ popped in", COLOR_RGB, [UIColor collapsedRowNickColor].toHexString, [self formatNick:e.nick mode:e.fromMode colorize:NO defaultColor:[UIColor collapsedRowNickColor].toHexString bold:NO displayName:nil], CLEAR, [self was:e]];
                    if(self->_showChan)
                        output = [output stringByAppendingFormat:@" %@", e.chan];
                    break;
                case kCollapsedEventPopOut:
                    output = [NSString stringWithFormat:@"%c%@↔\U0000FE0E\u00a0%@%c%@ nipped out", COLOR_RGB, [UIColor collapsedRowNickColor].toHexString, [self formatNick:e.nick mode:e.fromMode colorize:NO defaultColor:[UIColor collapsedRowNickColor].toHexString bold:NO displayName:nil], CLEAR, [self was:e]];
                    if(self->_showChan)
                        output = [output stringByAppendingFormat:@" %@", e.chan];
                    break;
                case kCollapsedEventConnectionStatus:
                    output = e.msg;
                    if(e.count > 1)
                        output = [output stringByAppendingFormat:@" (x%i)", e.count];
                    break;
            }
        } else {
            [self->_data sortUsingSelector:@selector(compare:)];
            NSEnumerator *i = [self->_data objectEnumerator];
            CollapsedEvent *last = nil;
            CollapsedEvent *next = [i nextObject];
            CollapsedEvent *e;
            int groupcount = 0;
            NSMutableString *message = [[NSMutableString alloc] init];
            
            while(next) {
                e = next;
                next = [i nextObject];
                
                if(message.length > 0 && e.type < kCollapsedEventNickChange && ((next == nil || next.type != e.type) && last != nil && last.type == e.type)) {
					if(groupcount == 1) {
                        [message deleteCharactersInRange:NSMakeRange(message.length - 2, 2)];
                        [message appendString:@" "];
                    }
                    [message appendString:@"and "];
				}
                
                if(last == nil || last.type != e.type) {
                    switch(e.type) {
                        case kCollapsedEventMode:
                            if(message.length)
                                [message appendString:@"•\u00a0"];
                            [message appendFormat:@"%c%@mode:\u00a0%c", COLOR_RGB, [UIColor collapsedRowNickColor].toHexString, CLEAR];
                            break;
                        case kCollapsedEventJoin:
                            [message appendFormat:@"%c%@→\U0000FE0E\u00a0%c", COLOR_RGB, [UIColor collapsedRowNickColor].toHexString, CLEAR];
                            break;
                        case kCollapsedEventPart:
                            [message appendFormat:@"%c%@←\U0000FE0E\u00a0%c", COLOR_RGB, [UIColor collapsedRowNickColor].toHexString, CLEAR];
                            break;
                        case kCollapsedEventQuit:
                            [message appendFormat:@"%c%@⇐\U0000FE0E\u00a0%c", COLOR_RGB, [UIColor collapsedRowNickColor].toHexString, CLEAR];
                            break;
                        case kCollapsedEventNickChange:
                            if(message.length)
                                [message appendString:@"•\u00a0"];
                            break;
                        case kCollapsedEventPopIn:
                        case kCollapsedEventPopOut:
                            [message appendFormat:@"%c%@↔\U0000FE0E\u00a0%c", COLOR_RGB, [UIColor collapsedRowNickColor].toHexString, CLEAR];
                            break;
                        default:
                            break;
                    }
                }
                
                if(e.type == kCollapsedEventNickChange) {
                    [message appendFormat:@"%@ %c%@→\U0000FE0E\u00a0%@%c", e.oldNick, COLOR_RGB, [UIColor collapsedRowNickColor].toHexString, [self formatNick:e.nick mode:e.fromMode colorize:NO defaultColor:[UIColor collapsedRowNickColor].toHexString bold:NO displayName:nil], CLEAR];
                    [message appendString:[self was:e]];
                } else if(e.type == kCollapsedEventNetSplit) {
                    [message appendString:[e.msg stringByReplacingOccurrencesOfString:@" " withString:@" ↮\U0000FE0E\u00a0"]];
                } else if(e.type == kCollapsedEventConnectionStatus) {
                    if(e.msg) {
                        [message appendString:e.msg];
                        if(e.count > 1)
                            [message appendFormat:@" (x%i)", e.count];
                    }
                } else if(!_showChan) {
                    [message appendString:[self formatNick:e.nick mode:(e.type == kCollapsedEventMode)?e.targetMode:e.fromMode colorize:NO defaultColor:[UIColor collapsedRowNickColor].toHexString bold:NO displayName:nil]];
                    [message appendString:[self was:e]];
                }
                
                if((next == nil || next.type != e.type) && !_showChan) {
                    switch(e.type) {
                        case kCollapsedEventJoin:
                            [message appendString:@" joined"];
                            break;
                        case kCollapsedEventPart:
                            [message appendString:@" left"];
                            break;
                        case kCollapsedEventQuit:
                            [message appendString:@" quit"];
                            break;
                        case kCollapsedEventPopIn:
                            [message appendString:@" popped in"];
                            break;
                        case kCollapsedEventPopOut:
                            [message appendString:@" nipped out"];
                            break;
                        default:
                            break;
                    }
                } else if(self->_showChan && e.type != kCollapsedEventNetSplit && e.type != kCollapsedEventConnectionStatus && e.type != kCollapsedEventNickChange) {
                    if(groupcount == 0) {
                        [message appendString:[self formatNick:e.nick mode:(e.type == kCollapsedEventMode)?e.targetMode:e.fromMode colorize:NO displayName:nil]];
                        [message appendString:[self was:e]];
                        switch(e.type) {
                            case kCollapsedEventJoin:
                                [message appendString:@" joined "];
                                break;
                            case kCollapsedEventPart:
                                [message appendString:@" left "];
                                break;
                            case kCollapsedEventQuit:
                                [message appendString:@" quit"];
                                break;
                            case kCollapsedEventPopIn:
                                [message appendString:@" popped in "];
                                break;
                            case kCollapsedEventPopOut:
                                [message appendString:@" nipped out "];
                                break;
                            default:
                                break;
                        }
                    }
                    if(e.type != kCollapsedEventQuit && e.chan)
                        [message appendString:e.chan];
                }
                
                if(next != nil && next.type == e.type && message.length > 0) {
                    [message appendString:@", "];
                    groupcount++;
                } else if(next != nil) {
                    [message appendString:@" "];
                    groupcount = 0;
                }
                
                last = e;
            }
            output = message;
        }
        
        return output;
    }
}

-(NSUInteger)count {
    return _data.count;
}

-(NSString *)formatNick:(NSString *)nick mode:(NSString *)mode colorize:(BOOL)colorize displayName:(NSString *)displayName {
    return [self formatNick:nick mode:mode colorize:colorize defaultColor:nil bold:YES displayName:displayName];
}
-(NSString *)formatNick:(NSString *)nick mode:(NSString *)mode colorize:(BOOL)colorize defaultColor:(NSString *)color displayName:(NSString *)displayName {
    return [self formatNick:nick mode:mode colorize:colorize defaultColor:color bold:YES displayName:displayName];
}
-(NSString *)formatNick:(NSString *)nick mode:(NSString *)mode colorize:(BOOL)colorize defaultColor:(NSString *)color bold:(BOOL)bold displayName:(NSString *)displayName {
    if(!displayName)
        displayName = nick;
    
    NSDictionary *PREFIX = nil;
    if(self->_server)
        PREFIX = self->_server.PREFIX;
    
    if(!PREFIX || PREFIX.count == 0) {
        PREFIX = @{_server?_server.MODE_OPER:@"y":@"!",
                   self->_server?_server.MODE_OWNER:@"q":@"~",
                   self->_server?_server.MODE_ADMIN:@"a":@"&",
                   self->_server?_server.MODE_OP:@"o":@"@",
                   self->_server?_server.MODE_HALFOP:@"h":@"%",
                   self->_server?_server.MODE_VOICED:@"v":@"+"};
    }
    
    NSDictionary *mode_colors = @{
        self->_server?_server.MODE_OPER.lowercaseString:@"y":@"E7AA00",
        self->_server?_server.MODE_OWNER.lowercaseString:@"q":@"E7AA00",
        self->_server?_server.MODE_ADMIN.lowercaseString:@"a":@"6500A5",
        self->_server?_server.MODE_OP.lowercaseString:@"o":@"BA1719",
        self->_server?_server.MODE_HALFOP.lowercaseString:@"h":@"B55900",
        self->_server?_server.MODE_VOICED.lowercaseString:@"v":@"25B100"
    };
    
    NSMutableString *output = [[NSMutableString alloc] initWithCapacity:100];
    [output appendFormat:@"%c", BOLD];
    BOOL showSymbol = [[NetworkConnection sharedInstance] prefs] && [[[[NetworkConnection sharedInstance] prefs] objectForKey:@"mode-showsymbol"] boolValue];
    
    if(colorize && nick) {
        color = [UIColor colorForNick:nick];
    }
    
    if(mode.length) {
        if([mode rangeOfString:self->_server?_server.MODE_OPER:@"Y"].location != NSNotFound)
            mode = self->_server?_server.MODE_OPER:@"Y";
        else if([mode rangeOfString:self->_server?_server.MODE_OPER.lowercaseString:@"y"].location != NSNotFound)
            mode = self->_server?_server.MODE_OPER.lowercaseString:@"y";
        else if([mode rangeOfString:self->_server?_server.MODE_OWNER:@"q"].location != NSNotFound)
            mode = self->_server?_server.MODE_OWNER:@"q";
        else if([mode rangeOfString:self->_server?_server.MODE_ADMIN:@"a"].location != NSNotFound)
            mode = self->_server?_server.MODE_ADMIN:@"a";
        else if([mode rangeOfString:self->_server?_server.MODE_OP:@"o"].location != NSNotFound)
            mode = self->_server?_server.MODE_OP:@"o";
        else if([mode rangeOfString:self->_server?_server.MODE_HALFOP:@"h"].location != NSNotFound)
            mode = self->_server?_server.MODE_HALFOP:@"h";
        else if([mode rangeOfString:self->_server?_server.MODE_VOICED:@"v"].location != NSNotFound)
            mode = self->_server?_server.MODE_VOICED:@"v";
        else
            mode = [mode substringToIndex:1];
        
        if(showSymbol) {
            if([PREFIX objectForKey:mode]) {
                if([mode_colors objectForKey:mode.lowercaseString]) {
                    [output appendFormat:@"%c%@%@%c\u202f", COLOR_RGB, [mode_colors objectForKey:mode.lowercaseString], [PREFIX objectForKey:mode], COLOR_RGB];
                } else {
                    [output appendFormat:@"%@\u202f", [PREFIX objectForKey:mode]];
                }
            }
        } else {
            if([mode_colors objectForKey:mode.lowercaseString]) {
                [output appendFormat:@"%c%@•%c\u202f", COLOR_RGB, [mode_colors objectForKey:mode.lowercaseString], COLOR_RGB];
            } else {
                [output appendString:@"•\u202f"];
            }
        }
    }

    if(!bold)
        [output appendFormat:@"%c", BOLD];
    
    if(color) {
        [output appendFormat:@"%c%@%@%c", COLOR_RGB, color, displayName, COLOR_RGB];
    } else {
        [output appendFormat:@"%@", displayName];
    }
    
    if(bold)
        [output appendFormat:@"%c", BOLD];

    return output;
}
@end
