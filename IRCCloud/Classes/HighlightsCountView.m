//
//  HighlightsCountView.m
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


#import "HighlightsCountView.h"

@implementation HighlightsCountView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self->_font = [UIFont boldSystemFontOfSize:14];
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self->_font = [UIFont boldSystemFontOfSize:14];
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

-(void)setCount:(NSString *)count {
    self->_count = count;
    [self invalidateIntrinsicContentSize];
    [self setNeedsDisplay];
}

-(NSString *)count {
    return _count;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGContextAddEllipseInRect(ctx, rect);
    CGContextSetFillColorWithColor(ctx, [[UIColor redColor] CGColor]);
    CGContextFillPath(ctx);
    CGContextRestoreGState(ctx);
    CGContextSaveGState(ctx);
    [[UIColor whiteColor] set];
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    CGSize size = [self->_count sizeWithFont:self->_font forWidth:rect.size.width lineBreakMode:NSLineBreakByClipping];
    [self->_count drawInRect:CGRectMake(rect.origin.x + ((rect.size.width - size.width) / 2), rect.origin.y + ((rect.size.height - size.height) / 2), size.width, size.height)
              withFont:self->_font];
#pragma GCC diagnostic pop
    CGContextRestoreGState(ctx);
}

-(CGSize)intrinsicContentSize {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    CGSize size = [self->_count sizeWithFont:self->_font forWidth:INT_MAX lineBreakMode:NSLineBreakByClipping];
#pragma GCC diagnostic pop
    size.width += 6;
    size.height += 6;
    if(size.width < size.height)
        size.width = size.height;
    return size;
}

@end
