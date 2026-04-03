#ifndef Q_OS_WASM

#include "FlutterMapItem.h"
#include "ComponentBridge.h"
#include "ComponentEngineFactory.h"
#include "flutter_constants.h"

#include <QCoreApplication>
#include <QFile>
#include <QDir>
#include <QQuickWindow>
#include <QJsonArray>
#include <QJsonObject>
#include <QDebug>

FlutterMapItem::FlutterMapItem(QQuickItem* parent)
    : QQuickItem(parent) {}

FlutterMapItem::~FlutterMapItem()
{
    if (loopTimer_) loopTimer_->stop();
    // Unregister the messenger callback before destroying the controller.
    if (bridge_) {
        bridge_->setParent(nullptr);
        delete bridge_;
        bridge_ = nullptr;
    }
    if (controller_) FlutterDesktopViewControllerDestroy(controller_);
}

void FlutterMapItem::ensureEngine()
{
    if (controller_ || !window())
        return;

    const QString exeDir    = QCoreApplication::applicationDirPath();
    const QString assetsPath = exeDir + QStringLiteral("/flutter_assets");
    const QString icuPath    = exeDir + QStringLiteral("/icudtl.dat");
    const QString aotPath    = exeDir + QStringLiteral("/app.so");

    if (!QDir(assetsPath).exists() || !QFile::exists(icuPath)) {
        qWarning("[FlutterMapItem] flutter_assets/ or icudtl.dat missing — map disabled.");
        return;
    }

    const QString resolvedAot = QFile::exists(aotPath) ? aotPath : QString{};

    controller_ = ComponentEngineFactory::createController(
        assetsPath, icuPath, resolvedAot,
        QStringLiteral("/map-component"),
        qRound(width()), qRound(height()));

    if (!controller_) {
        qWarning("[FlutterMapItem] createController() failed.");
        return;
    }

    // Embed Flutter's HWND as a Win32 child of the QML window.
    const HWND parentHwnd = reinterpret_cast<HWND>(window()->winId());
    const HWND flutterHwnd = FlutterDesktopViewGetHWND(
        FlutterDesktopViewControllerGetView(controller_));

    LONG style = ::GetWindowLong(flutterHwnd, GWL_STYLE);
    style = (style & ~(WS_POPUP | WS_CAPTION | WS_THICKFRAME | WS_OVERLAPPEDWINDOW))
            | WS_CHILD | WS_CLIPSIBLINGS;
    ::SetWindowLong(flutterHwnd, GWL_STYLE, style);
    ::SetParent(flutterHwnd, parentHwnd);
    ::ShowWindow(flutterHwnd, SW_HIDE);

    // Wire the ComponentBridge for bidirectional JSON messages.
    bridge_ = new ComponentBridge(
        FlutterDesktopViewControllerGetEngine(controller_),
        QLatin1String(FlutterChannels::kMap),
        this);

    // Flutter sends {"method":"ready"} after its first frame, indicating the
    // Dart message handler is registered.  Flush any pending routes then.
    connect(bridge_, &ComponentBridge::messageReceived,
            this, [this](const QString& method, const QJsonObject& args) {
        if (method == QLatin1String("ready")) {
            dartReady_ = true;
            flushPendingRoutes();
        } else if (method == QLatin1String("toggleRoute")) {
            emit routeToggled(args.value(QStringLiteral("id")).toInt());
        }
    });

    // Drive Flutter's message loop at ~60 fps from Qt's main thread.
    loopTimer_ = new QTimer(this);
    connect(loopTimer_, &QTimer::timeout, this, [this]() {
        if (controller_)
            FlutterDesktopEngineProcessMessages(
                FlutterDesktopViewControllerGetEngine(controller_));
    });
    loopTimer_->start(16);

    syncRect();
    syncVisibility(isVisible());

    qDebug() << "[FlutterMapItem] Map engine initialised.";
}

void FlutterMapItem::updateRoutes(const QVariantList& allRoutes,
                                  const QVariantList& selectedIds)
{
    pendingAllRoutes_   = allRoutes;
    pendingSelectedIds_ = selectedIds;
    pendingDirty_       = true;
    flushPendingRoutes();
}

void FlutterMapItem::flushPendingRoutes()
{
    if (!pendingDirty_ || !bridge_ || !dartReady_)
        return;

    QJsonArray routesArr;
    for (const QVariant& v : std::as_const(pendingAllRoutes_)) {
        const QVariantMap m = v.toMap();
        QJsonObject r;
        r[QStringLiteral("id")]   = m.value(QStringLiteral("id")).toInt();
        r[QStringLiteral("name")] = m.value(QStringLiteral("name")).toString();
        r[QStringLiteral("lat")]  = m.value(QStringLiteral("lat")).toDouble();
        r[QStringLiteral("lng")]  = m.value(QStringLiteral("lng")).toDouble();
        routesArr.append(r);
    }

    QJsonArray selectedArr;
    for (const QVariant& v : std::as_const(pendingSelectedIds_))
        selectedArr.append(v.toInt());

    bridge_->send(QStringLiteral("setRoutes"), {
        { QStringLiteral("routes"),      routesArr },
        { QStringLiteral("selectedIds"), selectedArr },
    });

    pendingDirty_ = false;
}

void FlutterMapItem::geometryChange(const QRectF& newGeom, const QRectF& oldGeom)
{
    QQuickItem::geometryChange(newGeom, oldGeom);
    syncRect();
}

void FlutterMapItem::itemChange(ItemChange change, const ItemChangeData& value)
{
    QQuickItem::itemChange(change, value);

    if (change == ItemSceneChange && value.window) {
        // Window became available; start engine if already visible.
        if (isVisible())
            ensureEngine();
    } else if (change == ItemVisibleHasChanged) {
        if (value.boolValue)
            ensureEngine();
        syncRect();
        syncVisibility(value.boolValue);
    }
}

void FlutterMapItem::syncRect()
{
    if (!controller_ || !window())
        return;

    const HWND flutterHwnd = FlutterDesktopViewGetHWND(
        FlutterDesktopViewControllerGetView(controller_));

    const QPointF scenePos = mapToScene(QPointF(0, 0));
    ::MoveWindow(flutterHwnd,
                 qRound(scenePos.x()), qRound(scenePos.y()),
                 qRound(width()),       qRound(height()),
                 TRUE);
}

void FlutterMapItem::syncVisibility(bool visible)
{
    if (!controller_)
        return;

    const HWND flutterHwnd = FlutterDesktopViewGetHWND(
        FlutterDesktopViewControllerGetView(controller_));

    ::ShowWindow(flutterHwnd, visible ? SW_SHOW : SW_HIDE);
}

#endif // Q_OS_WASM
