#import <Foundation/Foundation.h>

typedef void (^iDebounceBlock)();

@interface iDebounce : NSObject

+(instancetype)sharedInstance;

+(void)debounce:( iDebounceBlock )block withIdentifier:(NSString *)identifier wait:( NSTimeInterval )seconds;

@end
