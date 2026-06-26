#include <substrate.h>
#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>

void InitializeLogin();
void RenderLogin();

%hook UIWindow
- (void)makeKeyAndVisible {
    %orig;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        InitializeLogin();
    });
}
%end

%hook CAMetalLayer
- (void)presentDrawable:(id)drawable {
    RenderLogin();
    %orig;
}
%end

%ctor {
    NSLog(@"[OneStateLogin] Loaded");
}
