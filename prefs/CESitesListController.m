#import "CESitesListController.h"
#import "CELocalize.h"
#import <Cephei/HBPreferences.h>
#import <Preferences/PSSpecifier.h>

static NSString *const kPrefDomain = @"com.modyiq.copyenabler";

static HBPreferences *Prefs(void) {
    static HBPreferences *p = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        p = [[HBPreferences alloc] initWithIdentifier:kPrefDomain];
        [p registerDefaults:@{ @"ExcludedSites": @[] }];
    });
    return p;
}

@implementation CESitesListController

- (NSString *)title {
    return CELocalized(@"SITES");
}

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specs = [NSMutableArray array];
        PSSpecifier *group = [PSSpecifier groupSpecifierWithName:CELocalized(@"SECTION_SITES")];
        [group setProperty:CELocalized(@"SITES_FOOT") forKey:@"footerText"];
        [specs addObject:group];

        NSArray *sites = [Prefs() objectForKey:@"ExcludedSites"] ?: @[];
        for (NSString *site in sites) {
            PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:site
                                                               target:self
                                                                  set:NULL
                                                                  get:NULL
                                                               detail:nil
                                                                 cell:PSTitleValueCell
                                                                 edit:nil];
            [spec setProperty:site forKey:@"site"];
            [spec setProperty:@(UITableViewCellEditingStyleDelete) forKey:@"editStyle"];
            [specs addObject:spec];
        }

        PSSpecifier *add = [PSSpecifier preferenceSpecifierNamed:CELocalized(@"ADD_SITE")
                                                          target:self
                                                             set:NULL
                                                             get:NULL
                                                          detail:nil
                                                            cell:PSButtonCell
                                                            edit:nil];
        add.buttonAction = @selector(addSite);
        [specs addObject:add];

        _specifiers = specs;
    }
    return _specifiers;
}

- (void)addSite {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:CELocalized(@"ADD_SITE_TITLE")
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = CELocalized(@"DOMAIN");
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
        field.keyboardType = UIKeyboardTypeURL;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:CELocalized(@"CANCEL")
                                             style:UIAlertActionStyleCancel
                                           handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:CELocalized(@"ADD")
                                             style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction *action) {
        NSString *text = alert.textFields.firstObject.text;
        if (text.length) [self addSiteDomain:text];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)addSiteDomain:(NSString *)domain {
    NSString *clean = [[domain lowercaseString]
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!clean.length) return;

    NSMutableArray *sites = [([Prefs() objectForKey:@"ExcludedSites"] ?: @[]) mutableCopy];
    if (![sites containsObject:clean]) {
        [sites addObject:clean];
        [Prefs() setObject:sites forKey:@"ExcludedSites"];
        [self notifyChange];
        [self reloadSpecifiers];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)style
                                            forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (style != UITableViewCellEditingStyleDelete) return;
    PSSpecifier *spec = [self specifierAtIndexPath:indexPath];
    NSString *site = [spec propertyForKey:@"site"];
    if (!site) return;

    NSMutableArray *sites = [([Prefs() objectForKey:@"ExcludedSites"] ?: @[]) mutableCopy];
    [sites removeObject:site];
    [Prefs() setObject:sites forKey:@"ExcludedSites"];
    [self notifyChange];
    [self reloadSpecifiers];
}

- (void)notifyChange {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         CFSTR("com.modyiq.copyenabler/changed"), NULL, NULL, YES);
}

@end
