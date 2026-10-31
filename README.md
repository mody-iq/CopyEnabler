# CopyEnabler

Unrestricts text selection, copy, paste and long-press menus in every `WKWebView`
on iOS: Safari, in-app browsers, `SFSafariViewController`, and sites such as
GitHub that block copying.

There are no settings and no configuration. Install, respring, done.

## Install

Download the latest `.deb` from the
[Releases page](https://github.com/mody-iq/CopyEnabler/releases) and install it
with your package manager (Sileo, Zebra, or `dpkg -i`). Respring afterwards.

Built for **iOS 18.7** on **RootHide (Relaxin)** with `arm64` + `arm64e`.

## How it works

The tweak injects a single JavaScript `WKUserScript` into each `WKWebView`
configuration at `WKUserScriptInjectionTimeAtDocumentEnd`. That script:

- forces `user-select: text` on all elements via CSS;
- stops propagation of `contextmenu`, `selectstart`, `dragstart`, `copy`, `cut`
  and `paste` in the capture phase;
- neutralises the `oncopy` / `oncut` / `onpaste` / `onselectstart` /
  `oncontextmenu` handlers that sites install to block copying.

The script is idempotent: it marks the page so repeated injections are skipped.

## Source layout

    Tweak.xm            the whole tweak (single file)
    CopyEnabler.plist   MobileSubstrate filter
    Makefile            Theos build
    control             package metadata

## Building

Build with the RootHide toolchain (`roothide/theos` plus its `iOSToolchain`,
which uses Apple `ld64`), because that linker emits the correct `arm64e` CPU
subtype natively. Do not add `clang`/`ld` wrapper scripts or rewrite the CPU
subtype after linking: that corrupts the fixup data and the tweak then fails to
load with `bad bind opcode 0x00`.

    export THEOS=~/theos-rh
    export PATH=$THEOS/toolchain/linux/iphone/bin:$PATH
    THEOS_PACKAGE_SCHEME=roothide make package

Theos runs `strip -x` and then signs with `ldid -S`; that order is correct and
must not be bypassed.

## License

MIT
