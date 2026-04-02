#ifndef Q_OS_WASM

#include "FlutterContainer.h"
#include <QResizeEvent>
#include <QTimer>
#include <QWindow>

FlutterContainer::FlutterContainer(QWidget* parent)
    : QWidget(parent)
{
    // NativeWindow + DontCreateNativeAncestors ensure Qt gives this widget its
    // own HWND so we can reparent the Flutter HWND into it.
    setAttribute(Qt::WA_NativeWindow);
    setAttribute(Qt::WA_DontCreateNativeAncestors);
    setWindowTitle(QStringLiteral("EventCalendar — Flutter"));
}

bool FlutterContainer::initialize(const QString& assetsPath,
                                  const QString& icuDataPath,
                                  const QString& aotLibraryPath)
{
    FlutterDesktopEngineProperties props = {};
    // toStdWString() lives only as long as the temporary; store it first.
    const std::wstring assets = assetsPath.toStdWString();
    const std::wstring icu    = icuDataPath.toStdWString();
    const std::wstring aot    = aotLibraryPath.toStdWString();
    props.assets_path    = assets.c_str();
    props.icu_data_path  = icu.c_str();
    // aot_library_path is required in release builds; null is fine for debug.
    props.aot_library_path = aot.empty() ? nullptr : aot.c_str();

    engine_ = FlutterDesktopEngineCreate(&props);
    if (!engine_)
        return false;

    controller_ = FlutterDesktopViewControllerCreate(width(), height(), engine_);
    if (!controller_)
        return false;

    HWND hwnd = FlutterDesktopViewGetHWND(
        FlutterDesktopViewControllerGetView(controller_));

    flutter_window_   = QWindow::fromWinId(reinterpret_cast<WId>(hwnd));
    container_widget_ = QWidget::createWindowContainer(flutter_window_, this);
    container_widget_->setGeometry(0, 0, width(), height());

    // Drive Flutter's message loop from Qt's main thread at ~60 fps.
    auto* timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, [this]() {
        if (engine_)
            FlutterDesktopEngineProcessMessages(engine_);
    });
    timer->start(16);

    return true;
}

HWND FlutterContainer::flutterHwnd() const
{
    if (!controller_)
        return nullptr;
    return FlutterDesktopViewGetHWND(
        FlutterDesktopViewControllerGetView(controller_));
}

void FlutterContainer::resizeEvent(QResizeEvent* event)
{
    QWidget::resizeEvent(event);
    if (container_widget_)
        container_widget_->setGeometry(0, 0,
            event->size().width(), event->size().height());
}

FlutterContainer::~FlutterContainer()
{
    if (controller_)
        FlutterDesktopViewControllerDestroy(controller_);
    if (engine_)
        FlutterDesktopEngineDestroy(engine_);
}

#endif // Q_OS_WASM
