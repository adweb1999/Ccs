#include <imgui/imgui.h>
#include <imgui/imgui_impl_metal.h>
#include <Metal/Metal.h>
#include <MetalKit/MetalKit.h>
#include <UIKit/UIKit.h>
#include <Foundation/Foundation.h>
#include <objc/runtime.h>
#include <string>

// ========== CONFIG ==========
#define API_URL "https://your-api-server.com/api/login"
#define APP_NAME "OneState"

// ========== LOGIN STATE ==========
bool g_LoginVisible = true;  // ALWAYS VISIBLE until login success
bool g_LoginSuccess = false;
bool g_IsLoading = false;
char g_ErrorMsg[256] = "";

// Input fields
char g_Username[64] = "";
char g_Password[64] = "";

// Device ID
char g_DeviceID[64] = "";

// Colors
ImVec4 g_Color_BG = ImVec4(0.05f, 0.05f, 0.08f, 1.0f);
ImVec4 g_Color_Primary = ImVec4(0.0f, 0.6f, 1.0f, 1.0f);
ImVec4 g_Color_Error = ImVec4(1.0f, 0.2f, 0.2f, 1.0f);
ImVec4 g_Color_Success = ImVec4(0.2f, 1.0f, 0.4f, 1.0f);
ImVec4 g_Color_White = ImVec4(1.0f, 1.0f, 1.0f, 1.0f);
ImVec4 g_Color_Gray = ImVec4(0.5f, 0.5f, 0.5f, 1.0f);

// Metal
id<MTLDevice> g_Device = nil;
id<MTLCommandQueue> g_CommandQueue = nil;
CAMetalLayer* g_MetalLayer = nil;

// ========== GET DEVICE ID ==========
void GetDeviceID() {
    NSString* uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    strncpy(g_DeviceID, [uuid UTF8String], sizeof(g_DeviceID) - 1);
}

// ========== API LOGIN ==========
bool APILogin(const char* username, const char* password, const char* deviceID) {
    // TODO: Replace with your actual API
    // Example API call:
    /*
    NSURL* url = [NSURL URLWithString:@API_URL];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSDictionary* body = @{
        @"username": @(username),
        @"password": @(password),
        @"device_id": @(deviceID)
    };

    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    [request setHTTPBody:jsonData];

    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

    return [json[@"success"] boolValue];
    */

    // For testing - replace with real API
    return (strcmp(username, "admin") == 0 && strcmp(password, "123456") == 0);
}

// ========== STYLE ==========
void SetupStyle() {
    ImGuiStyle& style = ImGui::GetStyle();
    ImVec4* colors = style.Colors;

    colors[ImGuiCol_Text] = g_Color_White;
    colors[ImGuiCol_TextDisabled] = g_Color_Gray;
    colors[ImGuiCol_WindowBg] = g_Color_BG;
    colors[ImGuiCol_ChildBg] = g_Color_BG;
    colors[ImGuiCol_PopupBg] = g_Color_BG;
    colors[ImGuiCol_Border] = g_Color_Primary;
    colors[ImGuiCol_FrameBg] = ImVec4(0.1f, 0.1f, 0.15f, 1.0f);
    colors[ImGuiCol_FrameBgHovered] = ImVec4(0.15f, 0.15f, 0.2f, 1.0f);
    colors[ImGuiCol_FrameBgActive] = ImVec4(0.2f, 0.2f, 0.3f, 1.0f);
    colors[ImGuiCol_TitleBg] = g_Color_Primary;
    colors[ImGuiCol_TitleBgActive] = g_Color_Primary;
    colors[ImGuiCol_Button] = g_Color_Primary;
    colors[ImGuiCol_ButtonHovered] = ImVec4(0.0f, 0.7f, 1.0f, 1.0f);
    colors[ImGuiCol_ButtonActive] = ImVec4(0.0f, 0.8f, 1.0f, 1.0f);
    colors[ImGuiCol_CheckMark] = g_Color_Primary;
    colors[ImGuiCol_SliderGrab] = g_Color_Primary;
    colors[ImGuiCol_SliderGrabActive] = g_Color_Primary;

    style.WindowPadding = ImVec2(20, 20);
    style.FramePadding = ImVec2(12, 8);
    style.ItemSpacing = ImVec2(10, 10);
    style.WindowRounding = 0.0f;  // No rounding for fullscreen
    style.ChildRounding = 8.0f;
    style.FrameRounding = 8.0f;
    style.ButtonRounding = 8.0f;
}

