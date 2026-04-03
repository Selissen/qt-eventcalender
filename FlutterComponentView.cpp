#ifndef Q_OS_WASM

#include "FlutterComponentView.h"
#include "ComponentBridge.h"
#include "ComponentEngineFactory.h"

#include <QCoreApplication>
#include <QFile>
#include <QDir>
#include <QQuickWindow>
#include <QJsonObject>
#include <QJsonDocument>
#include <QDebug>

FlutterComponentView::FlutterComponentView(QQuickItem* parent)
    : QQuickItem(parent) {}

FlutterComponentView::~FlutterComponentView()
{
    if (loopTimer_) loopTimer_->stop();
    if (controller_) FlutterDesktopViewControllerDestroy(controller_);
}

void FlutterComponentView::setEntrypoint(const QString& v)
{
    if (entrypoint_ == v) return;
    entrypoint_ = v;
    emit entrypointChanged();
}

void FlutterComponentView::setChannel(const QString& v)
{
    if (channel_ == v) return;
    channel_ = v;
    emit channelChanged();
}

void FlutterComponentView::ensureEngine()
{
    if (controller_ || !window() || entrypoint_.isEmpty() || channel_.isEmpty())
        return;

    const QString exeDir     = QCoreApplication::applicationDirPath();
    const QString assetsPath = exeDir + QStringLiteral("/flutter_assets");
    const QString icuPath    = exeDir + QStringLiteral("/icudtl.dat");
    const QString aotPath    = exeDir + QStringLiteral("/app.so");

    if (!QDir(assetsPath).exists() || !QFile::exists(icuPath)) {
        qWarning("[FlutterComponentView] flutter_assets/ or icudtl.dat missing "
                 "— component '%s' disabled.", qPrintable(entrypoint_));
        return;
    }

    const QString resolvedAot = QFile::exists(aotPath) ? aotPath : QString{};

    controller_ = ComponentEngineFactory::createController(
        assetsPath, icuPath, resolvedAot,
        entrypoint_,
        qRound(width()), qRound(height()));

    if (!controller_) {
        qWarning("[FlutterComponentView] createController() failed for '%s'.",
                 qPrintable(entrypoint_));
        return;
    }

    // Embed Flutter's HWND as a Win32 child of the QML window.
    const HWND parentHwnd  = reinterpret_cast<HWND>(window()->winId());
    const HWND flutterHwnd = FlutterDesktopViewGetHWND(
        FlutterDesktopViewControllerGetView(controller_));

    LONG style = ::GetWindowLong(flutterHwnd, GWL_STYLE);
    style = (style & ~(WS_POPUP | WS_CAPTION | WS_THICKFRAME | WS_OVERLAPPEDWINDOW))
            | WS_CHILD | WS_CLIPSIBLINGS;
    ::SetWindowLong(flutterHwnd, GWL_STYLE, style);
    ::SetParent(flutterHwnd, parentHwnd);
    ::ShowWindow(flutterHwnd, SW_HIDE);

    bridge_ = new ComponentBridge(
        FlutterDesktopViewControllerGetEngine(controller_),
        channel_,
        this);

    connect(bridge_, &ComponentBridge::messageReceived,
            this, [this](const QString& method, const QJsonObject& jsonArgs) {
        if (method == QLatin1String("ready")) {
            dartReady_ = true;
            emit readyChanged();
            flushPending();
        } else {
            emit messageReceived(method, jsonArgs.toVariantMap());
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

    qDebug("[FlutterComponentView] Engine started for '%s' on channel '%s'.",
           qPrintable(entrypoint_), qPrintable(channel_));
}

void FlutterComponentView::send(const QString& method, const QVariantMap& args)
{
    if (!bridge_ || !dartReady_) {
        pending_.append({ method, args });
        return;
    }
    bridge_->send(method, QJsonObject::fromVariantMap(args));
}

void FlutterComponentView::flushPending()
{
    if (!bridge_ || !dartReady_) return;
    for (const Msg& m : std::as_const(pending_))
        bridge_->send(m.method, QJsonObject::fromVariantMap(m.args));
    pending_.clear();
}

void FlutterComponentView::geometryChange(const QRectF& newGeom, const QRectF& oldGeom)
{
    QQuickItem::geometryChange(newGeom, oldGeom);
    syncRect();
}

void FlutterComponentView::itemChange(ItemChange change, const ItemChangeData& value)
{
    QQuickItem::itemChange(change, value);
    if (change == ItemSceneChange && value.window) {
        if (isVisible()) ensureEngine();
    } else if (change == ItemVisibleHasChanged) {
        if (value.boolValue) ensureEngine();
        syncRect();
        syncVisibility(value.boolValue);
    }
}

void FlutterComponentView::syncRect()
{
    if (!controller_ || !window()) return;
    const HWND flutterHwnd = FlutterDesktopViewGetHWND(
        FlutterDesktopViewControllerGetView(controller_));
    const QPointF scenePos = mapToScene(QPointF(0, 0));
    ::MoveWindow(flutterHwnd,
                 qRound(scenePos.x()), qRound(scenePos.y()),
                 qRound(width()),       qRound(height()),
                 TRUE);
}

void FlutterComponentView::syncVisibility(bool visible)
{
    if (!controller_) return;
    const HWND flutterHwnd = FlutterDesktopViewGetHWND(
        FlutterDesktopViewControllerGetView(controller_));
    ::ShowWindow(flutterHwnd, visible ? SW_SHOW : SW_HIDE);
}

#endif // Q_OS_WASM
