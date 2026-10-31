#import "CELocalize.h"
#import "CEPreferences.h"

static NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *CETable(void) {
    static NSDictionary *table = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        table = @{
            @"en": @{
                @"TITLE": @"CopyEnabler Settings",
                @"SECTION_MAIN": @"Main Toggles",
                @"ENABLED": @"Enable Tweak",
                @"ENABLED_FOOT": @"Master switch for all CopyEnabler features.",
                @"SELECTION": @"Unrestrict Text Selection",
                @"SELECTION_FOOT": @"Allow selecting and highlighting text on any page.",
                @"COPYPASTE": @"Unrestrict Copy & Paste",
                @"COPYPASTE_FOOT": @"Remove page handlers that block copy, cut and paste.",
                @"CONTEXTMENU": @"Unrestrict Context Menu",
                @"CONTEXTMENU_FOOT": @"Restore the long-press menu on protected pages.",
                @"SECTION_SITES": @"Excluded Sites",
                @"SITES": @"Excluded Sites",
                @"SITES_FOOT": @"CopyEnabler is disabled on these domains.",
                @"SECTION_LANG": @"Language",
                @"LANG": @"Language",
                @"SECTION_DEV": @"Developer & Diagnostics",
                @"SHARE_LOG": @"Share Debug Logs",
                @"RESET": @"Reset Settings",
                @"RESET_DONE": @"Settings restored to defaults.",
                @"ADD_SITE": @"Add Site",
                @"ADD_SITE_TITLE": @"Add Excluded Site",
                @"DOMAIN": @"Domain",
                @"CANCEL": @"Cancel",
                @"ADD": @"Add",
                @"EMPTY": @"No excluded sites",
                @"LOG_TITLE": @"CopyEnabler Debug Log"
            },
            @"ar": @{
                @"TITLE": @"إعدادات كاسر حظر النسخ",
                @"SECTION_MAIN": @"مفاتيح التحكم الأساسية",
                @"ENABLED": @"مفتاح تفعيل الأداة الرئيسي",
                @"ENABLED_FOOT": @"المفتاح الرئيسي لجميع ميزات الأداة.",
                @"SELECTION": @"تفعيل تظليل وتحديد النصوص",
                @"SELECTION_FOOT": @"السماح بتحديد وتظليل النص في أي صفحة.",
                @"COPYPASTE": @"تفعيل النسخ واللصق",
                @"COPYPASTE_FOOT": @"إزالة أوامر الصفحة التي تمنع النسخ والقص واللصق.",
                @"CONTEXTMENU": @"تفعيل قائمة الضغط المطول",
                @"CONTEXTMENU_FOOT": @"استعادة قائمة الضغط المطول في الصفحات المحمية.",
                @"SECTION_SITES": @"المواقع المستثناة إن وجدت",
                @"SITES": @"المواقع المستثناة",
                @"SITES_FOOT": @"يتم تعطيل الأداة على هذه النطاقات.",
                @"SECTION_LANG": @"اللغة",
                @"LANG": @"اللغة",
                @"SECTION_DEV": @"المطور والتشخيص",
                @"SHARE_LOG": @"مشاركة سجل التتبع",
                @"RESET": @"إعادة ضبط الإعدادات",
                @"RESET_DONE": @"تمت استعادة الإعدادات الافتراضية.",
                @"ADD_SITE": @"إضافة موقع",
                @"ADD_SITE_TITLE": @"إضافة موقع مستثنى",
                @"DOMAIN": @"النطاق",
                @"CANCEL": @"إلغاء",
                @"ADD": @"إضافة",
                @"EMPTY": @"لا توجد مواقع مستثناة",
                @"LOG_TITLE": @"سجل تتبع CopyEnabler"
            }
        };
    });
    return table;
}

NSString *CELanguageCode(void) {
    [CEPreferences.shared registerDefaults:@{ @"Language": @"auto" }];
    NSString *selected = [CEPreferences.shared objectForKey:@"Language"] ?: @"auto";
    if ([selected isEqualToString:@"auto"]) {
        NSString *system = [NSLocale preferredLanguages].firstObject ?: @"en";
        return [system hasPrefix:@"ar"] ? @"ar" : @"en";
    }
    return selected;
}

NSString *CELocalized(NSString *key) {
    NSString *code = CELanguageCode();
    NSDictionary *dict = CETable()[code] ?: CETable()[@"en"];
    return dict[key] ?: CETable()[@"en"][key] ?: key;
}
