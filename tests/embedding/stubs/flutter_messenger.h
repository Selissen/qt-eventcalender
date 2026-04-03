// Stub flutter_messenger.h for unit tests.
// Types and signatures match the real Flutter Windows messenger header exactly.
#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include "flutter_export.h"

#if defined(__cplusplus)
extern "C" {
#endif

// Opaque reference to a Flutter engine messenger.
struct FlutterDesktopMessenger;
typedef struct FlutterDesktopMessenger* FlutterDesktopMessengerRef;

// Opaque handle for tracking responses to messages.
struct _FlutterPlatformMessageResponseHandle;
typedef struct _FlutterPlatformMessageResponseHandle
    FlutterDesktopMessageResponseHandle;

// The callback expected as a response of a binary message.
typedef void (*FlutterDesktopBinaryReply)(const uint8_t* data,
                                          size_t data_size,
                                          void* user_data);

// A message received from Flutter.
typedef struct {
    // Size of this struct as created by Flutter.
    size_t struct_size;
    // The name of the channel used for this message.
    const char* channel;
    // The raw message data.
    const uint8_t* message;
    // The length of |message|.
    size_t message_size;
    // The response handle. If non-null, the receiver of this message must call
    // FlutterDesktopSendMessageResponse exactly once with this handle.
    const FlutterDesktopMessageResponseHandle* response_handle;
} FlutterDesktopMessage;

// Function pointer type for message handler callback registration.
typedef void (*FlutterDesktopMessageCallback)(
    FlutterDesktopMessengerRef /* messenger */,
    const FlutterDesktopMessage* /* message */,
    void* /* user_data */);

// Sends a binary message to the Flutter side on the specified channel.
FLUTTER_EXPORT bool FlutterDesktopMessengerSend(
    FlutterDesktopMessengerRef messenger,
    const char* channel,
    const uint8_t* message,
    size_t message_size);

// Sends a binary message to the Flutter side with a reply callback.
FLUTTER_EXPORT bool FlutterDesktopMessengerSendWithReply(
    FlutterDesktopMessengerRef messenger,
    const char* channel,
    const uint8_t* message,
    size_t message_size,
    FlutterDesktopBinaryReply reply,
    void* user_data);

// Sends a reply to a FlutterDesktopMessage for the given response handle.
FLUTTER_EXPORT void FlutterDesktopMessengerSendResponse(
    FlutterDesktopMessengerRef messenger,
    const FlutterDesktopMessageResponseHandle* handle,
    const uint8_t* data,
    size_t data_length);

// Registers a callback for incoming messages on the specified channel.
FLUTTER_EXPORT void FlutterDesktopMessengerSetCallback(
    FlutterDesktopMessengerRef messenger,
    const char* channel,
    FlutterDesktopMessageCallback callback,
    void* user_data);

// Increments the reference count for the messenger.
FLUTTER_EXPORT FlutterDesktopMessengerRef
FlutterDesktopMessengerAddRef(FlutterDesktopMessengerRef messenger);

// Decrements the reference count for the messenger.
FLUTTER_EXPORT void FlutterDesktopMessengerRelease(
    FlutterDesktopMessengerRef messenger);

// Returns true if the messenger still references a running engine.
FLUTTER_EXPORT bool FlutterDesktopMessengerIsAvailable(
    FlutterDesktopMessengerRef messenger);

// Locks the messenger for thread-safe access.
FLUTTER_EXPORT FlutterDesktopMessengerRef
FlutterDesktopMessengerLock(FlutterDesktopMessengerRef messenger);

// Unlocks the messenger.
FLUTTER_EXPORT void FlutterDesktopMessengerUnlock(
    FlutterDesktopMessengerRef messenger);

#if defined(__cplusplus)
}
#endif
