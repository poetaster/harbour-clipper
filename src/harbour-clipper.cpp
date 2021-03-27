#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif
#include <QtQml> // needed for registering AudioRecorder
#include <sailfishapp.h>
#include <src/audio-recorder.h>

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
    qmlRegisterType<AudioRecorder>("AudioRecorder", 1, 0, "AudioRecorder"); // needed for AudioRecorder to register as QML component
    return SailfishApp::main(argc, argv);
}
