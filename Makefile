THEOS_DEVICE_IP = 192.168.1.1
ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = OneStateLogin

OneStateLogin_FILES = $(wildcard *.mm) $(wildcard imgui/*.cpp) $(wildcard imgui/*.mm)
OneStateLogin_CFLAGS = -fobjc-arc -std=c++17 -O2
OneStateLogin_LDFLAGS = -framework Foundation -framework UIKit -framework Metal -framework MetalKit -framework QuartzCore -framework CoreGraphics -framework Security -lobjc -lc++
OneStateLogin_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/library.mk
