# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# this is needed for using the qt builtin audio recorder
QT += qml quick multimedia

# The name of your application
TARGET = harbour-clipper

CONFIG += sailfishapp

HEADERS += \
    src/audio-recorder.h

SOURCES += src/harbour-clipper.cpp \
    src/audio-recorder.cpp

DISTFILES += qml/harbour-clipper.qml \
    qml/cover/CoverPage.qml \
    qml/cover/harbour_clipper.svg \
    qml/pages/FirstPage.qml \
    qml/pages/InfoPage.qml \
    qml/pages/SavePage.qml \
    qml/pages/AboutPage.qml \
    qml/filters/*.png \
    qml/filters/*.cube \
    qml/overlays/* \
    qml/symbols/*.svg \
    qml/py/videox.py \
    rpm/harbour-clipper.changes.in \
    rpm/harbour-clipper.changes.run.in \
    rpm/harbour-clipper.spec \
    translations/*.ts \
    harbour-clipper.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
#CONFIG += sailfishapp_i18n


# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
#TRANSLATIONS += translations/harbour-clipper-de.ts
