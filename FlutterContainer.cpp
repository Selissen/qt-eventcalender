#ifndef Q_OS_WASM

#include "FlutterContainer.h"
#include <QDebug>

FlutterContainer::FlutterContainer(QObject* parent)
    : QObject(parent) {}

bool FlutterContainer::initialize(const QString& assetsPath,
                                  const QString& icuDataPath,
                                  const QString& aotLibraryPath)
{
    const std::wstring assets = assetsPath.toStdWString();
    const std::wstring icu    = icuDataPath.toStdWString();
    const std::wstring aot    = aotLibraryPath.toStdWString();

    FlutterDesktopEngineProperties props = {};
    props.assets_path      = assets.c_str();
    props.icu_data_path    = icu.c_str();
    props.aot_library_path = aot.empty() ? nullptr : aot.c_str();

    engine_ = FlutterDesktopEngineCreate(&props);
    if (!engine_) {
        qWarning("[Flutter] FlutterDesktopEngineCreate failed.");
        return false;
    }

    // Initial size 0×0; positioned later via moveToRect() from FlutterView.
    controller_ = FlutterDesktopViewControllerCreate(0, 0, engine_);
    if (!controller_) {
        qWarning("[Flutter] FlutterDesktopViewControllerCreate failed.");
        FlutterDesktopEngineDestroy(engine_);
        engine_ = nullptr;
        return false;
    }

    // Drive Flutter's message loop from Qt's main thread at ~60 fps.
    loop_timer_ = new QTimer(this);
    connect(loop_timer_, &QTimer::timeout, this, [this]() {
        if (engine_)
            FlutterDesktopEngineProcessMessages(engine_);
    });
    loop_timer_->start(16);

    return true;
}

bool FlutterContainer::embedInto(HWND parentHwnd)
{
    HWND hwnd = flutterHwnd();
    if (!hwnd || !parentHwnd)
        return false;

    // Convert the Flutter top-level window into a WS_CHILD window so it
    // renders inside the parent (the QQuickWindow's HWND).
    LONG style = ::GetWindowLong(hwnd, GWL_STYLE);
    style = (style & ~(WS_POPUP | WS_CAPTION | WS_THICKFRAME | WS_OVERLAPPEDWINDOW))
            | WS_CHILD;
    ::SetWindowLong(hwnd, GWL_STYLE, style);
    ::SetParent(hwnd, parentHwnd);
    // Start hidden; NavigationBridge calls showEmbedded() on first navigation.
    ::ShowWindow(hwnd, SW_HIDE);
    embedded_visible_ = false;

    return true;
}

void FlutterContainer::moveToRect(int x, int y, int w, int h)
{
    if (HWND hwnd = flutterHwnd())
        ::MoveWindow(hwnd, x, y, w, h, TRUE);
}

void FlutterContainer::showEmbedded()
{
    if (HWND hwnd = flutterHwnd()) {
        ::ShowWindow(hwnd, SW_SHOW);
        ::SetFocus(hwnd);
        embedded_visible_ = true;
    }
}

void FlutterContainer::hideEmbedded()
{
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
