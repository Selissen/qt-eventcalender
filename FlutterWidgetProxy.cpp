#ifndef Q_OS_WASM

#include "FlutterWidgetProxy.h"
#include <QResizeEvent>
#include <windows.h>

FlutterWidgetProxy::FlutterWidgetProxy(FlutterDesktopViewControllerRef controller,
                                       QWidget* parent)
    : QWidget(parent), controller_(controller)
{
    setAttribute(Qt::WA_TranslucentBackground);
    setAutoFillBackground(false);
}

void FlutterWidgetProxy::activate()
{
    HWND hwnd = FlutterDesktopViewGetHWND(
        FlutterDesktopViewControllerGetView(controller_));

    // WS_CLIPSIBLINGS prevents z-order conflicts with sibling Qt controls
    // (tooltips, dropdowns) on the same parent window.
    ::SetWindowLong(hwnd, GWL_STYLE,
        ::GetWindowLong(hwnd, GWL_STYLE) | WS_CLIPSIBLINGS);

    flutter_window_ = QWindow::fromWinId(reinterpret_cast<WId>(hwnd));
    container_ = QWidget::createWindowContainer(flutter_window_, this);
    container_->setGeometry(0, 0, width(), height());

    // Note: FlutterDesktopViewControllerSetBackgroundColor is not available in
    // this engine version. Set transparency in Flutter via:
    //   MaterialApp(theme: ThemeData(scaffoldBackgroundColor: Colors.transparent))
}

void FlutterWidgetProxy::syncGeometry()
{
    if (container_)
        container_->setGeometry(0, 0, width(), height());
}

void FlutterWidgetProxy::resizeEvent(QResizeEvent* e)
{
    QWidget::resizeEvent(e);
    syncGeometry();
}

void FlutterWidgetProxy::moveEvent(QMoveEvent* e)
{
    QWidget::moveEvent(e);
    syncGeometry();
}

void FlutterWidgetProxy::showEvent(QShowEvent* e)
{
    QWidget::showEvent(e);
    if (container_) container_->show();
}

void FlutterWidgetProxy::hideEvent(QHideEvent* e)
{
    QWidget::hideEvent(e);
    if (container_) container_->hide();
}

FlutterWidgetProxy::~FlutterWidgetProxy()
{
    // Controller lifetime is managed by the owning screen / ComponentEngineFactory,
    // not by the proxy. Do NOT destroy the controller here.
}

#endif // Q_OS_WASM
