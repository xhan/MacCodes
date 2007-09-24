#import "URLFormatter.h"


@implementation URLFormatter

/* given a string that may be a http URL, try to massage it into an RFC-compliant http URL string */
- (NSString*)autoCompletedHTTPStringFromString:(NSString*)urlString
{	
	NSArray* stringParts = [urlString componentsSeparatedByString:@"/"];
	NSString* host = [stringParts objectAtIndex:0];
    
	if ([host rangeOfString:@"."].location == NSNotFound)
	{ 
		host = [NSString stringWithFormat:@"www.%@.com", host];
		urlString = [host stringByAppendingString:@"/"];
		
		NSArray* pathStrings = [stringParts subarrayWithRange:NSMakeRange(1, [stringParts count] - 1)];
		NSString* filePath = @"";
		if ([pathStrings count])
			filePath = [pathStrings componentsJoinedByString:@"/"];
		
		urlString = [urlString stringByAppendingString:filePath];
	}
	
	// see if the newly reconstructed string is a well formed URL
	urlString = [@"http://" stringByAppendingString:urlString];
	urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
	return [[NSURL URLWithString:urlString] absoluteString];
}

/* given a string that may be a mailto: URL, try to massage it into an RFC-compliant mailto URL string */
- (NSString*)autoCompletedMailToStringFromString:(NSString*)urlString
{
	if (NSNotFound != [urlString rangeOfString:@"/"].location)
		return nil; // there's a slash, it's probably not a mailto url
	
	NSArray* stringParts = [urlString componentsSeparatedByString:@"@"];
	if ([stringParts count] != 2)
	{	
		stringParts = [urlString componentsSeparatedByString:@" at "];
		if ([stringParts count] != 2)
			return nil; // too few or too many @ symbols
	}
	
	// assume that the front part is an address
	NSString* userAddress = [stringParts objectAtIndex:0];
	
	NSString* mailhost = [stringParts objectAtIndex:1];
	if ([mailhost rangeOfString:@"."].location == NSNotFound)
	{
		// assume a .com address
		mailhost = [NSString stringWithFormat:@"%@.com", mailhost];
	}
	
	// reconstruct the string
	NSString* newAddress = [NSString stringWithFormat:@"mailto:%@@%@", userAddress, mailhost];
	
	// and see if the newly reconstructed string is a well formed URL
	return [[NSURL URLWithString:newAddress] absoluteString];
}


/* given a string that may be an URL of some sort, try to massage it into an RFC-compliant http URL string */
- (NSURL*)autoCompletedURLFromString:(NSString*)urlString
{
    NSURL* theURL = [NSURL URLWithString:urlString];
	
    if (![[theURL scheme] length])
    {
		// first try just correcting percent escapes
		NSString* newURLString = [urlString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
		theURL = [NSURL URLWithString:newURLString];
		
		if (![[theURL scheme] length])
		{	// it still didn;t accept it, try auto-completing
			newURLString = [self autoCompletedMailToStringFromString:urlString];
			if (nil == newURLString)
				newURLString = [self autoCompletedHTTPStringFromString:urlString];
			
			theURL = [NSURL URLWithString:newURLString];
		}
    }
	
	return theURL;
}

- (NSString *)editingStringForObjectValue:(id)inObject
{
	return [inObject description];
}

- (NSString*)stringForObjectValue:(id)inObject
{
	NSURL* theURL;
	
    if (![inObject isKindOfClass:[NSURL class]])
	{
		// try to massage an NSURL from a string
		NSString* urlString = [inObject description];
		theURL = [NSURL URLWithString:urlString];
		if (nil != theURL)
			return nil;
	}
	else
	{	// it is an NSURL
		theURL = inObject;
	}
	
	return [theURL absoluteString];
}


- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error;
{
	/* Don't attempt to format an empty string. */
	if([string compare:@""] == NSOrderedSame)
	{
		*obj = @"";
		return YES;
	}
	
	NSURL* outURL = [self autoCompletedURLFromString:string];
	*obj = outURL;
	
	if (nil == outURL)
	{
		*error = [NSString stringWithFormat:@"Couldn't make  %@ into a well-formed URL", string];
	}
	
	return outURL != nil;
}

@end