// ========== FULLSCREEN LOGIN ==========
void RenderFullscreenLogin() {
    ImGuiIO& io = ImGui::GetIO();

    // FULLSCREEN WINDOW - NO ESCAPE
    ImGui::SetNextWindowPos(ImVec2(0, 0), ImGuiCond_Always);
    ImGui::SetNextWindowSize(ImVec2(io.DisplaySize.x, io.DisplaySize.y), ImGuiCond_Always);

    ImGui::Begin("##LoginFullscreen", nullptr,
        ImGuiWindowFlags_NoTitleBar |
        ImGuiWindowFlags_NoResize |
        ImGuiWindowFlags_NoMove |
        ImGuiWindowFlags_NoScrollbar |
        ImGuiWindowFlags_NoScrollWithMouse |
        ImGuiWindowFlags_NoCollapse |
        ImGuiWindowFlags_NoSavedSettings |
        ImGuiWindowFlags_NoBringToFrontOnFocus |
        ImGuiWindowFlags_NoNavFocus);

    // Center content vertically
    float contentHeight = 500.0f;
    float startY = (io.DisplaySize.y - contentHeight) / 2;

    ImGui::SetCursorPosY(startY);

    // Title
    ImGui::PushFont(ImGui::GetFont());
    ImGui::SetWindowFontScale(2.0f);
    ImVec2 titleSize = ImGui::CalcTextSize(APP_NAME);
    ImGui::SetCursorPosX((io.DisplaySize.x - titleSize.x * 2.0f) / 2);
    ImGui::TextColored(g_Color_Primary, APP_NAME);
    ImGui::SetWindowFontScale(1.0f);
    ImGui::PopFont();

    // Subtitle
    ImGui::SetCursorPosX((io.DisplaySize.x - ImGui::CalcTextSize("Login Required").x) / 2);
    ImGui::TextColored(g_Color_Gray, "Login Required");
    ImGui::Dummy(ImVec2(0, 30));

    // Center form
    float formWidth = 350.0f;
    ImGui::SetCursorPosX((io.DisplaySize.x - formWidth) / 2);

    ImGui::BeginChild("##Form", ImVec2(formWidth, 300), false);

    // Username
    ImGui::TextColored(g_Color_White, "Username:");
    ImGui::PushStyleColor(ImGuiCol_FrameBg, ImVec4(0.1f, 0.1f, 0.15f, 1.0f));
    ImGui::InputText("##username", g_Username, sizeof(g_Username));
    ImGui::PopStyleColor();
    ImGui::Dummy(ImVec2(0, 15));

    // Password
    ImGui::TextColored(g_Color_White, "Password:");
    ImGui::PushStyleColor(ImGuiCol_FrameBg, ImVec4(0.1f, 0.1f, 0.15f, 1.0f));
    ImGui::InputText("##password", g_Password, sizeof(g_Password), ImGuiInputTextFlags_Password);
    ImGui::PopStyleColor();
    ImGui::Dummy(ImVec2(0, 15));

    // Device ID (read-only)
    ImGui::TextColored(g_Color_Gray, "Device ID: %s", g_DeviceID);
    ImGui::Dummy(ImVec2(0, 20));

    // Error message
    if (strlen(g_ErrorMsg) > 0) {
        ImGui::TextColored(g_Color_Error, "%s", g_ErrorMsg);
        ImGui::Dummy(ImVec2(0, 10));
    }

    // Login button
    ImGui::PushStyleColor(ImGuiCol_Button, g_Color_Primary);
    ImGui::PushStyleColor(ImGuiCol_ButtonHovered, ImVec4(0.0f, 0.7f, 1.0f, 1.0f));
    ImGui::PushStyleColor(ImGuiCol_ButtonActive, ImVec4(0.0f, 0.8f, 1.0f, 1.0f));

    if (g_IsLoading) {
        ImGui::Button("Loading...", ImVec2(formWidth, 50));
    } else {
        if (ImGui::Button("Login", ImVec2(formWidth, 50))) {
            g_IsLoading = true;
            strcpy(g_ErrorMsg, "");

            // API Check
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                bool success = APILogin(g_Username, g_Password, g_DeviceID);

                dispatch_async(dispatch_get_main_queue(), ^{
                    g_IsLoading = false;
                    if (success) {
                        g_LoginSuccess = true;
                        g_LoginVisible = false;  // HIDE ONLY ON SUCCESS
                    } else {
                        strcpy(g_ErrorMsg, "Invalid username or password");
                    }
                });
            });
        }
    }

    ImGui::PopStyleColor(3);
    ImGui::Dummy(ImVec2(0, 15));

    // Register link
    ImGui::SetCursorPosX((formWidth - ImGui::CalcTextSize("Don't have an account? Register").x) / 2);
    ImGui::TextColored(g_Color_Gray, "Don't have an account?");
    ImGui::SameLine();
    if (ImGui::SmallButton("Register")) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://your-website.com/register"]];
    }

    ImGui::EndChild();

    // Footer
    ImGui::SetCursorPosY(io.DisplaySize.y - 40);
    ImGui::SetCursorPosX((io.DisplaySize.x - ImGui::CalcTextSize("Secured by Device ID Verification").x) / 2);
    ImGui::TextColored(g_Color_Gray, "Secured by Device ID Verification");

    ImGui::End();
}

