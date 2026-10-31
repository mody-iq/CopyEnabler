export TARGET = iphone:clang:16.5:14.0
export ARCHS = arm64 arm64e

THEOS_PACKAGE_SCHEME ?= roothide

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CopyEnabler

CopyEnabler_FILES = Tweak.xm
CopyEnabler_CFLAGS = -fobjc-arc
CopyEnabler_FRAMEWORKS = UIKit WebKit

include $(THEOS_MAKE_PATH)/tweak.mk

# This workspace is setgid, so staged directories inherit mode 2755 and dpkg
# rejects the control directory. Drop the inherited bit only; file contents and
# signatures are untouched.
before-package::
	$(ECHO_NOTHING)chmod -R g-s "$(THEOS_STAGING_DIR)" 2>/dev/null || true$(ECHO_END)
