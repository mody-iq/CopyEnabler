# CopyEnabler — project memory

Jailbreak tweak that unrestricts text selection / copy-paste / long-press menus in
every `WKWebView` on iOS. Repo: `mody-iq/CopyEnabler` (was `CopyEnbler`, GitHub
redirects old URLs). Branch: `main`.

## Build (must be run from repo root)
```
THEOS=$HOME/theos-rh THEOS_PACKAGE_SCHEME=roothide FINALPACKAGE=1 \
  make package FAKEROOT=/home/openhands/nofakeroot.sh
```
Produces `packages/com.modyiq.copyenabler_<ver>_iphoneos-arm64e.deb`.

## Environment quirks (Linux container, non-Apple host)
* Theos root is `~/theos-rh` (roothide fork). SDKs: iPhoneOS16.5, iPhoneOS18.6.
* `~/theos-rh/toolchain/.../bin/clang` is a **wrapper script** that routes Darwin
  links through `-fuse-ld=lld` and repairs the arm64e CPU subtype via
  `macho_arch_patch.py` (lld emits `ARM64_ALL`; iOS wants `ARM64E`). Theos passes
  `-target arm64e-apple-ios14.0`, not `-arch`, so the wrapper detects that form.
* `fakeroot` daemon hangs here → `FAKEROOT=/home/openhands/nofakeroot.sh` (no-op).
  `dm.pl` then fakes ownership because the build runs as non-root.
* `rsync` is required by bundle staging and was missing; installed via apt.
* `/workspace` is **setgid**. Staged dirs inherit `2755`, and `dpkg-deb` rejects a
  `DEBIAN` dir with the setgid bit ("bad permissions 2755"). The Makefile has a
  `before-package::` hook running `chmod -R g-s "$(THEOS_STAGING_DIR)"`.
* Editing Makefiles with heredocs loses tabs (recipe lines need real tabs). Use a
  Python writer or `printf` and verify with `cat -A`.

## Tweak design
* Filter `CopyEnabler.plist` uses `{ Filter = { Bundles = ( "com.apple.UIKit" ); }; }`
  — a documented roothide/ElleKit trick so the dylib loads into every app that
  links UIKit, i.e. system-wide `WKWebView` coverage (Safari, in-app browsers).
* Hook `WKWebView -initWithFrame:configuration:`, `-initWithCoder:`, and
  `WKWebViewConfiguration -init`, then add a `WKUserScript` at
  `WKUserScriptInjectionTimeAtDocumentEnd`, `forMainFrameOnly:NO`.
* Injected JS is idempotent via a `window.__CopyEnablerInstalled__` marker and
  checks a hostname exclusion list before applying.
* Preferences are stored by `shared/CEPreferences.[hm]`, a self-contained
  replacement for Cephei's `HBPreferences` (compiled into both the tweak and the
  bundle). It reads/writes `/var/mobile/Library/Preferences/com.modyiq.copyenabler.plist`
  directly and syncs over the Darwin notification
  `com.modyiq.copyenabler/changed`. `control` therefore depends only on
  `mobilesubstrate` — Cephei is NOT required. Both Makefiles pass
  `-I$(THEOS_PROJECT_DIR)/shared` and list the shared .m in their FILES.
* The UI is a PreferenceLoader bundle with a hand-built `PSListController`
  (EN/AR strings live in `prefs/CELocalize.m`).
* Do **not** use `@finally` in `Tweak.xm`: Logos compiles it as ObjC++ and it pulls
  in `std::terminate` / `__cxa_begin_catch`, which fail to link here.

## Verification habit
The injected JS is a string built with `stringWithFormat:`. It is easy to emit
invalid JS (e.g. CSS placed outside the string quotes). Extract the template and
`node --check` both the all-on and all-off substitution branches before shipping.
