#include <QAudioRecorder>
#include <QUrl>
#include <QDir>

#include "audio-recorder.h"

AudioRecorder :: AudioRecorder ( QObject * parent ) : QObject ( parent ) {
    q_audioRecorder = new QAudioRecorder ( this );

    q_audioRecorder -> setOutputLocation ( QUrl (QDir::homePath() + "/.cache/de.poetaster.de/harbour-clipper/recordedAudio.wav") );
    q_audioRecorder -> setVolume( 10 );

    b_recording = false;
}

const bool &AudioRecorder :: recording ( ) const {
    return b_recording;
}

void AudioRecorder :: record ( ) {
    if ( q_audioRecorder -> state ( ) == QMediaRecorder :: StoppedState ) {
        q_audioRecorder -> record ( );

        b_recording = true;
        emit recordingChanged ( );
    }
}

void AudioRecorder :: stop ( ) {
    if ( q_audioRecorder -> state ( ) == QMediaRecorder :: RecordingState ) {
        q_audioRecorder -> stop ( );

        b_recording = false;
        emit recordingChanged ( );
    }
}
