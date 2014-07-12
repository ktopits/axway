//
//  JsonUtils.m
//

#import "JsonUtils.h"


@implementation jsonUtils

+ (NSString*)encode:(id)object
{
    NSError* error = nil;
    NSString* json = [jsonUtils encode:object error:&error];
    
    if (json == nil) {
        if( error != nil ) {
            NSLog(@"unable to encode to JSON: %@", [error localizedDescription]);
        } else {
            NSLog(@"unable to encode to JSON: %@", object);
        }
    }
    
    return json;
}

+ (NSString*)encode:(id)object error:(NSError**)error
{
    NSData* dataObject = [jsonUtils encodeAsData:object error:error];
    if (dataObject != nil) {
        return [[NSString alloc] initWithData:dataObject
                                     encoding:NSUTF8StringEncoding];
    } else {
        return nil;
    }
}

+ (NSData*)encodeAsData:(id)object
{
    NSError* error = nil;
    NSData* data = [jsonUtils encodeAsData:object error:&error];
    if (data == nil) {
        if (error != nil) {
            NSLog(@"unable to encode to JSON data: %@", [error localizedDescription]);
        } else {
            NSLog(@"unable to encode to JSON data: %@", object);
        }
    }
    
    return data;
}

+ (NSData*)encodeAsData:(id)object error:(NSError**)error
{
    NSJSONWritingOptions writingOptions = 0;
    
#if (TARGET_IPHONE_SIMULATOR)
    writingOptions = NSJSONWritingPrettyPrinted;
#endif
    
    NSData* jsonAsData = [NSJSONSerialization dataWithJSONObject:object
                                           options:writingOptions
                                             error:error];
    if( jsonAsData == nil ) {
        NSLog( @"error: unable to encode as json. %@", object);
        if( *error ) {
            NSLog( @"error: %@", [*error localizedDescription]);
        } else {
            NSLog( @"no error given by NSJSONSerialization");
        }
    }
    
    return jsonAsData;
}

+ (id)decode:(NSString*)json
{
    NSError* error = nil;
    id objects = [jsonUtils decode:json error:&error];
    if( objects == nil || error != nil ) {
        if( error != nil ) {
            NSLog( @"JSON parse error: %@", [error localizedDescription]);
        } else {
            NSLog( @"JSON parse failed. no error given. %@", json );
        }
        
        return nil;
    } else {
        return objects;
    }
}

+ (id)decode:(NSString*)json error:(NSError**)error
{
    NSData* jsonAsData = [json dataUsingEncoding:NSUTF8StringEncoding];
    return [jsonUtils decodeData:jsonAsData error:error];
}

+ (id)decodeData:(NSData*)jsonData
{
    NSError* error = nil;
    id objects = [jsonUtils decodeData:jsonData error:&error];
    if( objects == nil || error != nil ) {
        if( error != nil ) {
            NSLog( @"JSON parse error: %@", [error localizedDescription]);
        } else {
            NSLog( @"JSON parse failed. no error given. %@", jsonData );
        }
    }
    
    return objects;
}

+ (id)decodeData:(NSData*)jsonData error:(NSError**)error
{
    return [NSJSONSerialization JSONObjectWithData:jsonData
                                           options:NSJSONReadingMutableContainers
                                             error:error];
}

@end
