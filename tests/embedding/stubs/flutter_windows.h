// Stub flutter_windows.h for unit tests.
// Matches the public API of the real Flutter Windows header but:
//   - does NOT include <dxgi.h> (unavailable / irrelevant in test builds)
//   - does NOT dllimport/export anything (FLUTTER_EXPORT is empty)
//   - opaque struct bodies are defined so stubs can be instantiated as globals
#pragma once

#include <stddef.h>
#include <stdint.h>
#include <windows.h>

#include "flutter_export.h"
#include "flutter_messenger.h"
#include "flutter_plugin_registrar.h"

#if defined(__cplusplus)
extern "C" {
#endif

typedef void (*VoidCallback)(void* /* user_data */);

// ---------------------------------------------------------------------------
// Opaque types — given a concrete body so test code can allocate them as
// global/static objects and cast their addresses to the Ref typedefs.
// ---------------------------------------------------------------------------

struct FlutterDesktopViewController { int id; };
typedef struct FlutterDesktopViewController* FlutterDesktopViewControllerRef;

struct FlutterDesktopView { int id; };
typedef struct FlutterDesktopView* FlutterDesktopViewRef;

struct FlutterDesktopEngine { int id; };
typedef struct FlutterDesktopEngine* FlutterDesktopEngineRef;

struct FlutterDesktopMessenger { int id; };

struct FlutterDesktopPluginRegistrar { int id; };
typedef struct FlutterDesktopPluginRegistrar* FlutterDesktopPluginRegistrarRef;

typedef int64_t FlutterDesktopViewId;

// GPU preference enum (mirrors the real header).
typedef enum {
    NoPreference            = 0,
    LowPowerPreference      = 1,
    HighPerformancePreference = 2,
} FlutterDesktopGpuPreference;

// UI thread policy enum (mirrors the real header).
typedef enum {
    Default             = 0,
    RunOnPlatformThread = 1,
    RunOnSeparateThread = 2,
} FlutterDesktopUIThreadPolicy;

// Engine creation properties.
typedef struct {
    const wchar_t* assets_path;
    const wchar_t* icu_data_path;
    const wchar_t* aot_library_path;
    const char*    dart_entrypoint;
    int            dart_entrypoint_argc;
    const char**   dart_entrypoint_argv;
    FlutterDesktopGpuPreference   gpu_preference;
    FlutterDesktopUIThreadPolicy  ui_thread_policy;
} FlutterDesktopEngineProperties;

// WindowProc delegate callback type.
typedef bool (*FlutterDesktopWindowProcCallback)(
    HWND, UINT, WPARAM, LPARAM, void*, LRESULT*);

// ---------------------------------------------------------------------------
// View controller
// ---------------------------------------------------------------------------

FLUTTER_EXPORT FlutterDesktopViewControllerRef
FlutterDesktopViewControllerCreate(int width, int height,
                                   FlutterDesktopEngineRef engine);

FLUTTER_EXPORT void FlutterDesktopViewControllerDestroy(
    FlutterDesktopViewControllerRef controller);

FLUTTER_EXPORT FlutterDesktopViewId FlutterDesktopViewControllerGetViewId(
    FlutterDesktopViewControllerRef controller);

FLUTTER_EXPORT FlutterDesktopEngineRef FlutterDesktopViewControllerGetEngine(
    FlutterDesktopViewControllerRef controller);

FLUTTER_EXPORT FlutterDesktopViewRef
FlutterDesktopViewControllerGetView(FlutterDesktopViewControllerRef controller);

FLUTTER_EXPORT void FlutterDesktopViewControllerForceRedraw(
    FlutterDesktopViewControllerRef controller);

FLUTTER_EXPORT bool FlutterDesktopViewControllerHandleTopLevelWindowProc(
    FlutterDesktopViewControllerRef controller,
    HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam, LRESULT* result);

// ---------------------------------------------------------------------------
// Engine
// ---------------------------------------------------------------------------

FLUTTER_EXPORT FlutterDesktopEngineRef FlutterDesktopEngineCreate(
    const FlutterDesktopEngineProperties* engine_properties);

FLUTTER_EXPORT bool FlutterDesktopEngineDestroy(FlutterDesktopEngineRef engine);

FLUTTER_EXPORT bool FlutterDesktopEngineRun(FlutterDesktopEngineRef engine,
                                            const char* entry_point);

FLUTTER_EXPORT uint64_t
FlutterDesktopEngineProcessMessages(FlutterDesktopEngineRef engine);

FLUTTER_EXPORT void FlutterDesktopEngineReloadSystemFonts(
    FlutterDesktopEngineRef engine);

FLUTTER_EXPORT FlutterDesktopPluginRegistrarRef
FlutterDesktopEngineGetPluginRegistrar(FlutterDesktopEngineRef engine,
                                       const char* plugin_name);

FLUTTER_EXPORT FlutterDesktopMessengerRef
FlutterDesktopEngineGetMessenger(FlutterDesktopEngineRef engine);

FLUTTER_EXPORT void FlutterDesktopEngineSetNextFrameCallback(
    FlutterDesktopEngineRef engine,
    VoidCallback callback,
    void* user_data);

FLUTTER_EXPORT bool FlutterDesktopEngineProcessExternalWindowMessage(
    FlutterDesktopEngineRef engine,
    HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam, LRESULT* result);

// ---------------------------------------------------------------------------
// View
// ---------------------------------------------------------------------------

FLUTTER_EXPORT HWND FlutterDesktopViewGetHWND(FlutterDesktopViewRef view);

// ---------------------------------------------------------------------------
// Plugin registrar extensions
// ---------------------------------------------------------------------------

FLUTTER_EXPORT FlutterDesktopViewRef FlutterDesktopPluginRegistrarGetView(
    FlutterDesktopPluginRegistrarRef registrar);

FLUTTER_EXPORT FlutterDesktopViewRef FlutterDesktopPluginRegistrarGetViewById(
    FlutterDesktopPluginRegistrarRef registrar,
    FlutterDesktopViewId view_id);

FLUTTER_EXPORT void
FlutterDesktopPluginRegistrarRegisterTopLevelWindowProcDelegate(
    FlutterDesktopPluginRegistrarRef registrar,
    FlutterDesktopWindowProcCallback delegate,
    void* user_data);

FLUTTER_EXPORT void
FlutterDesktopPluginRegistrarUnregisterTopLevelWindowProcDelegate(
    FlutterDesktopPluginRegistrarRef registrar,
    FlutterDesktopWindowProcCallback delegate);

// ---------------------------------------------------------------------------
// Utilities
// ---------------------------------------------------------------------------

FLUTTER_EXPORT UINT FlutterDesktopGetDpiForHWND(HWND hwnd);
FLUTTER_EXPORT UINT FlutterDesktopGetDpiForMonitor(HMONITOR monitor);
FLUTTER_EXPORT void FlutterDesktopResyncOutputStreams();

#if defined(__cplusplus)
}
#endif
