#import "CEPreferences.h"

NSString *const CEPreferencesDomain = @"com.modyiq.copyenabler";
NSString *const CEPreferencesChangedNotification = @"com.modyiq.copyenabler/changed";

@interface CEPreferences ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *values;
@property (nonatomic, strong) NSDictionary<NSString *, id> *defaults;
@end

static void CEPreferencesChangedCallback(CFNotificationCenterRef center, void *observer,
                                         CFNotificationName name, const void *object,
                                         CFDictionaryRef userInfo) {
    [(__bridge CEPreferences *)observer reload];
}

@implementation CEPreferences

+ (instancetype)shared {
    static CEPreferences *shared = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ shared = [[CEPreferences alloc] init]; });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _defaults = @{};
        [self reload];
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        (__bridge void *)self,
                                        CEPreferencesChangedCallback,
                                        (__bridge CFStringRef)CEPreferencesChangedNotification,
                                        NULL,
                                        CFNotificationSuspensionBehaviorDeliverImmediately);
    }
    return self;
}

- (NSString *)plistPath {
    return [@"/var/mobile/Library/Preferences" stringByAppendingPathComponent:
            [CEPreferencesDomain stringByAppendingPathExtension:@"plist"]];
}

- (void)reload {
    NSDictionary *disk = [NSDictionary dictionaryWithContentsOfFile:[self plistPath]];
    @synchronized (self) {
        self.values = disk ? [disk mutableCopy] : [NSMutableDictionary dictionary];
    }
}

- (void)registerDefaults:(NSDictionary<NSString *, id> *)defaults {
    if (!defaults.count) return;
    NSMutableDictionary *merged = [defaults mutableCopy];
    @synchronized (self) {
        [merged addEntriesFromDictionary:self.defaults];
    }
    self.defaults = merged;
}

- (id)objectForKey:(NSString *)key {
    if (!key) return nil;
    id value = nil;
    @synchronized (self) { value = self.values[key]; }
    return value ?: self.defaults[key];
}

- (BOOL)boolForKey:(NSString *)key {
    id value = [self objectForKey:key];
    return [value respondsToSelector:@selector(boolValue)] ? [value boolValue] : NO;
}

- (NSArray *)arrayForKey:(NSString *)key {
    id value = [self objectForKey:key];
    return [value isKindOfClass:[NSArray class]] ? value : @[];
}

- (void)setObject:(id)value forKey:(NSString *)key {
    if (!key) return;
    @synchronized (self) {
        if (value) self.values[key] = value;
        else [self.values removeObjectForKey:key];
    }
    [self persist];
    [self notifyChange];
}

- (void)setBool:(BOOL)value forKey:(NSString *)key {
    [self setObject:@(value) forKey:key];
}

- (void)removeObjectForKey:(NSString *)key {
    [self setObject:nil forKey:key];
}

- (void)persist {
    NSDictionary *snapshot;
    @synchronized (self) { snapshot = [self.values copy]; }
    NSString *path = [self plistPath];
    [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent]
                             withIntermediateDirectories:YES
                                              attributes:nil
                                                   error:NULL];
    [snapshot writeToFile:path atomically:YES];
}

- (void)notifyChange {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         (__bridge CFStringRef)CEPreferencesChangedNotification,
                                         NULL, NULL, YES);
}

@end
