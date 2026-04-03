// flutter_stub.cpp — implementations of the Flutter Windows C API functions
// used by the embedding layer, plus the FlutterStub control/observation API.
//
// The stubs are compiled directly into each test executable instead of
// linking against flutter_windows.dll, so the embedding code under test
// exercises real logic paths with full control over Flutter-side behaviour.
#ifndef Q_OS_WASM

#include "flutter_stub.h"

#include <map>
#include <string>
#include <cstring>

// ── Stable dummy objects ──────────────────────────────────────────────────
// These are global instances whose addresses are returned by the create
// functions.  Using fixed addresses lets test code compare pointer values.

static FlutterDesktopEngine          g_engine      { 1 };
static FlutterDesktopViewController  g_controller  { 2 };
static FlutterDesktopView            g_view        { 3 };
static FlutterDesktopMessenger       g_messenger   { 4 };

// Dummy HWND value returned by FlutterDesktopViewGetHWND.
// Using GetDesktopWindow() would require a display; use a non-null sentinel
// that satisfies "hwnd != nullptr" checks without actually parenting windows.
static HWND g_dummyHwnd = reinterpret_cast<HWND>(static_cast<uintptr_t>(0xDEADBEEFu));

// ── Mutable stub state ────────────────────────────────────────────────────

namespace {

struct StubState {
    bool failNextEngineCreate     = false;
    bool failNextControllerCreate = false;

    QList<FlutterStub::SendRecord>     sends;
    QList<FlutterStub::CallbackRecord> callbacks;

    // channel → {callback, userData}  (latest registration wins)
    struct Registration {
        FlutterDesktopMessageCallback callback = nullptr;
        void*                         userData = nullptr;
    };
    std::map<std::string, Registration> registrations;
};

static StubState g_state;

} // anonymous namespace

// ── FlutterStub control / observation API ─────────────────────────────────

namespace FlutterStub {

void reset()
{
    g_state = StubState{};
}

void failNextEngineCreate()
{
    g_state.failNextEngineCreate = true;
}

void failNextControllerCreate()
{
    g_state.failNextControllerCreate = true;
}

QList<SendRecord> takeSends()
{
    QList<SendRecord> result;
    result.swap(g_state.sends);
    return result;
}

QList<CallbackRecord> takeCallbacks()
{
    QList<CallbackRecord> result;
    result.swap(g_state.callbacks);
    return result;
}

void injectMessage(const std::string& channel, const QByteArray& payload)
{
    auto it = g_state.registrations.find(channel);
    if (it == g_state.registrations.end() || it->second.callback == nullptr)
        return;

    FlutterDesktopMessage msg{};
    msg.struct_size   = sizeof(FlutterDesktopMessage);
    msg.channel       = channel.c_str();
    msg.message       = reinterpret_cast<const uint8_t*>(payload.constData());
    msg.message_size  = static_cast<size_t>(payload.size());
    msg.response_handle = nullptr;

    it->second.callback(&g_messenger, &msg, it->second.userData);
}

FlutterDesktopEngineRef         stubEngine()     { return &g_engine;     }
FlutterDesktopViewControllerRef stubController() { return &g_controller; }
FlutterDesktopViewRef           stubView()       { return &g_view;       }
FlutterDesktopMessengerRef      stubMessenger()  { return &g_messenger;  }

} // namespace FlutterStub

// ── Flutter Windows C API stubs ───────────────────────────────────────────

