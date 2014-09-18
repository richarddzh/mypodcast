//
//  DZFeedParser.m
//  mypodcast
//
//  Created by Richard Dong on 14-8-15.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZFeedParser.h"
#import "DZItem.h"
#import "DZChannel.h"

BOOL DZStringEqual(NSString * s1, NSString * s2)
{
    return [s1 compare:s2] == NSOrderedSame;
}

BOOL DZStringEqualAny(NSString * s1, NSArray * s2)
{
    for (NSString * s in s2) {
        if ([s1 compare:s] == NSOrderedSame) {
            return YES;
        }
    }
    return NO;
}

NSNumber * DZTimeFromString(NSString * s)
{
    float time = 0, period = 0;
    NSCharacterSet * digit = [NSCharacterSet decimalDigitCharacterSet];
    for (int i = 0; i < s.length; ++i) {
        unichar ch = [s characterAtIndex:i];
        if (ch == ':') {
            time = (time + period) * 60;
            period = 0;
        }
        else if ([digit characterIsMember:ch]) {
            period = period * 10 + (ch - '0');
        }
        else {
            break;
        }
    }
    return @(time + period);
}

NSDate * DZDateFromString(NSString * s)
{
    NSDateFormatter * format = [[NSDateFormatter alloc]init];
    [format setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US"]];
    NSDate * date = [format dateFromString:s];
    if (date == nil) {
        [format setDateFormat:@"EEE, d MMM yyyy h:m:s ZZZ"];
        date = [format dateFromString:s];
    }
    if (date == nil) {
        [format setDateFormat:@"d MMM yyyy h:m:s ZZZ"];
        date = [format dateFromString:s];
    }
    return date;
}

@interface DZFeedParser ()
{
    DZChannel *         _channel;
    NSXMLParser *       _parser;
    NSString *          _innerText;
    NSString *          _itemTitle;
    NSString *          _itemUrl;
    NSString *          _itemGuid;
    NSString *          _itemPubDate;
    NSString *          _itemDuration;
    id<DZObjectFactory> _factory;
    BOOL                _inItem;
}
@end

@implementation DZFeedParser

- (DZChannel *)parseFeed:(NSData *)data atURL:(NSString *)url withObjectFactory:(id<DZObjectFactory>)factory error:(NSError **)error
{
    self->_channel = [factory channelWithURL:url];
    self->_factory = factory;
    self->_parser = [[NSXMLParser alloc]initWithData:data];
    if (self->_parser == nil || self->_channel == nil) {
        return nil;
    }
    self->_inItem = NO;
    self->_innerText = nil;
    [self->_parser setDelegate:self];
    if ([self->_parser parse]) {
        *error = nil;
    } else {
        *error = self->_parser.parserError;
    }
    return self->_channel;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if (DZStringEqual(elementName, @"item")) {
        self->_inItem = YES;
        self->_itemDuration = nil;
        self->_itemGuid = nil;
        self->_itemPubDate = nil;
        self->_itemTitle = nil;
        self->_itemUrl = nil;
    }
    else if (DZStringEqualAny(elementName, @[@"title", @"description", @"guid", @"pubDate", @"itunes:duration"])) {
        self->_innerText = @"";
    }
    else if (DZStringEqual(elementName, @"itunes:image")) {
        NSString * href = [attributeDict objectForKey:@"href"];
        if (href != nil && !self->_inItem) {
            self->_channel.image = href;
        }
    }
    else if (DZStringEqual(elementName, @"enclosure")) {
        NSString * url = [attributeDict objectForKey:@"url"];
        self->_itemUrl = url;
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if (DZStringEqual(elementName, @"item")) {
        self->_inItem = NO;
        if (self->_itemGuid != nil && self->_channel != nil) {
            DZItem * item = [self->_factory itemInChannel:self->_channel withGuid:self->_itemGuid];
            item.feed = @(YES);
            if (self->_itemUrl != nil) item.url = self->_itemUrl;
            if (self->_itemTitle != nil) item.title = self->_itemTitle;
            if (self->_itemDuration != nil) item.duration = DZTimeFromString(self->_itemDuration);
            if (self->_itemPubDate != nil) item.pubDate = DZDateFromString(self->_itemPubDate);
        }
    }
    else if (DZStringEqual(elementName, @"title")) {
        if (self->_inItem) {
            self->_itemTitle = self->_innerText;
        } else {
            self->_channel.title = self->_innerText;
        }
    }
    else if (DZStringEqual(elementName, @"description")) {
        self->_channel.descriptions = self->_innerText;
    }
    else if (DZStringEqual(elementName, @"guid") && self->_inItem) {
        self->_itemGuid = self->_innerText;
    }
    else if (DZStringEqual(elementName, @"itunes:duration") && self->_inItem) {
        self->_itemDuration = self->_innerText;
    }
    else if (DZStringEqual(elementName, @"pubDate") && self->_inItem) {
        self->_itemPubDate = self->_innerText;
    }
    self->_innerText = nil;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (self->_innerText == nil) {
        return;
    }
    self->_innerText = [self->_innerText stringByAppendingString:string];
}

@end
