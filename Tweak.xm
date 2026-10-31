#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <Cephei/HBPreferences.h>

static NSString *const kPrefDomain = @"com.modyiq.copyenabler";
static NSString *const kMarker = @"__CopyEnablerInstalled__";

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
            @"ExcludedSites": @[]
        }];
    });
    return p;
}

static NSMutableArray<NSString *> *DebugLog(void) {
    static NSMutableArray *log = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ log = [NSMutableArray array]; });
    return log;
}

static NSString *CELogFilePath(void) {
    return @"/var/mobile/Library/Logs/CopyEnabler.log";
}

static void CELog(NSString *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);
    NSDateFormatter *df = [NSDateFormatter new];
    df.dateFormat = @"HH:mm:ss";
    NSString *line = [NSString stringWithFormat:@"[%@] %@\n", [df stringFromDate:[NSDate date]], msg];
    NSLog(@"[CopyEnabler] %@", msg);

    NSMutableArray *log = DebugLog();
    @synchronized (log) {
        [log addObject:line];
        if (log.count > 500) [log removeObjectAtIndex:0];
    }

    NSString *path = CELogFilePath();
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm createDirectoryAtPath:[path stringByDeletingLastPathComponent]
  withIntermediateDirectories:YES attributes:nil error:NULL];
    if (![fm fileExistsAtPath:path]) {
        [line writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
        return;
    }
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
    if (!fh) return;
    @try {
        [fh seekToEndOfFile];
        [fh writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
    } @catch (NSException *e) {
    }
    [fh closeFile];
}

static NSString *CEBuildScript(void) {
    HBPreferences *prefs = Prefs();
    if (![prefs boolForKey:@"Enabled"]) return nil;

    BOOL selection = [prefs boolForKey:@"EnableSelection"];
    BOOL copyPaste = [prefs boolForKey:@"EnableCopyPaste"];
    BOOL contextMenu = [prefs boolForKey:@"EnableContextMenu"];
    NSArray *excluded = [prefs objectForKey:@"ExcludedSites"] ?: @[];

    NSData *json = [NSJSONSerialization dataWithJSONObject:excluded options:0 error:NULL];
    NSString *excludedJSON = json ? [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding] : @"[]";

    return [NSString stringWithFormat:
        @"(function(){"
         "try{"
         "if(window.%@)return;"
         "var h=(location.hostname||'').toLowerCase();"
         "var ex=%@;"
         "for(var i=0;i<ex.length;i++){var d=String(ex[i]).toLowerCase().replace(/^https?:\\/\\//,'').replace(/\\/.*$/,'');"
         "if(d&&(h===d||h.indexOf('.'+d,h.length-d.length-1)!==-1))return;}"
         "window.%@=true;"
         "var css='*:not(script):not(style),*:before,*:after{'"
         "%@"
         "%@"
         "%@"
         "}';"
         "var s=document.createElement('style');s.type='text/css';s.appendChild(document.createTextNode(css));"
         "(document.head||document.documentElement).appendChild(s);"
         "%@"
         "%@"
         "}catch(e){}"
         "})();",
        kMarker, excludedJSON, kMarker,
        selection ? @"-webkit-user-select:text!important;user-select:text!important;-webkit-touch-callout:default!important;" : @"",
        copyPaste ? @"-webkit-user-modify:read-write!important;" : @"",
        contextMenu ? @"" : @"-webkit-touch-callout:none!important;",
        copyPaste ? @"var ev=['copy','cut','paste','selectstart','dragstart','beforecopy','beforecut','beforepaste'];"
                    "ev.forEach(function(n){window.addEventListener(n,function(e){e.stopPropagation();},true);"
                    "document.addEventListener(n,function(e){e.stopPropagation();},true);});"
                    "var hnd=['oncopy','oncut','onpaste','onselectstart','ondragstart','oncontextmenu','onmousedown','onmouseup'];"
                    "hnd.forEach(function(p){try{Object.defineProperty(document,p,{configurable:true,set:function(){},get:function(){return null;}});"
                    "Object.defineProperty(document.body||document.documentElement,p,{configurable:true,set:function(){},get:function(){return null;}});}catch(e){}});"
                    "try{document.onselectstart=null;document.oncopy=null;document.oncut=null;document.onpaste=null;document.oncontextmenu=null;}catch(e){}"
                    "var st=document.createElement('style');st.type='text/css';"
                    "st.appendChild(document.createTextNode('body,input,textarea,*{-webkit-user-select:text!important;user-select:text!important;-webkit-user-modify:read-write!important;}'));"
                    "(document.head||document.documentElement).appendChild(st);" : @"",
        contextMenu ? @"try{document.oncontextmenu=null;window.oncontextmenu=null;}catch(e){}"
                      "document.addEventListener('contextmenu',function(e){e.stopPropagation();},true);" : @""];
}

static void CEInject(WKWebViewConfiguration *config) {
    if (!config) return;
    NSString *src = CEBuildScript();
    if (!src) return;

    WKUserContentController *ucc = config.userContentController;
    if (!ucc) {
        ucc = [[WKUserContentController alloc] init];
        config.userContentController = ucc;
    }
    if (![ucc isKindOfClass:[WKUserContentController class]]) return;

    for (WKUserScript *existing in ucc.userScripts) {
        if ([existing.source containsString:kMarker]) return;
    }
    WKUserScript *script = [[WKUserScript alloc] initWithSource:src
                                                   injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                                forMainFrameOnly:NO];
    if (!script) return;
    [ucc addUserScript:script];
    CELog(@"injected script into %@", ucc);
}

%hook WKWebView
- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    if (configuration) CEInject(configuration);
    return %orig;
}
- (instancetype)initWithCoder:(NSCoder *)coder {
    id view = %orig;
    @try {
        WKWebViewConfiguration *config = [view valueForKey:@"configuration"];
        if (config) CEInject(config);
    } @catch (NSException *e) {}
    return view;
}
%end

%hook WKWebViewConfiguration
- (instancetype)init {
    id config = %orig;
    if (config) CEInject(config);
    return config;
}
%end

static void CEPrefsChanged(CFNotificationCenterRef center, void *observer, CFNotificationName name,
                           const void *object, CFDictionaryRef userInfo) {
    CELog(@"preferences changed; new pages will use updated rules");
}

%ctor {
    if (!Prefs()) return;
    CELog(@"CopyEnabler loaded (enabled=%@)", [Prefs() boolForKey:@"Enabled"] ? @"YES" : @"NO");
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL,
                                    CEPrefsChanged, CFSTR("com.modyiq.copyenabler/changed"),
                                    NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}
