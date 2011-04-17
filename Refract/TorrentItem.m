//
//  TorrentItem.m
//  Refract
//
//  Created by xiphux on 4/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TorrentItem.h"
#import "RFTorrent.h"
#import "RFUtils.h"

@interface TorrentItem ()
- (void)updateUpperLabel;
- (void)updateLowerLabel;
- (void)torrentUpdated;
@end

@implementation TorrentItem

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

@synthesize upperLabel;
@synthesize lowerLabel;

- (void)awakeFromNib
{
    [self updateUpperLabel];
    [self updateLowerLabel];
}

- (void)setRepresentedObject:(id)newObject
{
    if ([self representedObject]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"TorrentUpdated" object:[self representedObject]];
    }
    
    [super setRepresentedObject:newObject];
    
    if ([self representedObject]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(torrentUpdated) name:@"TorrentUpdated" object:[self representedObject]];
    }
    
    [self torrentUpdated];
}

- (void)torrentUpdated
{
    [self updateUpperLabel];
    [self updateLowerLabel];
}

- (void)updateUpperLabel
{
    NSString *label = @"";
    
    if ([self representedObject]) {
        RFTorrent *t = [self representedObject];
        switch ([t status]) {
            case stDownloading:
                label = [NSString stringWithFormat:@"%@ of %@ (%.2f%%) - %d remaining", [RFUtils readableBytesDecimal:[t currentSize]], [RFUtils readableBytesDecimal:[t doneSize]], [t percent], [t eta]];
                break;
            case stSeeding:
                // TODO: ratio, uploaded amount, convert eta to readable
                label = [NSString stringWithFormat:@"%@, uploaded  (Ratio: ) - %d remaining", [RFUtils readableBytesDecimal:[t doneSize]], [t eta]];
                break;
            case stStopped:
                label = [NSString stringWithFormat:@"%@, uploaded  (Ratio: )", [RFUtils readableBytesDecimal:[t doneSize]]];
                break;
        }
    }
    
    [upperLabel setStringValue:label];
}

- (void)updateLowerLabel
{
    NSString *label = @"";
    
    if ([self representedObject]) {
        RFTorrent *t = [self representedObject];
        switch ([t status]) {
            case stDownloading:
                label = [NSString stringWithFormat:@"Downloading from %d of %d peers - DL: %@, UL: %@", [t peersDownload], [t peersConnected], [RFUtils readableRateDecimal:[t downloadRate]], [RFUtils readableRateDecimal:[t uploadRate]]];
                break;
            case stSeeding:
                label = [NSString stringWithFormat:@"Seeding to %d of %d peers - UL: %@", [t peersUpload], [t peersConnected], [RFUtils readableRateDecimal:[t uploadRate]]];
                break;
            case stStopped:
                label = [NSString stringWithFormat:@"Stopped"];
                break;
        }
    }
    
    [lowerLabel setStringValue:label];
}

@end
