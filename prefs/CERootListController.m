#import "CERootListController.h"
#import "CESitesListController.h"
#import "CELocalize.h"
#import <Cephei/HBPreferences.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSListItemsController.h>

static NSString *const kPrefDomain = @"com.modyiq.copyenabler";

static HBPreferences *Prefs(void) {
    static HBPreferences *p = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        p = [[HBPreferences alloc] initWithIdentifier:kPrefDomain];
        [p registerDefaults:@{
            @"Enabled": @YES,
            @"EnableSelection": @YES,
            @"EnableCopyPaste": @YES,
            @"EnableContextMenu": @YES,
            @"ExcludedSites": @[],
            @"Language": @"auto"
        }];
    });
    return p;
}

@implementation CERootListController

- (NSString *)title {
    return CELocalized(@"TITLE");
}

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specs = [NSMutableArray array];

        PSSpecifier *group = [PSSpecifier groupSpecifierWithName:CELocalized(@"SECTION_MAIN")];
        [specs addObject:group];
        [specs addObject:[self switchSpecifier:CELocalized(@"ENABLED") key:@"Enabled"]];

        PSSpecifier *sel = [self switchSpecifier:CELocalized(@"SELECTION") key:@"EnableSelection"];
        [sel setProperty:CELocalized(@"SELECTION_FOOT") forKey:@"footerText"];
        [specs addObject:sel];

        PSSpecifier *cp = [self switchSpecifier:CELocalized(@"COPYPASTE") key:@"EnableCopyPaste"];
        [cp setProperty:CELocalized(@"COPYPASTE_FOOT") forKey:@"footerText"];
        [specs addObject:cp];

        PSSpecifier *cm = [self switchSpecifier:CELocalized(@"CONTEXTMENU") key:@"EnableContextMenu"];
        [cm setProperty:CELocalized(@"CONTEXTMENU_FOOT") forKey:@"footerText"];
        [specs addObject:cm];

        PSSpecifier *sitesGroup = [PSSpecifier groupSpecifierWithName:CELocalized(@"SECTION_SITES")];
        [sitesGroup setProperty:CELocalized(@"SITES_FOOT") forKey:@"footerText"];
        [specs addObject:sitesGroup];
        PSSpecifier *sites = [PSSpecifier preferenceSpecifierNamed:CELocalized(@"SITES")
                                                            target:self
                                                               set:NULL
                                                               get:NULL
                                                            detail:[CESitesListController class]
                                                              cell:PSLinkCell
                                                              edit:nil];
        [specs addObject:sites];

        PSSpecifier *langGroup = [PSSpecifier groupSpecifierWithName:CELocalized(@"SECTION_LANG")];
        [specs addObject:langGroup];
        PSSpecifier *lang = [PSSpecifier preferenceSpecifierNamed:CELocalized(@"LANG")
                                                           target:self
                                                              set:@selector(setLanguage:forSpecifier:)
                                                              get:@selector(getLanguage:)
                                                           detail:[PSListItemsController class]
                                                             cell:PSLinkListCell
                                                             edit:nil];
        [lang setProperty:@[@"auto", @"en", @"ar"] forKey:@"validValues"];
        [lang setProperty:@[@"Auto", @"English", @"العربية"] forKey:@"validTitles"];
        [lang setProperty:@"Language" forKey:@"key"];
        [specs addObject:lang];

        PSSpecifier *devGroup = [PSSpecifier groupSpecifierWithName:CELocalized(@"SECTION_DEV")];
        [specs addObject:devGroup];
        PSSpecifier *share = [PSSpecifier preferenceSpecifierNamed:CELocalized(@"SHARE_LOG")
                                                            target:self
                                                               set:NULL
                                                               get:NULL
                                                            detail:nil
                                                              cell:PSButtonCell
                                                              edit:nil];
        share.buttonAction = @selector(shareLogs);
        [specs addObject:share];

        PSSpecifier *reset = [PSSpecifier preferenceSpecifierNamed:CELocalized(@"RESET")
                                                            target:self
                                                               set:NULL
                                                               get:NULL
                                                            detail:nil
                                                              cell:PSButtonCell
                                                              edit:nil];
        reset.buttonAction = @selector(resetSettings);
        [specs addObject:reset];

        _specifiers = specs;
    }
    return _specifiers;
}

- (PSSpecifier *)switchSpecifier:(NSString *)name key:(NSString *)key {
    PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:name
                                                       target:self
                                                          set:@selector(setPreference:forSpecifier:)
                                                          get:@selector(getPreference:)
                                                       detail:nil
                                                         cell:PSSwitchCell
                                                         edit:nil];
    [spec setProperty:key forKey:@"key"];
    return spec;
}

- (id)getPreference:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    return @([Prefs() boolForKey:key]);
}

- (void)setPreference:(id)value forSpecifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    [Prefs() setBool:[value boolValue] forKey:key];
    [self notifyChange];
}

- (id)getLanguage:(PSSpecifier *)specifier {
    return [Prefs() objectForKey:@"Language"] ?: @"auto";
}

- (void)setLanguage:(id)value forSpecifier:(PSSpecifier *)specifier {
    [Prefs() setObject:value forKey:@"Language"];
    [self notifyChange];
    [self reloadSpecifiers];
}

- (void)notifyChange {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         CFSTR("com.modyiq.copyenabler/changed"), NULL, NULL, YES);
}

- (void)shareLogs {
    NSString *log = [self readLogFile];
    UIActivityViewController *vc = [[UIActivityViewController alloc]
        initWithActivityItems:@[log] applicationActivities:nil];
    if (vc.popoverPresentationController) {
        vc.popoverPresentationController.sourceView = self.view;
    }
    [self presentViewController:vc animated:YES completion:nil];
}

- (NSString *)readLogFile {
    NSMutableArray *lines = [NSMutableArray array];
    for (NSString *path in @[@"/var/mobile/Library/Logs/CopyEnabler.log",
                             @"/tmp/CopyEnabler.log"]) {
        NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
        if (content.length) [lines addObject:content];
    }
    return lines.count ? [lines componentsJoinedByString:@"\n"] : @"CopyEnabler: no log entries captured yet.";
}

- (void)resetSettings {
    for (NSString *key in @[@"Enabled", @"EnableSelection", @"EnableCopyPaste",
                            @"EnableContextMenu", @"ExcludedSites", @"Language"]) {
        [Prefs() removeObjectForKey:key];
    }
    [self notifyChange];
    [self reloadSpecifiers];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:CELocalized(@"RESET_DONE")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
