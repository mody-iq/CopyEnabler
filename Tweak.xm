#import <WebKit/WebKit.h>

#define CE_MARKER "__CopyEnabler__"

static NSString *CEScript(void) {
    return @"(function(){"
    "try{"
    "if(window." CE_MARKER ")return;"
    "window." CE_MARKER "=true;"

    "var css='*,*::before,*::after{"
    "-webkit-user-select:text!important;user-select:text!important;"
    "-webkit-touch-callout:default!important;"
    "}';"
    "var s=document.createElement('style');"
    "s.type='text/css';"
    "s.appendChild(document.createTextNode(css));"
    "(document.head||document.documentElement).appendChild(s);"

    "var ev=['contextmenu','selectstart','dragstart','copy','cut','paste',"
    "'beforecopy','beforecut','beforepaste'];"
    "var stop=function(e){e.stopPropagation();};"
    "for(var i=0;i<ev.length;i++){"
    "try{document.addEventListener(ev[i],stop,true);}catch(e){}"
    "try{window.addEventListener(ev[i],stop,true);}catch(e){}"
    "}"

    "var props=['oncopy','oncut','onpaste','onselectstart','ondragstart','oncontextmenu'];"
    "var targets=[document,window];"
    "if(document.body)targets.push(document.body);"
    "if(document.documentElement)targets.push(document.documentElement);"
    "for(var j=0;j<props.length;j++){"
    "for(var k=0;k<targets.length;k++){"
    "try{Object.defineProperty(targets[k],props[j],{configurable:true,"
    "get:function(){return null;},set:function(){}});}catch(e){}"
    "}"
    "}"
    "}catch(e){}"
    "})();";
}

static void CEInject(WKWebViewConfiguration *config) {
    if (!config) return;
    @try {
        WKUserContentController *ucc = config.userContentController;
        if (!ucc) {
            ucc = [[WKUserContentController alloc] init];
            if (!ucc) return;
            config.userContentController = ucc;
        }
        for (WKUserScript *existing in ucc.userScripts) {
            if ([existing.source containsString:@CE_MARKER]) return;
        }
        WKUserScript *script = [[WKUserScript alloc] initWithSource:CEScript()
                                                       injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                                    forMainFrameOnly:NO];
        if (script) [ucc addUserScript:script];
    } @catch (NSException *e) {
    }
}

%group CEHooks

%hook WKWebView

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    CEInject(configuration);
    return %orig;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    id view = %orig;
    @try {
        CEInject([view valueForKey:@"configuration"]);
    } @catch (NSException *e) {
    }
    return view;
}

%end

%end

// WebKit is not linked into every process that loads UIKit, and hooking a class
// that does not exist crashes. Only install the hooks where WKWebView is real.
%ctor {
    @try {
        @autoreleasepool {
            if (!objc_getClass("WKWebView")) return;
            %init(CEHooks);
        }
    } @catch (NSException *e) {
    }
}
