#ifndef Q_OS_WASM

#include "FlutterContainer.h"
#include <QDebug>

FlutterContainer::FlutterContainer(QObject* parent)
    : QObject(parent) {}

bool FlutterContainer::initialize(const QString& assetsPath,
                                  const QString& icuDataPath,
                                  const QString& aotLibraryPath)
{
    if (state_ != State::Uninitialized) {
        qWarning("[FlutterContainer] initialize() called more than once — ignored.");
        return false;
    }

    const std::wstring assets = assetsPath.toStdWString();
    const std::wstring icu    = icuDataPath.toStdWString();
    const std::wstring aot    = aotLibraryPath.toStdWString();

    FlutterDesktopEngineProperties props = {};
    props.assets_path      = assets.c_str();
    props.icu_data_path    = icu.c_str();
    props.aot_library_path = aot.empty() ? nullptr : aot.c_str();

    engine_ = FlutterDesktopEngineCreate(&props);
    if (!engine_) {
        const QString reason = QStringLiteral("FlutterDesktopEngineCreate failed");
        qWarning("[FlutterContainer] %s — check assets_path ('%ls') and icu_data_path ('%ls').",
                 qPrintable(reason), assets.c_str(), icu.c_str());
        emit initializationFailed(reason);
        return false;
    }

    // Initial size 0×0; positioned later via moveToRect() from FlutterView.
    controller_ = FlutterDesktopViewControllerCreate(0, 0, engine_);
    if (!controller_) {
        const QString reason = QStringLiteral("FlutterDesktopViewControllerCreate failed");
        qWarning("[FlutterContainer] %s.", qPrintable(reason));
        FlutterDesktopEngineDestroy(engine_);
        engine_ = nullptr;
        emit initializationFailed(reason);
        return false;
    }

    // Drive Flutter's message loop from Qt's main thread at ~60 fps.
    loop_timer_ = new QTimer(this);
    connect(loop_timer_, &QTimer::timeout, this, [this]() {
        if (engine_)
            FlutterDesktopEngineProcessMessages(engine_);
    });
    loop_timer_->start(16);

    state_ = State::Initialized;
    return true;
}

bool FlutterContainer::embedInto(HWND parentHwnd)
{
    if (state_ != State::Initialized) {
        qWarning("[FlutterContainer] embedInto() called in wrong state "
                 "(must call initialize() first).");
        return false;
    }

    HWND hwnd = flutterHwnd();
    if (!hwnd || !parentHwnd)
        return false;

    // Convert the Flutter top-level window into a WS_CHILD window so it
    // renders inside the parent (the QQuickWindow's HWND).
    LONG style = ::GetWindowLong(hwnd, GWL_STYLE);
    style = (style & ~(WS_POPUP | WS_CAPTION | WS_THICKFRAME | WS_OVERLAPPEDWINDOW))
            | WS_CHILD;
    if (!::SetWindowLong(hwnd, GWL_STYLE, style))
        qWarning("[FlutterContainer] SetWindowLong failed: %lu", ::GetLastError());
    if (!::SetParent(hwnd, parentHwnd))
        qWarning("[FlutterContainer] SetParent failed: %lu", ::GetLastError());

    // Start hidden; NavigationBridge calls showEmbedded() on first navigation.
    ::ShowWindow(hwnd, SW_HIDE);
    embedded_visible_ = false;

    state_ = State::Embedded;
    return true;
}

void FlutterContainer::moveToRect(int x, int y, int w, int h)
{
    if (state_ == State::Uninitialized) return;
    if (HWND hwnd = flutterHwnd())
        ::MoveWindow(hwnd, x, y, w, h, TRUE);
}

void FlutterContainer::showEmbedded()
{
    if (state_ == State::Uninitialized) return;
    if (HWND hwnd = flutterHwnd()) {
        ::ShowWindow(hwnd, SW_SHOW);
        ::SetFocus(hwnd);
        embedded_visible_ = true;
    }
}

void FlutterContainer::hideEmbedded()
{
    if (state_ == State::Uninitialized) return;
    if (HWND hwnd = flutterHwnd()) {
        ::ShowWindow(hwnd, SW_HIDE);
        embedded_visible_ = false;
    }
}

HWND FlutterContainer::flutterHwnd() const
{
    if (!controller_)
        return nullptr;
    return FlutterDesktopViewGetHWND(
        FlutterDesktopViewControllerGetView(controller_));
}

FlutterDesktopMessengerRef FlutterContainer::messenger() const
{
    return engine_ ? FlutterDesktopEngineGetMessenger(engine_) : nullptr;
}

FlutterContainer::~FlutterContainer()
{
    if (loop_timer_)
        loop_timer_->stop();
    if (controller_)
        FlutterDesktopViewControllerDestroy(controller_);
    // engine_ is owned by the controller after ViewControllerCreate;
    // destroying the controller also destroys the engine.
}

#endif // Q_OS_WASM
