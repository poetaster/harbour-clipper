#include <QAudioRecorder>
#include <QUrl>
#include <QDir>
#include <QString>
#include "audio-recorder.h"

AudioRecorder :: AudioRecorder ( QObject * parent ) : QObject ( parent ) {
    q_audioRecorder = new QAudioRecorder ( this );

    /*QAudioEncoderSettings audioSettings;
    audioSettings.setCodec("audio/amr");
    audioSettings.setQuality(QMultimedia::HighQuality);
    q_audioRecorder->setEncodingSettings(audioSettings);*/

    q_audioRecorder -> setOutputLocation ( QUrl (QDir::homePath() + "/.cache/de.poetaster/harbour-clipper/recordedAudio.wav") );
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
