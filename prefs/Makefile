export TARGET = iphone:clang:16.5:14.0
export ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = CopyEnablerPrefs

CopyEnablerPrefs_FILES = CERootListController.m CESitesListController.m CELocalize.m $(THEOS_PROJECT_DIR)/shared/CEPreferences.m
CopyEnablerPrefs_FRAMEWORKS = UIKit
CopyEnablerPrefs_PRIVATE_FRAMEWORKS = Preferences
CopyEnablerPrefs_INSTALL_PATH = /Library/PreferenceBundles
CopyEnablerPrefs_CFLAGS = -fobjc-arc -I$(THEOS_PROJECT_DIR)/shared

include $(THEOS_MAKE_PATH)/bundle.mk
