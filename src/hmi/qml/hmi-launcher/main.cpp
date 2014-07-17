#include <QtQuick/QQuickView>
#include <QApplication>
#include <QObject>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QQuickWindow>
#include <QSurfaceFormat>
#include "dbusif.h"
#include "wheelarea.h"

#define WIDTH 800
#define HEIGHT 480

int main(int argc, char ** argv)
{
    QApplication app(argc, argv);

    // Register component types with QML.
    qmlRegisterType<DBusIf>("lbs.plugin.dbusif", 1, 0, "DBusIf");
    qmlRegisterType<Preference>("lbs.plugin.preference", 1,0, "Preference");
    qmlRegisterType<WheelArea>("lbs.plugin.wheelarea", 1, 0, "WheelArea");

    int rc = 0;

    QQmlEngine engine;
    QQmlComponent *component = new QQmlComponent(&engine);

    QObject::connect(&engine, SIGNAL(quit()), QCoreApplication::instance(), SLOT(quit()));

    component->loadUrl(QUrl(argv[1]));

    if (!component->isReady() ) {
        qWarning("%s", qPrintable(component->errorString()));
        return -1;
    }

    QObject *topLevel = component->create();

    topLevel->setProperty("width", WIDTH);
    topLevel->setProperty("height", HEIGHT);

    QQuickWindow *window = qobject_cast<QQuickWindow *>(topLevel);

    window->setMaximumWidth(WIDTH);
    window->setMaximumHeight(HEIGHT);
    window->setFlags(Qt::CustomizeWindowHint);

    QSurfaceFormat surfaceFormat = window->requestedFormat();
    window->setFormat(surfaceFormat);
    window->show();

    rc = app.exec();

    delete component;
    return rc;
}