extern "C" {

// ---- Engine ----------------------------------------------------------------

FlutterDesktopEngineRef FlutterDesktopEngineCreate(
    const FlutterDesktopEngineProperties* /*props*/)
{
    if (g_state.failNextEngineCreate) {
        g_state.failNextEngineCreate = false;
        return nullptr;
    }
    return &g_engine;
}

bool FlutterDesktopEngineDestroy(FlutterDesktopEngineRef /*engine*/)
{
    return true;
}

bool FlutterDesktopEngineRun(FlutterDesktopEngineRef /*engine*/,
                              const char* /*entry_point*/)
{
    return true;
}

uint64_t FlutterDesktopEngineProcessMessages(FlutterDesktopEngineRef /*engine*/)
{
    return 0;
}

void FlutterDesktopEngineReloadSystemFonts(FlutterDesktopEngineRef /*engine*/)
{}

FlutterDesktopPluginRegistrarRef FlutterDesktopEngineGetPluginRegistrar(
    FlutterDesktopEngineRef /*engine*/, const char* /*plugin_name*/)
{
    return nullptr;
}

FlutterDesktopMessengerRef FlutterDesktopEngineGetMessenger(
    FlutterDesktopEngineRef engine)
{
    if (!engine) return nullptr;
    return &g_messenger;
}

void FlutterDesktopEngineSetNextFrameCallback(
    FlutterDesktopEngineRef /*engine*/,
    VoidCallback /*callback*/,
    void* /*user_data*/)
{}

bool FlutterDesktopEngineProcessExternalWindowMessage(
    FlutterDesktopEngineRef /*engine*/,
    HWND /*hwnd*/, UINT /*msg*/, WPARAM /*wp*/, LPARAM /*lp*/, LRESULT* /*r*/)
{
    return false;
}

// ---- View controller -------------------------------------------------------

FlutterDesktopViewControllerRef FlutterDesktopViewControllerCreate(
    int /*width*/, int /*height*/, FlutterDesktopEngineRef /*engine*/)
{
    if (g_state.failNextControllerCreate) {
        g_state.failNextControllerCreate = false;
        return nullptr;
    }
    return &g_controller;
}

void FlutterDesktopViewControllerDestroy(
    FlutterDesktopViewControllerRef /*controller*/)
{}

FlutterDesktopViewId FlutterDesktopViewControllerGetViewId(
    FlutterDesktopViewControllerRef /*controller*/)
{
    return 0;
}

FlutterDesktopEngineRef FlutterDesktopViewControllerGetEngine(
    FlutterDesktopViewControllerRef /*controller*/)
{
    return &g_engine;
}

FlutterDesktopViewRef FlutterDesktopViewControllerGetView(
    FlutterDesktopViewControllerRef controller)
{
    if (!controller) return nullptr;
    return &g_view;
}

void FlutterDesktopViewControllerForceRedraw(
    FlutterDesktopViewControllerRef /*controller*/)
{}

bool FlutterDesktopViewControllerHandleTopLevelWindowProc(
    FlutterDesktopViewControllerRef /*controller*/,
    HWND /*hwnd*/, UINT /*msg*/, WPARAM /*wp*/, LPARAM /*lp*/, LRESULT* /*r*/)
{
    return false;
}

// ---- View ------------------------------------------------------------------

HWND FlutterDesktopViewGetHWND(FlutterDesktopViewRef view)
{
    if (!view) return nullptr;
    return g_dummyHwnd;
}

// ---- Plugin registrar stubs ------------------------------------------------

FlutterDesktopViewRef FlutterDesktopPluginRegistrarGetView(
    FlutterDesktopPluginRegistrarRef /*reg*/)
{
    return nullptr;
}

FlutterDesktopViewRef FlutterDesktopPluginRegistrarGetViewById(
    FlutterDesktopPluginRegistrarRef /*reg*/, FlutterDesktopViewId /*id*/)
{
    return nullptr;
}

void FlutterDesktopPluginRegistrarRegisterTopLevelWindowProcDelegate(
    FlutterDesktopPluginRegistrarRef /*reg*/,
    FlutterDesktopWindowProcCallback /*delegate*/,
    void* /*user_data*/)
{}

void FlutterDesktopPluginRegistrarUnregisterTopLevelWindowProcDelegate(
    FlutterDesktopPluginRegistrarRef /*reg*/,
    FlutterDesktopWindowProcCallback /*delegate*/)
{}

// ---- Messenger -------------------------------------------------------------

bool FlutterDesktopMessengerSend(FlutterDesktopMessengerRef /*messenger*/,
                                  const char* channel,
                                  const uint8_t* message,
                                  size_t message_size)
{
    FlutterStub::SendRecord rec;
    rec.channel = channel ? channel : "";
    if (message && message_size > 0)
        rec.payload = QByteArray(reinterpret_cast<const char*>(message),
                                 static_cast<int>(message_size));
    g_state.sends.append(rec);
    return true;
}

bool FlutterDesktopMessengerSendWithReply(
    FlutterDesktopMessengerRef messenger,
    const char* channel,
    const uint8_t* message,
    size_t message_size,
    FlutterDesktopBinaryReply /*reply*/,
    void* /*user_data*/)
{
    return FlutterDesktopMessengerSend(messenger, channel, message, message_size);
}

void FlutterDesktopMessengerSendResponse(
    FlutterDesktopMessengerRef /*messenger*/,
    const FlutterDesktopMessageResponseHandle* /*handle*/,
    const uint8_t* /*data*/,
    size_t /*data_length*/)
{}

void FlutterDesktopMessengerSetCallback(
    FlutterDesktopMessengerRef /*messenger*/,
    const char* channel,
    FlutterDesktopMessageCallback callback,
    void* user_data)
{
    const std::string ch = channel ? channel : "";

    FlutterStub::CallbackRecord rec;
    rec.channel  = ch;
    rec.callback = callback;
    rec.userData = user_data;
    g_state.callbacks.append(rec);

    // Update the live registration so injectMessage can find it.
    if (callback) {
        g_state.registrations[ch] = { callback, user_data };
    } else {
        g_state.registrations.erase(ch);
    }
}

FlutterDesktopMessengerRef FlutterDesktopMessengerAddRef(
    FlutterDesktopMessengerRef messenger)
{
    return messenger;
}

void FlutterDesktopMessengerRelease(FlutterDesktopMessengerRef /*messenger*/)
{}

bool FlutterDesktopMessengerIsAvailable(
    FlutterDesktopMessengerRef /*messenger*/)
{
    return true;
}

FlutterDesktopMessengerRef FlutterDesktopMessengerLock(
    FlutterDesktopMessengerRef messenger)
{
    return messenger;
}

void FlutterDesktopMessengerUnlock(FlutterDesktopMessengerRef /*messenger*/)
{}

// ---- Utilities -------------------------------------------------------------

UINT FlutterDesktopGetDpiForHWND(HWND /*hwnd*/)   { return 96; }
UINT FlutterDesktopGetDpiForMonitor(HMONITOR /*m*/) { return 96; }
void FlutterDesktopResyncOutputStreams()             {}

} // extern "C"

#endif // Q_OS_WASM
