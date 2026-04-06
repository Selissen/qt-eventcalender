// flutter_stub.h — test control and observation API for the Flutter Windows
// C API stubs.  Include this in test files that need to prime or inspect stub
// behaviour.  The implementation lives in flutter_stub.cpp.
#pragma once
#ifndef Q_OS_WASM

#include <string>
#include <QByteArray>
#include <QList>

// Pull in the stub type definitions so callers can refer to
// FlutterDesktopMessageCallback etc. without an extra include.
#include "stubs/flutter_windows.h"

namespace FlutterStub {

// ── Recorded outbound send ────────────────────────────────────────────────
struct SendRecord {
    std::string channel;
    QByteArray  payload;
};

// ── Recorded callback registration ───────────────────────────────────────
struct CallbackRecord {
    std::string                    channel;
    FlutterDesktopMessageCallback  callback;   // may be nullptr (unregister)
    void*                          userData;
};

// ── Recorded engine creation properties ──────────────────────────────────
struct EngineCreateRecord {
    std::string              entrypoint;  // dart_entrypoint (empty = "main")
    std::vector<std::string> argv;        // dart_entrypoint_argv values
};

// ── Control API ──────────────────────────────────────────────────────────

/// Reset all stub state.  Call in QTest::init() / QTEST_MAIN setUp.
void reset();

/// Make the next FlutterDesktopEngineCreate() return nullptr.
void failNextEngineCreate();

/// Make the next FlutterDesktopViewControllerCreate() return nullptr.
void failNextControllerCreate();

// ── Observation API ───────────────────────────────────────────────────────

/// Return and clear all MessengerSend calls recorded since last call/reset.
QList<SendRecord> takeSends();

/// Return and clear all MessengerSetCallback calls recorded since last call/reset.
QList<CallbackRecord> takeCallbacks();

/// Return and clear the engine-creation record captured by the last
/// FlutterDesktopEngineCreate() call (entrypoint + argv).
EngineCreateRecord takeLastEngineCreate();

// ── Injection API ─────────────────────────────────────────────────────────

/// Simulate Flutter sending |payload| on |channel| to Qt.
/// Finds the registered callback for that channel and calls it with a
/// FlutterDesktopMessage populated from the payload bytes.
/// Does nothing if no callback is registered for the channel.
void injectMessage(const std::string& channel, const QByteArray& payload);

// ── Stable singleton instances ────────────────────────────────────────────
// The create functions return pointers to these when not failing, so the
// same address is reused across calls and can be compared in assertions.

FlutterDesktopEngineRef          stubEngine();
FlutterDesktopViewControllerRef  stubController();
FlutterDesktopViewRef            stubView();
FlutterDesktopMessengerRef       stubMessenger();

} // namespace FlutterStub

#endif // Q_OS_WASM
