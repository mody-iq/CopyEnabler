export TARGET = iphone:clang:16.5:14.0
export ARCHS = arm64 arm64e

THEOS_PACKAGE_SCHEME ?= roothide

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CopyEnabler

CopyEnabler_FILES = Tweak.xm shared/CEPreferences.m
CopyEnabler_CFLAGS = -fobjc-arc -I$(THEOS_PROJECT_DIR)/shared
CopyEnabler_FRAMEWORKS = UIKit WebKit

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += prefs
include $(THEOS_MAKE_PATH)/aggregate.mk

# This workspace is setgid, so staged directories inherit mode 2755 and dpkg
# rejects the control directory. Drop the inherited bit only; file contents and
# signatures are untouched.
before-package::
	$(ECHO_NOTHING)chmod -R g-s "$(THEOS_STAGING_DIR)" 2>/dev/null || true$(ECHO_END)
