# CopyEnabler

A native iOS jailbreak tweak that removes copy / text-selection / long-press
restrictions inside every `WKWebView` — Safari, in-app browsers, and embedded web
views (GitHub, documentation sites, and so on).

أداة لتجاوز حظر النسخ وتحديد النص وقائمة الضغط المطول داخل جميع صفحات الويب على iOS.

## Compatibility

| | |
|---|---|
| Device tested | iPhone XS Max (A12 Bionic) |
| iOS | 18.7 |
| Jailbreak | RootHide (Relaxin v0.5.5) |
| Architectures | `arm64` + `arm64e` (fat binary) |
| Framework | Theos, Logos, Objective-C, WebKit |

The package is built with `THEOS_PACKAGE_SCHEME=roothide`, so paths live under
`/var/jb`. On a rootless or rootful jailbreak, rebuild with
`THEOS_PACKAGE_SCHEME=rootless` or unset (see `Makefile`).

Binaries are built with the RootHide toolchain (`roothide/theos` plus its
`iOSToolchain`, which uses Apple `ld64`). That linker emits the correct `arm64e`
CPU subtype natively, so no post-link patching of the Mach-O header is needed.
Do not add custom `clang`/`ld` wrapper scripts or rewrite the CPU subtype after
linking: doing so corrupts the binary and the preference bundle then fails to
load with `bad bind opcode 0x00`.

Theos runs `strip -x` and then signs with `ldid -S` as part of the normal build;
that order is correct and must not be bypassed.

There are no third-party dependencies: the only requirement is the substrate
(`mobilesubstrate`). Preferences are stored by a small self-contained class
(`shared/CEPreferences.m`) that reads the mobile user's preference plist directly,
so Cephei is not needed.

## Install

```bash
dpkg -i CopyEnabler_1.0.0_iphoneos-arm64e.deb
```

Or install the `.deb` from the release page with Sileo / Zebra / Filza.
After installing, respring so SpringBoard reloads the preference bundle.

## How it works

The filter in `CopyEnabler.plist` targets `com.apple.UIKit` rather than a single
bundle ID, so the dylib is loaded into every process that links UIKit. The tweak
then hooks `WKWebView` initialisation and attaches a `WKUserScript` to each
`WKWebViewConfiguration`, injected at `WKUserScriptInjectionTimeAtDocumentEnd` for
all frames.

The injected script:

* forces `-webkit-user-select: text !important` and `user-select: text !important`
  on `*`, `*:before` and `*:after`;
* unbinds `contextmenu`, `selectstart`, `dragstart`, `copy`, `cut` and `paste`
  listeners in the capture phase;
* neutralises page-set `oncopy`, `oncut`, `onpaste`, `onselectstart` and
  `oncontextmenu` handlers via `Object.defineProperty`;
* restores `-webkit-touch-callout` so the long-press menu works again.

Every step is wrapped in `try/catch`, and the script is idempotent through a
`window.__CopyEnablerInstalled__` marker. Hooks check for `nil` configuration
objects before injecting, so no web view is ever touched unsafely.

## Preferences

Settings appear under **Settings → CopyEnabler** as a grouped native table view.
The interface and all labels are available in English and Arabic, selected by
**Auto / English / العربية**.

* Main toggles — master switch, text selection, copy & paste, context menu
* Excluded sites — per-domain opt-out, matched on the hostname and its subdomains
* Language
* Developer & diagnostics — share debug logs, reset settings

Diagnostic output is written to `/var/mobile/Library/Logs/CopyEnabler.log` and can
be shared directly from the preferences pane.

## Build from source

```bash
export THEOS=$HOME/theos
make package THEOS_PACKAGE_SCHEME=roothide FINALPACKAGE=1
```

The `.deb` is written to `packages/`.

## Layout

```
Makefile                     tweak build rules
control                      package metadata
CopyEnabler.plist            ElleKit/roothide filter (com.apple.UIKit)
Tweak.xm                     hooking + JavaScript/CSS injection
shared/CEPreferences.[hm]    standalone preference store (no Cephei)
prefs/                       preference bundle (EN/AR UI)
layout/                      PreferenceLoader entry
debs/                        prebuilt package
```

Preferences live in
`/var/mobile/Library/Preferences/com.modyiq.copyenabler.plist`.
