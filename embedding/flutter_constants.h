#pragma once
#ifndef Q_OS_WASM

/// Compile-time constants for all Flutter↔Qt channel names and route strings.
/// Use these everywhere instead of bare string literals to keep the protocol
/// definition in one place.
namespace FlutterChannels {
    /// Qt → Flutter: raw UTF-8 route string (go_router path).
    constexpr const char* kNavigation     = "navigation";
    /// Flutter → Qt: any payload triggers return to Qt shell.
    constexpr const char* kNavigationBack = "navigation/back";
    /// Bidirectional channel for the map component.
    constexpr const char* kMap            = "com.eventcalendar/map";
}

namespace FlutterRoutes {
    constexpr const char* kPlans         = "/plans";
    constexpr const char* kWidgetCatalog = "/widget-catalog";
}

#endif // Q_OS_WASM
