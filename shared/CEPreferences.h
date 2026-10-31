#import <Foundation/Foundation.h>

/// Standalone preference store. Replaces Cephei's HBPreferences so the tweak has
/// no external dependency: values live in the mobile user's preference plist and
/// are re-read whenever a Darwin notification announces a change.
@interface CEPreferences : NSObject

+ (instancetype)shared;

- (void)registerDefaults:(NSDictionary<NSString *, id> *)defaults;

- (id)objectForKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;
- (NSArray *)arrayForKey:(NSString *)key;

- (void)setObject:(id)value forKey:(NSString *)key;
- (void)setBool:(BOOL)value forKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;

- (void)reload;

@end
