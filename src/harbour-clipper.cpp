#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif
#include <QtQml> // needed for registering AudioRecorder
#include <QGuiApplication>
#include <QLocale>
#include <QQuickView>
#include <QScopedPointer>
#include <QStandardPaths>
#include <sailfishapp.h>
#include <src/audio-recorder.h>

void migrateLocalStorage()
{
    // first for the new directory, post sailjail

    QDir newDbDir( QDir::homePath() + "/.cache/de.poetaster/harbour-clipper/");

    if( ! newDbDir.exists() )
        newDbDir.mkpath(newDbDir.path());
}

int main(int argc, char *argv[])
{
    // SailfishApp::main() will display "qml/harbour-audiocut.qml", if you need more
    // control over initialization, you can use:
    //
    //   - SailfishApp::application(int, char *[]) to get the QGuiApplication *
    //   - SailfishApp::createView() to get a new QQuickView * instance
    //   - SailfishApp::pathTo(QString) to get a QUrl to a resource file
    //   - SailfishApp::pathToMainQml() to get a QUrl to the main QML file
    //
    // To display the view, call "show()" (will show fullscreen on device).

    QGuiApplication *app = SailfishApp::application(argc, argv);

    migrateLocalStorage();

    // now set too new OrgName
    app->setApplicationDisplayName("Videoworks");
    app->setApplicationName("harbour-clipper");
    app->setOrganizationDomain("de.poetaster");
    app->setOrganizationName("de.poetaster"); // needed for Sailjail

    QTranslator *appTranslator = new QTranslator;
    appTranslator->load("harbour-clipper-" + QLocale::system().name(), SailfishApp::pathTo("translations").path());
    app->installTranslator(appTranslator);


    qmlRegisterType<AudioRecorder>("AudioRecorder", 1, 0, "AudioRecorder"); // needed for AudioRecorder to register as QML component
    QScopedPointer<QQuickView> view(SailfishApp::createView());
    view->setSource(SailfishApp::pathTo("qml/harbour-clipper.qml"));
    view->setTitle("Videoworks");
    view->showFullScreen();
    return app->exec();
}