// ========== INITIALIZATION ==========
void InitializeLogin() {
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO();

    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;

    SetupStyle();
    GetDeviceID();

    UIWindow* keyWindow = [[UIApplication sharedApplication] keyWindow];
    UIViewController* rootVC = [keyWindow rootViewController];
    UIView* view = [rootVC view];

    for (CALayer* layer in [view.layer sublayers]) {
        if ([layer isKindOfClass:[CAMetalLayer class]]) {
            g_MetalLayer = (CAMetalLayer*)layer;
            break;
        }
    }

    if (g_MetalLayer) {
        g_Device = MTLCreateSystemDefaultDevice();
        g_CommandQueue = [g_Device newCommandQueue];
        ImGui_ImplMetal_Init(g_Device);
    }

    NSLog(@"[OneStateLogin] Login screen initialized");
    NSLog(@"[OneStateLogin] Device ID: %s", g_DeviceID);
}

// ========== RENDER ==========
void RenderLogin() {
    if (!g_MetalLayer || !g_Device) return;
    if (!g_LoginVisible) return;  // Don't render if login success

    ImGuiIO& io = ImGui::GetIO();

    ImGui_ImplMetal_NewFrame(g_MetalLayer.currentDrawable);
    ImGui::NewFrame();

    // ALWAYS render fullscreen login
    RenderFullscreenLogin();

    ImGui::Render();

    id<MTLCommandBuffer> commandBuffer = [g_CommandQueue commandBuffer];
    MTLRenderPassDescriptor* renderPassDescriptor = [[MTLRenderPassDescriptor alloc] init];
    renderPassDescriptor.colorAttachments[0].texture = g_MetalLayer.currentDrawable.texture;
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionLoad;
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);

    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    ImGui_ImplMetal_RenderDrawData(ImGui::GetDrawData(), commandBuffer, renderEncoder);
    [renderEncoder endEncoding];
    [commandBuffer presentDrawable:g_MetalLayer.currentDrawable];
    [commandBuffer commit];
}
