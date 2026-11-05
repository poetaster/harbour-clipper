import QtQuick 2.6
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
import io.thp.pyotherside 1.5
Item {
    // more details AUDIO
    id:item
    //audio manipulations
    // Pythona
    function audioFadeFunction(){
        py.audioFadeFunction()
    }
    function audioVolumeFunction() {
        py.audioVolumeFunction()
    }
    function audioExtractFunction() {
        py.audioExtractFunction()
    }
    function audioMixerFunction() {
        py.audioMixerFunction()
    }
    function recordAudioFunction() {
        py.recordAudioFunction()
    }
    function audioEffectsFilters() {
        py.audioEffectsFilters()
    }
    property int fadeDir: 0
    property int filtType: 0
    property int audioNewLen: -1


    Python {
        id: py
        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../../py'));
            importModule('videox', function () {});

            // Handlers do something to QML with received infos from Pythonfile (=pyotherside.send)
            setHandler('homePathFolder', function( homeDir ) {
                tempMediaFolderPath = homeDir + "/.cache/de.poetaster/harbour-clipper/"
                //tempMediaFolderPath =  StandardPaths.temporary
                saveMediaFolderPath =  homeDir + "/Videos"
                homeDirectory = homeDir
                py.createTmpAndSaveFolder()
                py.deleteAllTMPFunction()
            });
            setHandler('loadTempMedia', function( newFilePath ) {
                idMediaPlayer.source = ""
                idMediaPlayer.source = encodeURI( newFilePath )
                py.getVideoInfo( newFilePath, "false" )
                brandNewFile = false
            });
            setHandler('extractedAudio', function( targetPath ) {
                finishedLoading = true
                banner.notify( qsTr("Audio extracted to") + "\n" + " " + targetPath + " ", Theme.highlightDimmerColor, 10000 )
            });
            setHandler('finishedSavingRenaming', function( newFilePath, newFileName, newFileType ) {
                idMediaPlayer.source = ""
                idMediaPlayer.source = newFilePath
                origMediaFilePath = newFilePath
                origMediaFileName = newFileName + "." + newFileType
                origMediaFolderPath = origMediaFilePath.replace(origMediaFileName, "")
                var origMediaFileNameArray = origMediaFileName.split(".")
                origMediaName = (origMediaFileNameArray.slice(0, origMediaFileNameArray.length-1)).join(".")
                origMediaType = origMediaFileNameArray[origMediaFileNameArray.length - 1]
                py.getVideoInfo( inputPathPy, "true" )
                undoNr = 0
                noFile = false
                idTimerDelaySetCropmarkers.start()
            });
            setHandler('deletedFile', function() {
                origMediaFilePath = ""
                origMediaFileName = ""
                origMediaFolderPath = ""
                origMediaName = ""
                origMediaType = "none"
                origVideoWidth = 0
                origVideoHeight = 0
                origCodecVideo = "none"
                origCodecAudio = "none"
                origFrameRate = 0
                origFileSize = 0
                idMediaPlayer.source = ""
                undoNr = 0
                noFile = true
            });
            setHandler('deletedLastTmp', function() {
                finishedLoading = true
            });
            setHandler('sourceVideoInfo', function( videoResolution, videoCodec, audioCodec, frameRate, pixelFormat, audioSamplerate, audioLayout, isOriginal, estimatedSize, videoRotation, playbackDuration, sampleAspectRatio, displayAspectRatio ) {
                videoResolution = videoResolution.toString()
                var videoResolutionArray= videoResolution.split("x")
                sourceVideoWidth = parseInt(videoResolutionArray[0])
                sourceVideoHeight = parseInt(videoResolutionArray[1])
                sourceSampleAspectRatio = sampleAspectRatio.toString()
                sourceDisplayAspectRatio = displayAspectRatio.toString()
                origVideoRotation = parseInt(videoRotation)
                if (origVideoRotation !== 90 && origVideoRotation !== -90 ) { origVideoRotation = 0 } // Patch: if no EXIF tag = 0
                if (isOriginal === "true") {
                    origFileSize =  ( parseInt(estimatedSize) / 1024 / 1024 ).toFixed(2)
                    origVideoWidth = sourceVideoWidth
                    origVideoHeight = sourceVideoHeight
                    origCodecVideo = videoCodec.toString()
                    origFrameRate = frameRate.toString()
                    origPixelFormat = pixelFormat.toString()
                    origCodecAudio = audioCodec.toString()
                    origSAR = sourceSampleAspectRatio
                    origDAR = sourceDisplayAspectRatio
                    if (origCodecAudio === "vorbis") { origCodecAudio = "libvorbis" } // Patch: vorbis is experimental, use libvorbis instead
                    origAudioLayout = audioLayout.toString()
                    origAudioSamplerate = audioSamplerate.toString()
                    origVideoDuration = new Date( (parseFloat(playbackDuration)*1000) ).toISOString().substr(11,8)
                    if ( (origVideoWidth >= warningLargeSize || origVideoHeight >= warningLargeSize) && brandNewFile === true ) {
                        banner.notify( qsTr("This seems to be a large file.") + "\n" + qsTr("For speed convenience you may scale it down first." ), Theme.highlightDimmerColor, 5000 )
                    }
                }
                tmpVideoFileSize =  ( parseInt(estimatedSize) / 1024 / 1024 ).toFixed(2)
            });
            setHandler('overlayVideoInfo', function( videoResolution ) {
                videoResolution = videoResolution.toString()
                var videoResolutionArray= videoResolution.split("x")
                previewVideoWidth = parseInt(videoResolutionArray[0])
                previewVideoHeight = parseInt(videoResolutionArray[1])
                croppingRatio = previewRatioFileVideo
                setCropmarkersRatio()
                idPreviewOverlayImage.source = ""
                idPreviewOverlayImage.source = overlayThumbnailPath
            });
            setHandler('errorOccured', function( messageWarning ) {
                finishedLoading = true
                undoNr = undoNr - 1
                banner.notify( qsTr("ERROR!") + "\n" + messageWarning, Theme.errorColor, 10000 )
            });
            setHandler('clearOverlayFilename', function() {
                clearOverlayFunction()
            });
            setHandler('progressPercentage', function( percentDone ) {
                processedPercent = percentDone
            });
            setHandler('previewImageCreated', function() {
                idThumbnailOverlay.source = ""
                idThumbnailOverlay.source = thumbnailPath
                thumbnailVisible = true // show thumbnail preview
            });
            setHandler('switchToAlphaFullScreen', function() {
                idComboBoxImageOverlayAlphaStretch.currentIndex = 0
            });
            setHandler('newClipCreated', function( newFilePath, newFileName ) {
                idMediaPlayer.stop()
                brandNewFile = true
                origMediaFilePath = newFilePath.toString()
                origMediaFileName = newFileName.toString()
                origMediaFolderPath = origMediaFilePath.replace(origMediaFileName.fileName, "")
                var origMediaFileNameArray = origMediaFileName.split(".")
                origMediaName = (origMediaFileNameArray.slice(0, origMediaFileNameArray.length-1)).join(".")
                origMediaType = origMediaFileNameArray[origMediaFileNameArray.length - 1]
                idMediaPlayer.source = ""
                idMediaPlayer.source = encodeURI( newFilePath )
                py.deleteAllTMPFunction()
                py.getVideoInfo( newFilePath, "true" )
                undoNr = 0
                noFile = false
                brandNewFile = true
                finishedLoading = true
                subtitleModel.clear()
            });
            setHandler('playbackDurationParsed', function( playbackDuration, targetName ) {
                if ( targetName === "previewAudioFile" ) {
                    filePreviewDuration = parseFloat(playbackDuration) * 1000 // needs milliseconds
                }
                else if ( targetName === "addStorylineModel" ) {
                    storylineAddFileDuration = (parseFloat(playbackDuration)).toFixed(1) // needs seconds
                }
            });
            setHandler('subtitleFileParsed', function( subtitleText ) {
                //console.log(subtitleText)
            });
            setHandler('imagesExtracted', function() {
                finishedLoading = true
                banner.notify( qsTr("Extracted to") + "\n" + " " + origMediaFolderPath + " ", Theme.highlightDimmerColor, 10000 )
            });
        }
        function audioFadeFunction() {
            preparePathAndUndo()
            if ( idComboBoxAudioFade.currentIndex === 0 ) {var fadeDirection = "in" }
            else if ( idComboBoxAudioFade.currentIndex === 1 ) {fadeDirection = "out" }
            if (fadeDirection === "in") {
                var fadeFrom = "0"
                var fadeLength = ((idMediaPlayer.position)/1000).toString()
            }
            if (fadeDirection === "out") {
                fadeFrom = (idMediaPlayer.position/1000).toString()
                fadeLength = ((idMediaPlayer.duration - idMediaPlayer.position)/1000).toString()
            }
            call("videox.audioFadeFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, fadeFrom , fadeLength, fadeDirection ])
        }
        function audioVolumeFunction() {
            preparePathAndUndo()
            var fromSec = ((fromPosMillisecond/1000)).toString()
            var toSec = ((toPosMillisecond/1000)).toString()
            if ( idComboBoxAudioVolume.currentIndex === 0 ) {var actionDB = "slider" }
            else if ( idComboBoxAudioVolume.currentIndex === 1 ) {actionDB = "normalize" }
            else if ( idComboBoxAudioVolume.currentIndex === 2 ) {actionDB = "mute" }
            var addVolumeDB = (idToolsRowAudioVolumeSlider.value).toString()
            call("videox.audioVolumeFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, actionDB, addVolumeDB, fromSec, toSec ])
        }
        function audioExtractFunction() {
            finishedLoading = false // since no preparePathAndUndo() we need to activate the waiting icon
            if ( idComboBoxAudioExtract.currentIndex === 0 ) {var targetCodec = "original" }
            else if ( idComboBoxAudioExtract.currentIndex === 1 ) {targetCodec = "flac" }
            else if ( idComboBoxAudioExtract.currentIndex === 2 ) {targetCodec = "wav" }
            else if ( idComboBoxAudioExtract.currentIndex === 3 ) {targetCodec = "mp3" }
            else if ( idComboBoxAudioExtract.currentIndex === 4 ) {targetCodec = "aac" }
            var targetFolderPath = origMediaFolderPath
            if (targetCodec !== "original") {
                var targetPath = origMediaFolderPath + origMediaName + "_audio" + "." + targetCodec
            }
            else {
                targetCodec = origCodecAudio.toString()
                if ( targetCodec !== "flac" && targetCodec !== "wav" && targetCodec !== "mp3" && targetCodec !== "aac" ) {
                    targetCodec = "flac"
                }
                targetPath = origMediaFolderPath + origMediaName + "_audio" + "." + targetCodec // origCodecAudio.toString()
            }
            var helperPathWav = origMediaFolderPath + origMediaName + "_audio" + ".flac"
            var mp3CompressBitrateType = "-V2"
            call("videox.audioExtractFunction", [ ffmpeg_staticPath, inputPathPy, targetPath, targetFolderPath, targetCodec, helperPathWav, mp3CompressBitrateType, fromTimestampPy, toTimestampPy ])
        }
        function audioMixerFunction() {
            preparePathAndUndo()
            var fromSec = ((fromPosMillisecond/1000)).toString()
            var toSec = ((toPosMillisecond/1000)).toString()
            var overlayDuration = (toPosMillisecond/1000 - fromPosMillisecond/1000).toString()
            var volumeFactorBase = (idToolsRowAudioMixerVolumeSliderBase.value).toString()
            var volumeFactorOver = (idToolsRowAudioMixerVolumeSliderOver.value).toString()
            var audioDelayMS = (fromPosMillisecond).toString()
            var fadeDurationIn = (idToolsAudioMixereFadeIn.text).toString()
            var fadeDurationOut = (idToolsAudioMixereFadeOut.text).toString()
            var currentPosition = (idMediaPlayer.position/1000).toString()
            var currentFileLength = (idMediaPlayer.duration/1000).toString()
            if ( idComboBoxAudioNewLength.currentIndex === 0 ) { var getLengthFrom = "newFile" }
            else if ( idComboBoxAudioNewLength.currentIndex === 1 ) { getLengthFrom = "betweenMarkers" }
            call("videox.audioMixerFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, addAudioPath, origCodecAudio, fromSec, toSec, overlayDuration, volumeFactorBase, volumeFactorOver, audioDelayMS, fadeDurationIn, fadeDurationOut, currentPosition, getLengthFrom, currentFileLength ])
        }
        function recordAudioFunction() {
            preparePathAndUndo()
            var currentFileLength = (idMediaPlayer.duration/1000).toString()
            var currentPosition = recordingOverlayStart // get info from idWatchdog_recordAudio
            var volumeFactorBase = (idToolsRowAudioMixerVolumeSliderBase.value).toString()
            var volumeFactorOver = (idToolsRowAudioMixerVolumeSliderOver.value * 2).toString()
            var fadeDurationIn = "0.25" // (idToolsAudioMixereFadeIn.text).toString()
            var fadeDurationOut = "0.25" // (idToolsAudioMixereFadeOut.text).toString()
            call("videox.recordAudioFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, recordAudioPath, currentFileLength, currentPosition, origCodecAudio, fadeDurationIn, fadeDurationOut, volumeFactorBase, volumeFactorOver ])
        }
        function audioEffectsFilters() {
            var filterType
            if ( idComboBoxAudioFilters.currentIndex === 0 ) { filterType = "denoise"  }
            if ( idComboBoxAudioFilters.currentIndex === 1 ) { filterType = "echo"  }
            if ( idComboBoxAudioFilters.currentIndex === 2 ) { filterType = "highpass"  }
            if ( idComboBoxAudioFilters.currentIndex === 3 ) { filterType = "lowpass" }

            preparePathAndUndo()
            var fromSec = ((fromPosMillisecond/1000)).toString()
            var toSec = ((toPosMillisecond/1000)).toString()
            if ( filterType === "denoise" ) {
                if (idComboBoxAudioFiltersDenoise.currentIndex === 0) { var effectTypeValue = "afftdn=nt=w:om=o" } // ToDo: more options, see documentation
                else if (idComboBoxAudioFiltersDenoise.currentIndex === 1) { effectTypeValue = "anlmdn=o=o" } // ToDo: more options, see documentation
            }
            else if (filterType === "highpass") {
                effectTypeValue = "highpass=f=" + (idToolsAudioFiltersFrequencyHighpass.text).toString()
            }
            else if (filterType === "lowpass") {
                effectTypeValue = "lowpass=f=" + (idToolsAudioFiltersFrequencyLowpass.text).toString()
            }
            else if (filterType === "echo") {
                if (idComboBoxAudioFiltersEcho.currentIndex === 0) { // standard
                    var in_gain = "0.6"
                    var out_gain = "0.3"
                    var delays = "1000"
                    var decays = "0.5"
                }
                else if (idComboBoxAudioFiltersEcho.currentIndex === 1) { // double instruments
                    in_gain = "0.8"
                    out_gain = "0.88"
                    delays = "60"
                    decays = "0.4"
                }
                else if (idComboBoxAudioFiltersEcho.currentIndex === 2) { // mountain concert
                    in_gain = "0.8"
                    out_gain = "0.9"
                    delays = "1000"
                    decays = "0.3"
                }
                else if (idComboBoxAudioFiltersEcho.currentIndex === 3) { // robot style
                    in_gain = "0.8"
                    out_gain = "0.88"
                    delays = "6"
                    decays = "0.4"
                }
                effectTypeValue = "aecho=in_gain=" + in_gain + ":out_gain=" + out_gain + ":delays=" + delays + ":decays=" + decays
            }
            console.log(filterType)
            console.log(effectTypeValue)
            call("videox.audioEffectsFilters", [ ffmpeg_staticPath, inputPathPy, outputPathPy, fromSec, toSec, effectTypeValue, origCodecAudio, filterType ])
        }

        function deleteAllTMPFunction() {
            undoNr = 0
            call("videox.deleteAllTMPFunction", [ tempMediaFolderPath ])
        }
        function getVideoInfo( pathToFile, isOriginal ) {
            var thumbnailSec = "0.25"
            if (undoNr === 0) { isOriginal = "true" } // Patch for undo when back to first
            call("videox.getVideoInfo", [ pathToFile, isOriginal, thumbnailPath, thumbnailSec ])
        }

        onError: {
            // when an exception is raised, this error handler will be called
            if (debug) {
                console.log('python error: ' + traceback);
                banner.notify( qsTr("Pthon Error") + "\n" + " " + traceback + " ", Theme.highlightDimmerColor, 100000 )
            }
        }
        onReceived: {
            // asychronous messages from Python arrive here via pyotherside.send()
            if (debug) console.log('got message from python: ' + data);
        }
    } // end python

    Row {
        id: idToolsRowAudioFade
        visible: (mainToolbar.buttonAudio.selected && audioToolbar.buttonFade.selected )
        x: spacerLandscapeLowerToolRow
        width: mainToolbar.width - 2 * spacerLandscapeLowerToolRow

        Item {
            width: mainToolbar.x
            height: standardDetailItemHeight
        }
        ComboBox {
            id: idComboBoxAudioFade
            width: parent.width
            description: qsTr("direction")
            menu: ContextMenu {
                MenuItem { text: qsTr("in - louder") }
                MenuItem { text: qsTr("out - mute") }
            }
            onClicked: {
               fadeDir = currentIndex
            }
        }
    }
    Row {
        id: idToolsRowAudioVolume
        visible: (mainToolbar.buttonAudio.selected && audioToolbar.buttonVolume.selected )
        x: spacerLandscapeLowerToolRow
        width: mainToolbar.width - 2 * spacerLandscapeLowerToolRow

        Item {
            width: mainToolbar.x
            height: standardDetailItemHeight
        }
        ComboBox {
            id: idComboBoxAudioVolume
            width: ( currentIndex !== 0 ) ? parent.width : (parent.width / 6 * 2)
            description: qsTr("adjustment")
            menu: ContextMenu {
                MenuItem { text: qsTr("manual") }
                MenuItem { text: qsTr("normalize") }
                MenuItem { text: qsTr("mute") }
            }
        }
        Slider {
            id: idToolsRowAudioVolumeSlider
            visible: ( idComboBoxAudioVolume.currentIndex === 0 )
            width: parent.width / 6 * 4
            leftMargin: Theme.paddingMedium * 1.1
            rightMargin: leftMargin
            minimumValue: -10
            maximumValue: 10
            value: 0
            stepSize: 0.5
            handleVisible: false
            color: Theme.primaryColor

            Label {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -Theme.paddingSmall / 2
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor //highlightColor
                text: (idToolsRowAudioVolumeSlider.value >= 0) ? ("+" + idToolsRowAudioVolumeSlider.value + " " + qsTr(" dB")) : (idToolsRowAudioVolumeSlider.value + " " + qsTr(" dB"))
            }
        }
    }
    Row {
        id: idToolsRowAudioFilters
        visible: (mainToolbar.buttonAudio.selected && audioToolbar.buttonFilters.selected )
        x: spacerLandscapeLowerToolRow
        width: mainToolbar.width - 2 * spacerLandscapeLowerToolRow

        Item {
            width: mainToolbar.x
            height: standardDetailItemHeight
        }
        ComboBox {
            id: idComboBoxAudioFilters
            width: parent.width / 6 * 2
            description: qsTr("effects")
            menu: ContextMenu {
                MenuItem { text: qsTr("denoise") }
                MenuItem { text: qsTr("add echo") }
                MenuItem { text: qsTr("high pass") }
                MenuItem { text: qsTr("low pass") }
            }
            onClicked: {
                filtType = currentIndex
            }
        }
        ComboBox {
            id: idComboBoxAudioFiltersDenoise
            visible: idComboBoxAudioFilters.currentIndex === 0
            width: parent.width / 6 * 4
            description: qsTr("denoiser type")
            menu: ContextMenu {
                MenuItem { text: qsTr("afftdn") }
                MenuItem { text: qsTr("anlmdn") }
            }
        }
        ComboBox {
            id: idComboBoxAudioFiltersEcho
            visible: idComboBoxAudioFilters.currentIndex === 1
            width: parent.width / 6 * 4
            description: qsTr("echo type")
            menu: ContextMenu {
                MenuItem { text: qsTr("standard") }
                MenuItem { text: qsTr("double instuments") }
                MenuItem { text: qsTr("mountain concert") }
                MenuItem { text: qsTr("robot style") }
            }
        }
        TextField {
            id: idToolsAudioFiltersFrequencyHighpass
            visible: idComboBoxAudioFilters.currentIndex === 2
            width: parent.width / 6 * 4
            height: Theme.itemSizeMedium
            textTopMargin: Theme.paddingMedium
            text: "200" // highpass removes bass < 200 Hz
            color: Theme.highlightColor
            inputMethodHints: Qt.ImhDigitsOnly
            validator: IntValidator { bottom: 0; top: 20000 }
            EnterKey.onClicked: {
                if (idToolsAudioFiltersFrequencyHighpass.text.length < 1 || idToolsAudioFiltersFrequencyHighpass.text < 0 ) {
                    idToolsAudioFiltersFrequencyHighpass.text = "200"
                }
                idToolsAudioFiltersFrequencyHighpass.focus = false
            }
            Label {
                anchors.top: parent.bottom
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: qsTr("remove below frequency (Hz)")
            }
        }
        TextField {
            id: idToolsAudioFiltersFrequencyLowpass
            visible: idComboBoxAudioFilters.currentIndex === 3
            width: parent.width / 6 * 4
            height: Theme.itemSizeMedium
            textTopMargin: Theme.paddingMedium
            text: "2000" // lowpass removes heights > 2000 Hz
            color: Theme.highlightColor
            inputMethodHints: Qt.ImhDigitsOnly
            validator: IntValidator { bottom: 0; top: 20000 }
            EnterKey.onClicked: {
                if (idToolsAudioFiltersFrequencyLowpass.text.length < 1 || idToolsAudioFiltersFrequencyLowpass.text < 0 ) {
                    idToolsAudioFiltersFrequencyLowpass.text = "2000"
                }
                idToolsAudioFiltersFrequencyLowpass.focus = false
            }
            Label {
                anchors.top: parent.bottom
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: qsTr("remove above frequency (Hz)")
            }
        }
    }
    Row {
        id: idToolsRowAudioExtract
        visible: (mainToolbar.buttonAudio.selected && audioToolbar.buttonExtract.selected )
        x: spacerLandscapeLowerToolRow
        width: mainToolbar.width - 2 * spacerLandscapeLowerToolRow

        Item {
            width: mainToolbar.x
            height: standardDetailItemHeight
        }
        ComboBox {
            id: idComboBoxAudioExtract
            width: parent.width
            description: qsTr("codec")
            menu: ContextMenu {
                MenuItem { text: qsTr("source") + " [" + origCodecAudio  + "]" }
                MenuItem { text: qsTr("flac") }
                MenuItem { text: qsTr("wav") }
                MenuItem { text: qsTr("mp3") }
                MenuItem { text: qsTr("acc") }
            }
        }
    }

    Row {
        id: idToolsRowAudioMixer1a
        visible: (mainToolbar.buttonAudio.selected && audioToolbar.buttonMixer.selected )
        x: spacerLandscapeLowerToolRow
        width: mainToolbar.width - 2 * spacerLandscapeLowerToolRow
        //anchors.bottom:	idToolsRowAudioMixer1bRecorder.top
        anchors.top:	idToolsRowAudioExtract.top

        Item {
            width: mainToolbar.x
            height: standardDetailItemHeight
        }
        ComboBox {
            id: idComboBoxAudioNewLength
            width: parent.width / 6 * 3
            description: (currentIndex === 0 ) ? qsTr("use overlay duration") : qsTr("cut or loop overlay to fill")
            menu: ContextMenu {
                MenuItem { text: qsTr("start at cursor") }
                MenuItem { text: qsTr("between markers") }
            }
            onClicked: {
                audioNewLen = currentIndex
            }
        }
        TextField {
            id: idToolsAudioMixereFadeIn
            width: parent.width / 6 * 1.5
            height: Theme.itemSizeMedium
            textTopMargin: Theme.paddingMedium
            text: "0"
            color: Theme.highlightColor
            inputMethodHints: Qt.ImhDigitsOnly
            validator: IntValidator { bottom: 0; top: 99 }
            EnterKey.onClicked: {
                if (idToolsAudioMixereFadeIn.text.length < 1 || idToolsAudioMixereFadeIn.text < 0 ) {
                    idToolsAudioMixereFadeIn.text = "0"
                }
                idToolsAudioMixereFadeIn.focus = false
            }
            Label {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Theme.paddingSmall / 4 * 3
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: "sec"
            }
            Label {
                anchors.top: parent.bottom
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: qsTr("fade in")
            }
        }
        TextField {
            id: idToolsAudioMixereFadeOut
            width: parent.width / 6 * 1.5
            height: Theme.itemSizeMedium
            textTopMargin: Theme.paddingMedium
            text: "0"
            color: Theme.highlightColor
            inputMethodHints: Qt.ImhDigitsOnly
            validator: IntValidator { bottom: 0; top: 99 }
            EnterKey.onClicked: {
                if (idToolsAudioMixereFadeOut.text.length < 1 || idToolsAudioMixereFadeOut.text < 0 ) {
                    idToolsAudioMixereFadeOut.text = "0"
                }
                idToolsAudioMixereFadeOut.focus = false
            }
            Label {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Theme.paddingSmall / 4 * 3
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: "sec"
            }
            Label {
                anchors.top: parent.bottom
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: qsTr("fade out")
            }
        }
    }
    Row {
        id: idToolsRowAudioMixer1bRecorder
        visible: ( mainToolbar.buttonAudio.selected && audioToolbar.buttonRecorder.selected )
        x: spacerLandscapeLowerToolRow
        width: mainToolbar.width - 2 * spacerLandscapeLowerToolRow
        anchors.top: idToolsRowAudioMixer1a.bottom

        Item {
            width: mainToolbar.x
            height: standardDetailItemHeight
        }

        Label {
            width: parent.width
            height: standardDetailItemHeight
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Label.WordWrap
            text:  qsTr("Manually mute device speaker if you do not use headsets. Otherwise speaker output will be re-recorded.")
        }
    }

    Row {
        id: idToolsRowAudioMixer2
        visible: (mainToolbar.buttonAudio.selected && (audioToolbar.buttonMixer.selected || audioToolbar.buttonRecorder.selected) )
        x: spacerLandscapeLowerToolRow
        width: mainToolbar.width - 2 * spacerLandscapeLowerToolRow
        anchors.top: idToolsRowAudioMixer1bRecorder.bottom

        Item {
            width: mainToolbar.x
            height: standardDetailItemHeight
        }
        ValueButton {
            visible: audioToolbar.buttonRecorder.selected
            width: parent.width / 6 * 2
            height: standardDetailItemHeight
            value: qsTr("recording")
            valueColor: Theme.primaryColor //highlightColor
            description: qsTr("overlay audio")
        }
        ValueButton {
            visible: audioToolbar.buttonMixer.selected
            width: parent.width / 6 * 2
            enabled: ( noFile === false && finishedLoading === true )
            height: standardDetailItemHeight
            value: (addAudioLoaded === false) ? qsTr("[none]"): ( addAudioName )
            description: qsTr("overlay audio")
            onClicked: { pageStack.push( addFilePickerPageAudio ) }
        }
        Slider {
            id: idToolsRowAudioMixerVolumeSliderOver
            width: parent.width / 6 * 4
            leftMargin: Theme.paddingMedium * 1.1
            rightMargin: leftMargin
            minimumValue: 0
            maximumValue: 2
            value: 1
            stepSize: 0.01
            handleVisible: false
            color: Theme.primaryColor

            Label {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -Theme.paddingSmall / 2
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor //highlightColor
                text: qsTr("volume") + " " + Math.round(parent.value * 100) + " %"
            }
        }
    }

    Row {
        id: idToolsRowAudioMixer3
        visible: (mainToolbar.buttonAudio.selected && (audioToolbar.buttonMixer.selected || audioToolbar.buttonRecorder.selected) )
        x: spacerLandscapeLowerToolRow
        width: mainToolbar.width - 2 * spacerLandscapeLowerToolRow
        anchors.top:idToolsRowAudioMixer2.bottom
        Item {
            width: mainToolbar.x
            height: standardDetailItemHeight
        }
        ValueButton {
            width: parent.width / 6 * 2
            height: standardDetailItemHeight
            value: qsTr("source")
            valueColor: Theme.primaryColor
            description: qsTr("current audio")
        }
        Slider {
            id: idToolsRowAudioMixerVolumeSliderBase
            width: parent.width / 6 * 4
            leftMargin: Theme.paddingMedium * 1.1
            rightMargin: leftMargin
            minimumValue: 0
            maximumValue: 2
            value: 0.5
            stepSize: 0.01
            handleVisible: false
            color: Theme.primaryColor

            Label {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -Theme.paddingSmall / 2
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor //highlightColor
                text: qsTr("volume") + " " + Math.round(parent.value * 100) + " %"
            }
        }
    }

}
