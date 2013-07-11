//
//  NamesListTableViewController.m
//  IRCCloud
//
//  Created by Sam Steele on 7/7/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import "NamesListTableViewController.h"
#import "TTTAttributedLabel.h"
#import "ColorFormatter.h"
#import "NetworkConnection.h"

@interface NamesTableCell : UITableViewCell {
    TTTAttributedLabel *_info;
}
@property (readonly) UILabel *info;
@end

@implementation NamesTableCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _info = [[TTTAttributedLabel alloc] init];
        _info.font = [UIFont systemFontOfSize:FONT_SIZE];
        _info.textColor = [UIColor grayColor];
        _info.lineBreakMode = NSLineBreakByCharWrapping;
        _info.numberOfLines = 0;
        [self.contentView addSubview:_info];
    }
    return self;
}

-(void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect frame = [self.contentView bounds];
    frame.origin.x = 6;
    frame.size.width -= 12;
    
    _info.frame = frame;
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end

@implementation NamesListTableViewController

-(id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        //_addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonPressed)];
    }
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    //self.navigationItem.leftBarButtonItem = _addButton;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
    [self refresh];
}

-(void)refresh {
    NSMutableArray *data = [[NSMutableArray alloc] init];
    
    for(NSDictionary *user in [_event objectForKey:@"members"]) {
        NSMutableDictionary *u = [[NSMutableDictionary alloc] initWithDictionary:user];
        NSString *name;
        if([[user objectForKey:@"mode"] length])
            name = [NSString stringWithFormat:@"%c1%c%@%c (+%@)", COLOR_MIRC, BOLD, [user objectForKey:@"nick"], CLEAR, [user objectForKey:@"mode"]];
        else
            name = [NSString stringWithFormat:@"%c1%c%@", COLOR_MIRC, BOLD, [user objectForKey:@"nick"]];
        NSAttributedString *formatted = [ColorFormatter format:[NSString stringWithFormat:@"%@%c%@%c%@",name,CLEAR,[[user objectForKey:@"away"] intValue]?@" [away]\n":@"\n", ITALICS, [user objectForKey:@"usermask"]] defaultColor:[UIColor lightGrayColor] mono:NO linkify:NO server:nil links:nil];
        [u setObject:formatted forKey:@"formatted"];
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)(formatted));
        CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0,0), NULL, CGSizeMake(self.tableView.bounds.size.width - 6 - 12,CGFLOAT_MAX), NULL);
        [u setObject:@(ceilf(suggestedSize.height) + 16) forKey:@"height"];
        CFRelease(framesetter);
        [data addObject:u];
    }
    
    _data = data;
    [self.tableView reloadData];
}

-(void)doneButtonPressed {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)addButtonPressed {
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *row = [_data objectAtIndex:[indexPath row]];
    return [[row objectForKey:@"height"] floatValue];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_data count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NamesTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"namecell"];
    if(!cell)
        cell = [[NamesTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"namecell"];
    NSDictionary *row = [_data objectAtIndex:[indexPath row]];
    cell.info.attributedText = [row objectForKey:@"formatted"];
    return cell;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [_alertView dismissWithClickedButtonIndex:1 animated:YES];
    [self alertView:_alertView clickedButtonAtIndex:1];
    return NO;
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self dismissViewControllerAnimated:YES completion:nil];
    NSDictionary *row = [_data objectAtIndex:[indexPath row]];
    [[NetworkConnection sharedInstance] say:[NSString stringWithFormat:@"/query %@", [row objectForKey:@"nick"]] to:nil cid:_event.cid];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    _alertView = nil;
}

-(BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    if(alertView.alertViewStyle == UIAlertViewStylePlainTextInput && [alertView textFieldAtIndex:0].text.length == 0)
        return NO;
    else
        return YES;
}

@end
