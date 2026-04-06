#ifndef Q_OS_WASM

#include "FlutterComponentView.h"
#include "ComponentBridge.h"
#include "ComponentEngineFactory.h"

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
    // Unregister the messenger callback before destroying the controller so
    // no in-flight message can arrive after bridge_ is freed.
    if (bridge_) {
        bridge_->setParent(nullptr);
        delete bridge_;
        bridge_ = nullptr;
    }
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

void FlutterComponentView::setInstanceId(const QString& v)
{
    if (instanceId_ == v) return;
    instanceId_ = v;
    emit instanceIdChanged();
}

void FlutterComponentView::setArtifactsDir(const QString& v)
{
    if (artifactsDir_ == v) return;
    artifactsDir_ = v;
    emit artifactsDirChanged();
}

void FlutterComponentView::ensureEngine()
{
    if (controller_ || !window() || entrypoint_.isEmpty() || channel_.isEmpty())
        return;

    // Instance property overrides the process-wide factory default.
    const QString dir = artifactsDir_.isEmpty()
        ? ComponentEngineFactory::artifactsDir()
        : artifactsDir_;

    controller_ = ComponentEngineFactory::createController(
        dir + QStringLiteral("/flutter_assets"),
        dir + QStringLiteral("/icudtl.dat"),
        QFile::exists(dir + QStringLiteral("/app.so"))
            ? dir + QStringLiteral("/app.so") : QString{},
        entrypoint_,
        instanceId_,
        qRound(width()), qRound(height()));

    if (!controller_) {
        const QString reason =
            QStringLiteral("createController() failed for '%1'").arg(entrypoint_);
        qWarning("[FlutterComponentView] %s.", qPrintable(reason));
        emit engineError(reason);
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

    // Full channel: "base/instanceId" when instanceId is set, else "base".
    const QString fullChannel = instanceId_.isEmpty()
        ? channel_
        : channel_ + QStringLiteral("/") + instanceId_;

    bridge_ = new ComponentBridge(
        FlutterDesktopViewControllerGetEngine(controller_),
        fullChannel,
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
           qPrintable(entrypoint_), qPrintable(fullChannel));
}

static constexpr int kMaxPendingMessages = 256;

void FlutterComponentView::send(const QString& method, const QVariantMap& args)
{
    if (!bridge_ || !dartReady_) {
        if (pending_.size() >= kMaxPendingMessages) {
            qWarning("[FlutterComponentView] pending queue full (%d) for '%s' "
                     "— dropping oldest message.",
                     kMaxPendingMessages, qPrintable(entrypoint_));
            pending_.removeFirst();
        }
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
