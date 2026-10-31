export TARGET = iphone:clang:16.5:14.0
export ARCHS = arm64 arm64e

THEOS_PACKAGE_SCHEME ?= roothide

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CopyEnabler

CopyEnabler_FILES = Tweak.xm
CopyEnabler_CFLAGS = -fobjc-arc
CopyEnabler_FRAMEWORKS = UIKit WebKit
CopyEnabler_EXTRA_FRAMEWORKS = Cephei

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += prefs
include $(THEOS_MAKE_PATH)/aggregate.mk

# Workspace is setgid; strip the inherited bit so dpkg-deb accepts the stage.
before-package::
	$(ECHO_NOTHING)chmod -R g-s "$(THEOS_STAGING_DIR)" 2>/dev/null || true$(ECHO_END)
