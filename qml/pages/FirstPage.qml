import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0 // File-Loader
import QtMultimedia 5.6 // Audio + Video Support
//import QtFeedback 5.0 // vibration feedback
import io.thp.pyotherside 1.5
import AudioRecorder 1.0 // custom qt audio recorder

Page {
    id: page
    allowedOrientations: Orientation.All
    onOrientationTransitionRunningChanged: {
        delayShowCropMarkers = true
        idTimerDelaySetCropmarkers.start()
    }
    onOrientationChanged: {
        if ( page.orientation === Orientation.Landscape ) { spacerLandscapeLowerToolRow = page.width / 14 }
        else if ( page.orientation === Orientation.Portrait ) { spacerLandscapeLowerToolRow = 0 }
    }

    // file and folder variables
    property bool debug: true
    property string origMediaFilePath
    property string origMediaFileName : "none"
    property string origMediaFolderPath
    property string origMediaName
    property string origMediaType : "none"
    property var origVideoWidth : 0
    property var origVideoHeight : 0
    property var origCodecVideo : "none"
    property var origCodecAudio : "none"
    property var origFrameRate : 0
    property var origPixelFormat : "none"
    property var origAudioSamplerate : 0
    property var origAudioLayout : "none"
    property var origFileSize : 0
    property var origVideoRotation : 0
    property var origVideoDuration : "00:00:00"
    property var origSAR : "0:0"
    property var origDAR : "0:0"
    property string homeDirectory
    property string tempMediaFolderPath: StandardPaths.home + '/.cache/de.poetaster/harbour-clipper'
    property string tempMediaType : "mkv"
    property string ffmpeg_staticPath : "/usr/bin/ffmpeg"
    property string overlaysFolder : "/usr" + "/share" + "/harbour-clipper" + "/qml" + "/overlays/"
    property string filterFolder : "/usr" + "/share" + "/harbour-clipper" + "/qml" + "/filters/"
    property string outputPathPy
    property string inputPathPy : decodeURIComponent( "/" + idMediaPlayer.source.toString().replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"") )
    property string saveMediaFolderPath // : "/home" + "/nemo" + "/Videos" + "/Clipper/"
    //property string saveMediaFolderPath : StandardPaths.home + '/Videos'
    property string lastTmpMedia2delete
    property var thumbnailPath : tempMediaFolderPath + "thumbnail.png"
    property var overlayThumbnailPath : tempMediaFolderPath + "thumbnail_overlay.png"
    property bool thumbnailVisible : false
    property var tmpVideoFileSize : 0
    property var openingArguments : Qt.application.arguments //[0]=app-path, [1]=file-path
    property bool brandNewFile : true
    property var recordAudioPath : tempMediaFolderPath + "recordedAudio.wav" // pulse recorder can only produce wav
    property var subtitleTempPath : tempMediaFolderPath + "subtitle.srt" // create manual subtitles here

    // UI variables
    property var warningLargeSize : 1920 // show warning on loading, this might take long to process
    property int undoNr : 0
    property var finishedLoading : true
    property var clipboardAvailable : false
    property bool noFile : true
    property var plusMinusInfo : ""
    property var itemsToolbar : 5
    property var fontSizePreview : Theme.fontSizeExtraLarge
    property bool trimAreaVisible : (idButtonCut.down && idButtonCutTrim.down) ? true : false
    property bool cropAreaVisible : ( (idButtonCut.down && idButtonCutCrop.down)
                                     || (idButtonImage.down && idButtonImageEffects.down && idComboBoxImageEffects.currentIndex === 0 && idComboBoxImageEffectsBasics.currentIndex === 1 ) // blur
                                     || (idButtonImage.down && idButtonImageOverlays.down && overlayFilePath !== "" && (idComboBoxImageOverlayType.currentIndex === 0 ||  idComboBoxImageOverlayType.currentIndex === 1 || (idComboBoxImageOverlayType.currentIndex === 4 && idComboBoxImageOverlayAlphaStretch.currentIndex === 1 )) )
                                     || (idButtonImage.down && idButtonImageOverlays.down && ( idComboBoxImageOverlayType.currentIndex === 2 || idComboBoxImageOverlayType.currentIndex === 3 ) )
                                     ) ? true : false
    property bool textAreaVisible : ( idButtonImage.down && idButtonImageText.down ) ? true : false
    property bool hideUpperTimeMarkers : ( cropAreaVisible === true || dragAreaText.pressed || idButtonFile.down || idMediaPlayer.height <= idTimeInfoRow.height ) ? true : false
    property bool hideLowerTimeMarkers : ( dragAreaText.pressed
                                          || idMediaPlayer.height <= idTimeInfoRow.height
                                          || dragArea1.pressed
                                          || dragArea2.pressed
                                          || (idButtonCut.down && ( idButtonCutTrim.down === false ) )
                                          || (idButtonImage.down && ( (idButtonImageEffects.down && ((idComboBoxImageEffects.currentIndex === 0 && ( (idComboBoxImageEffectsBasics.currentIndex === 0 && ( idComboBoxImageEffectsFade.currentIndex === 0 || idComboBoxImageEffectsFade.currentIndex === 1 )) || idComboBoxImageEffectsBasics.currentIndex === 5) ) // fade || reverse ||
                                                                                                 || (idComboBoxImageEffects.currentIndex === 2 && (idComboBoxImageEffectsRepair.currentIndex === 3 || idComboBoxImageEffectsRepair.currentIndex === 4 || idComboBoxImageEffectsRepair.currentIndex === 5) )  // deshake || repairFrames || stabilize ||
                                                                                                 || (idComboBoxImageEffects.currentIndex === 3 && ( idComboBoxImageEffectsFinders.currentIndex === 2 || idComboBoxImageEffectsFinders.currentIndex === 3 ) ) // blackFrame || whiteFrame
                                                                                                 || idComboBoxImageEffects.currentIndex === 4 // all frei0r effects
                                                                                                 )) //reverse only works for whole clip
                                                                     || idButtonImageGeometry.down) )
                                          || (idButtonAudio.down && (idButtonAudioFade.down || idButtonAudioRecord.down) )
                                          || (idButtonAudio.down && idButtonAudioMixer.down && idComboBoxAudioNewLength.currentIndex === 0 )
                                          || (idButtonAudio.down && idButtonAudioFilters.down && idComboBoxAudioFilters.currentIndex === 1 ) // echo effects do not support yet timeline editing
                                          || (idButtonCollage.down && ( idButtonCollageSubtitle.down === false || (idButtonCollageSubtitle.down === true && idComboBoxCollageSubtitleAdd.currentIndex === 0) ) )
                                          || idButtonFile.down
                                         ) ? true : false
    property var lastToolsButtonPressed : "Cut"
    property var backColorTools : Theme.rgba(Theme.primaryColor, 0.1) // "transparent" // Theme.rgba(Theme.highlightDimmerColor, 0.5)
    property var standardDetailItemHeight : 0
    property var minTrimLength : 750 //ms -> can't find any i-frames at 500ms, so needs something to merge later
    property var spacerLandscapeLowerToolRow : 0
    property var processedPercent : 0
    property var oldSlideshowHeight : 0
    property var oldStorylineHeight : 0
    property var oldSubtitleHeight : 0

    // UI crop handles variables
    property bool delayShowCropMarkers : false
    property var croppingRatio : 0
    property var oldRatioCrop : 0
    property var padRatioText : "1/1"
    property var padRatio : 1
    property var handleWidth : 2* Theme.paddingLarge
    property bool stretchOversizeActive : false // true
    property var oldPosX1
    property var oldPosY1
    property var diffX1
    property var diffY1
    property var stopX1
    property var oldPosX2
    property var oldPosY2
    property var diffX2
    property var diffY2
    property var stopX2

    property int oldmouseX
    property int oldmouseY
    property var oldWidth
    property var oldHeight
    property var oldFullAreaHeight
    property var oldFullAreaWidth
    property var oldWhichSquareLEFT
    property var oldWhichSquareUP

    property var cropX
    property var cropY
    property var cropWidth
    property var cropHeight
    property var scaleDisplayFactorCrop : ( origVideoRotation !== 90 && origVideoRotation !== -90 ) ? (sourceVideoWidth / idMediaPlayer.width) : ( sourceVideoHeight / idMediaPlayer.width )
    property var startRecordingHandlePosX : 0

    // add and overlay variables
    property var addTextColor : "white"
    property var addTextboxColor : "black"
    property var addTextboxPlusFactor : 1.1
    property var standardFont : Theme.fontFamily
    property var customFontFilePath
    property var customFontName
    property bool fontFileLoaded : false
    property var drawRectangleColor : "black"
    property var drawRectangleThickness
    property var baseFrameThickness : Theme.paddingSmall
    property var colorToAlpha : "black"

    // media variables
    property var fromPosMillisecond : 0
    property var toPosMillisecond : 0
    property var fromTimestampPy : new Date(fromPosMillisecond).toISOString().substr(11,12)
    property var toTimestampPy : new Date(toPosMillisecond).toISOString().substr(11,12)

    property var sourceVideoWidth : 0
    property var sourceVideoHeight : 0
    property var sourceSampleAspectRatio : "1:1"
    property var sourceDisplayAspectRatio : "0:0"
    property var origVideoRatio : (sourceVideoWidth / sourceVideoHeight)

    property var cubeFilePath : ""
    property var cubeFileName
    property var cubeFileNamePure
    property bool cubeFileLoaded : false

    property var overlayFilePath : ""
    property var overlayFileName
    property var overlayFileNamePure
    property bool overlayFileLoaded : false

    property var addFilePath : ""
    property var addFileName
    property var addFileNamePure
    property bool addFileLoaded : false

    property var addAudioPath : ""
    property var addAudioName
    property var addAudioNamePure
    property bool addAudioLoaded : false

    property var addSubtitlePath : ""
    property var addSubtitleName
    property var addSubtitleNamePure
    property bool addSubtitleLoaded : false

    property bool recordingAudioState : false
    property var recordingOverlayStart : 0

    // overlayPreviewVariables
    property var previewImageWidth : idPreviewOverlayImage.sourceSize.width
    property var previewImageHeight : idPreviewOverlayImage.sourceSize.height
    property var previewRatioFileImage : previewImageWidth / previewImageHeight
    property var previewVideoWidth : 1
    property var previewVideoHeight : 1
    property var previewRatioFileVideo: previewVideoWidth / previewVideoHeight
    property var previewAlphaType
    property var filePreviewDuration : 0
    property var resultingFilePreviewWidth : (page.width - 2*(Theme.paddingLarge + addThemeSliderPaddingSides )) / idMediaPlayer.duration * filePreviewDuration

    // collage variables
    property string allSelectedPathsSlideshow : ""
    property string allSelectedDurationsSlideshow : ""
    property string allSelectedTransitionsSlideshow : ""
    property string allSelectedTransitionDurationsSlideshow : ""

    property var slideshowAddFilePath
    property var slideshowAddFileName
    property bool slideshowAddFileLoaded : false

    property string allSelectedPathsStoryline : ""
    property string allSelectedTransitionsStoryline : ""
    property string allSelectedTransitionDurationsStoryline : ""

    property var storylineAddFilePath
    property var storylineAddFileName
    property bool storylineAddFileLoaded : false
    property var storylineAddFileDuration

    property var addSubtitleContainer
    property bool showHintSavingSubtitles : false

    // Patch: when Theme changes: adjust slider markings, since slider has different width on
    property var mainColor : Theme.primaryColor
    property var addThemeSliderPaddingSides : 0

    onMainColorChanged: {
        checkThemechangeAdjustMarkerPadding()
    }


    // autostart items
    Component.onCompleted: {
        console.debug(StandardPaths.home)
        py.getHomePath() // get home path for multiuser environments
        standardDetailItemHeight = idToolsRowCutAdd.height * 4 / 3  // Patch: 1 px sometimes needed???
        openWithPath()
        checkThemechangeAdjustMarkerPadding()
    }


    // watchdogs: when entering or leaving certain tools
    Item {
        id: idWatchdog_ratioChangeOverlay
        enabled: ( idButtonImage.down && idButtonImageOverlays.down&& ( overlayFilePath !== "" || idComboBoxImageOverlayType.currentIndex === 2 || idComboBoxImageOverlayType.currentIndex === 3 ) ) ? true : false
        onEnabledChanged: {
            if ( idButtonImage.down && idButtonImageOverlays.down && ( overlayFilePath !== "" || idComboBoxImageOverlayType.currentIndex === 2 || idComboBoxImageOverlayType.currentIndex === 3 ) ) { // on_enter
                if ( idComboBoxImageOverlayType.currentIndex === 0 ) { croppingRatio = previewRatioFileImage }
                else if ( idComboBoxImageOverlayType.currentIndex === 1 ) { croppingRatio = previewRatioFileVideo }
                else if ( idComboBoxImageOverlayType.currentIndex === 4 ) { croppingRatio = previewRatioFileVideo } //ToDo: give its own ratio
                else { croppingRatio = 0 }
                setCropmarkersRatio()
            }
        }
    }
    Item {
        id: idWatchdog_ratioChangeBlur
        enabled: ( idButtonImage.down && idButtonImageEffects.down && idComboBoxImageEffects.currentIndex === 0 && idComboBoxImageEffectsBasics.currentIndex === 1 ) ? true : false
        onEnabledChanged: {
            if ( idButtonImage.down && idButtonImageEffects.down && idComboBoxImageEffects.currentIndex === 0 && idComboBoxImageEffectsBasics.currentIndex === 1 ) { // on_enter
                croppingRatio = 0
                setCropmarkersRatio()
            }
        }
    }
    Item {
        id: idWatchdog_ratioChangeCrop
        enabled: ( idButtonCut.down && idButtonCutCrop.down ) ? true : false
        onEnabledChanged: {
            if ( idButtonCut.down && idButtonCutCrop.down ) { // on_enter
                croppingRatio = oldRatioCrop
                setCropmarkersRatio()
            }
            else { // on_leave
                oldRatioCrop = croppingRatio
            }
        }
    }

    Timer {
        id: idTimerShowInfoPlusMinus
        interval: 750
        running: false
        repeat: false
        onTriggered: {
            //idTimerShowInfoPlusMinus.stop()
        }
    }
    Timer {
        id: idTimerShowErrorLengthOutside
        interval: 2000
        running: false
        repeat: false
    }
    Timer {
        id: idTimerDelaySetCropmarkers
        interval: 1000 // 750ms still give some errors, since too early when loading file
        running: false
        repeat: false
        onTriggered: {
            setCropmarkersRatio()
            delayShowCropMarkers = false
        }
    }
    Timer {
        id: idTimerScrollToBottom
        interval: 250
        running: false
        repeat: false
        onTriggered: {
            idSilicaFlickable.scrollToBottom()
        }
    }
    Timer {
        id: idTimerRecalculateSlideshowListHeight
        interval: 50
        running: false
        repeat: false
        onTriggered: {
            oldSlideshowHeight = listView.contentHeight
        }
    }
    Timer {
        id: idTimerRecalculateStorylineListHeight
        interval: 50
        running: false
        repeat: false
        onTriggered: {
            oldStorylineHeight = listView2.contentHeight
        }
    }    
    Timer {
        id: idTimerRecalculateSubtitleListHeight
        interval: 50
        running: false
        repeat: false
        onTriggered: {
            oldSubtitleHeight = listView3.contentHeight
        }
    }
    Timer {
        id: idTimerDelayRecording
        interval: 450
        running: false
        repeat: false
        onTriggered: {
            recordingOverlayStart = (idMediaPlayer.position/1000).toString()
            recordingAudioState = true
            idMediaPlayer.play()
            thumbnailVisible = false
            audioRecorder_Sample.record()
        }
    }

    RemorsePopup {
        id: remorse
        onTriggered: py.deleteFile()
    }

    Component {
       id: filePickerPage
       FilePickerPage {
           title: qsTr("Select video")
           nameFilters: [ '*.mp4', '*.mkv', '*.flv', '*.mpeg', '*.avi', '*.mov', '*.m4v' ]
           onSelectedContentPropertiesChanged: {
               idMediaPlayer.stop()
               origMediaFilePath = selectedContentProperties.filePath.toString()
               origMediaFileName = selectedContentProperties.fileName
               origMediaFolderPath = origMediaFilePath.replace(selectedContentProperties.fileName, "")
               var origMediaFileNameArray = origMediaFileName.split(".")
               origMediaName = (origMediaFileNameArray.slice(0, origMediaFileNameArray.length-1)).join(".")
               origMediaType = origMediaFileNameArray[origMediaFileNameArray.length - 1]
               idMediaPlayer.source = ""
               idMediaPlayer.source = origMediaFilePath
               py.deleteAllTMPFunction()
               py.getVideoInfo( inputPathPy, "true" )
               undoNr = 0
               noFile = false
               brandNewFile = true
               subtitleModel.clear()
           }
       }
    }

    Component {
       id: videoPickerPage
       VideoPickerPage {
           onSelectedContentPropertiesChanged: {
               idMediaPlayer.stop()
               origMediaFilePath = selectedContentProperties.filePath.toString()
               origMediaFileName = selectedContentProperties.fileName
               origMediaFolderPath = origMediaFilePath.replace(selectedContentProperties.fileName, "")
               var origMediaFileNameArray = origMediaFileName.split(".")
               origMediaName = (origMediaFileNameArray.slice(0, origMediaFileNameArray.length-1)).join(".")
               origMediaType = origMediaFileNameArray[origMediaFileNameArray.length - 1]
               idMediaPlayer.source = ""
               idMediaPlayer.source = origMediaFilePath
               py.deleteAllTMPFunction()
               py.getVideoInfo( inputPathPy, "true" )
               undoNr = 0
               noFile = false
               brandNewFile = true
               subtitleModel.clear()
           }
       }
    }

    Component {
        id: lutHaldFilePickerPage
        FilePickerPage {
           title: qsTr("Select LUT (png, cube, 3dl)")
           nameFilters: [ '*.cube', '*.3dl', '*.png' ]
           onSelectedContentPropertiesChanged: {
               cubeFilePath = selectedContentProperties.filePath
               cubeFileName = selectedContentProperties.fileName
               var cubeFileNameNameArray = cubeFileName.split(".")
               cubeFileNamePure = (cubeFileNameNameArray.slice(0, cubeFileNameNameArray.length-1)).join(".")
               cubeFileLoaded = true
           }
        }
     }

    Component {
        id: overlayFilePickerPageImage
        ImagePickerPage {
            title: qsTr("Select overlay image")
            onSelectedContentPropertiesChanged: {
                overlayFilePath = selectedContentProperties.filePath
                overlayFileName = selectedContentProperties.fileName
                var overlayFileNameNameArray = overlayFileName.split(".")
                overlayFileNamePure = (overlayFileNameNameArray.slice(0, overlayFileNameNameArray.length-1)).join(".")
                overlayFileLoaded = true
                idPreviewOverlayImage.source = ""
                idPreviewOverlayImage.source = overlayFilePath
                croppingRatio = previewRatioFileImage
                setCropmarkersRatio()
            }
        }
    }

    Component {
        id: overlayFilePickerPageVideo
        VideoPickerPage {
            title: qsTr("Select overlay video")
            onSelectedContentPropertiesChanged: {
                overlayFilePath = selectedContentProperties.filePath
                overlayFileName = selectedContentProperties.fileName
                var overlayFileNameNameArray = overlayFileName.split(".")
                overlayFileNamePure = (overlayFileNameNameArray.slice(0, overlayFileNameNameArray.length-1)).join(".")
                overlayFileLoaded = true
                idPreviewOverlayImage.source = ""
                py.getOverlayVideoInfo( overlayFilePath )
            }
        }
    }

    Component {
        id: overlayFilePickerPageAlpha
        FilePickerPage {
            title: qsTr("Select alpha video/image")
            nameFilters: [ '*.mp4', '*.mkv', '*.flv', '*.mpeg', '*.avi', '*.mov', '*.m4v', '*.jpg', '*.jpeg', '*.png', '*.tif', '*.tiff', '*.bmp', '*.gif' ]
            onSelectedContentPropertiesChanged: {
                overlayFilePath = selectedContentProperties.filePath
                overlayFileName = selectedContentProperties.fileName
                var overlayFileNameNameArray = overlayFileName.split(".")
                overlayFileNamePure = (overlayFileNameNameArray.slice(0, overlayFileNameNameArray.length-1)).join(".")
                var addAlphaContainer = overlayFileNameNameArray[overlayFileNameNameArray.length - 1]
                overlayFileLoaded = true
                if ( addAlphaContainer === "mp4" || addAlphaContainer === "mkv" || addAlphaContainer === "flv" || addAlphaContainer === "mpeg" || addAlphaContainer === "avi" || addAlphaContainer === "mov" || addAlphaContainer === "m4v" ) {
                    previewAlphaType = "video"
                    idPreviewOverlayImage.source = ""
                    py.getOverlayVideoInfo( overlayFilePath )
                }
                else {
                    previewAlphaType = "image"
                    idPreviewOverlayImage.source = ""
                    idPreviewOverlayImage.source = overlayFilePath
                    croppingRatio = previewRatioFileImage
                    setCropmarkersRatio()
                }
            }
        }
    }

    Component {
        id: timelineFilePickerPage
        FilePickerPage {
            title: qsTr("Select video/image")
            nameFilters: [ '*.mp4', '*.mkv', '*.flv', '*.mpeg', '*.avi', '*.mov', '*.m4v', '*.jpg', '*.jpeg', '*.png', '*.tif', '*.tiff', '*.bmp', '*.gif' ]
            onSelectedContentPropertiesChanged: {
                overlayFilePath = selectedContentProperties.filePath
                overlayFileName = selectedContentProperties.fileName
                overlayFileLoaded = true
            }
        }
    }

    Component {
        id: addFilePickerPageVideo
        VideoPickerPage {
            title: qsTr("Select video to add")
            onSelectedContentPropertiesChanged: {
                addFilePath = selectedContentProperties.filePath
                addFileName = selectedContentProperties.fileName
                var addFileNameNameArray = addFileName.split(".")
                addFileNamePure = (addFileNameNameArray.slice(0, addFileNameNameArray.length-1)).join(".")
                addFileLoaded = true
            }
        }
    }

    Component {
        id: addFilePickerPageAudio
        FilePickerPage {
            title: qsTr("Select audio file")
            nameFilters: [ '*.wav', '*.mp3', '*.flac', '*.ogg', '*.aac', '*.m4a' ]
            onSelectedContentPropertiesChanged: {
                addAudioPath = selectedContentProperties.filePath
                addAudioName = selectedContentProperties.fileName
                var addFileNameNameArray = addAudioName.split(".")
                addAudioNamePure = (addFileNameNameArray.slice(0, addFileNameNameArray.length-1)).join(".")
                addAudioLoaded = true
                py.getPlaybackDuration( decodeURIComponent( "/" + addAudioPath.toString().replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"") ), "previewAudioFile" )
            }
        }
    }

    Component {
        id: addFilePickerPageSubtitle
        FilePickerPage {
            title: qsTr("Select subtitle file (ass, srt)")
            nameFilters: [ '*.ass', '*.srt' ]
            onSelectedContentPropertiesChanged: {
                addSubtitlePath = selectedContentProperties.filePath
                addSubtitleName = selectedContentProperties.fileName
                var addFileNameNameArray = addSubtitleName.split(".")
                addSubtitleNamePure = (addFileNameNameArray.slice(0, addFileNameNameArray.length-1)).join(".")
                addSubtitleContainer = (addFileNameNameArray[addFileNameNameArray.length - 1]).toString()
                addSubtitleLoaded = true
                py.parseSubtitleFile( addSubtitlePath )
            }
        }
    }

    Component {
       id: fontPickerPage
       FilePickerPage {
           title: qsTr("Select font")
           nameFilters: [ '*.ttf', '*.otf' ]
           onSelectedContentPropertiesChanged: {
               customFontFilePath = selectedContentProperties.filePath
               customFontName = selectedContentProperties.fileName
               localFont.source = selectedContentProperties.filePath
               idPaintTextPreview.font.family = localFont.name
               fontFileLoaded = true
           }
       }
    }

    Component {
        id: slideshowImagePicker
        ImagePickerPage {
            title: qsTr("Select image")
            onSelectedContentPropertiesChanged: {
                slideshowAddFilePath = selectedContentProperties.filePath
                slideshowAddFileName = selectedContentProperties.fileName
                slideshowAddFileLoaded = true
            }
        }
    }

    Component {
        id: storylineVideoPicker
        FilePickerPage {
            title: qsTr("Select video")
            nameFilters: [ '*.mp4', '*.mkv', '*.flv', '*.mpeg', '*.avi', '*.mov', '*.m4v' ]
            onSelectedContentPropertiesChanged: {
                storylineAddFilePath = selectedContentProperties.filePath
                storylineAddFileName = selectedContentProperties.fileName
                storylineAddFileLoaded = true
                py.getPlaybackDuration( decodeURIComponent( "/" + storylineAddFilePath.toString().replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"") ), "addStorylineModel" )
            }
        }
    }

    FontLoader {
        id: localFont
        source: ""
    }

    Banner {
        id: banner
    }

    AudioRecorder {
        id: audioRecorder_Sample //(( audioRecorder_Sample.recording ) ? audioRecorder_Sample.stop() : audioRecorder_Sample.record() )
        onRecordingChanged: {
            console.log("recording changed")

        }

    }

    /*
    HapticsEffect {
        id: idVibration
        duration: 200
        intensity: 10
    }
    */

    SoundEffect {
        id: recordingBeepStart
        loops: 1
        source: "/usr/share/sounds/jolla-ambient/stereo/video_record_start.wav"
    }

    SoundEffect {
        id: recordingBeepStop
        loops: 1
        source: "/usr/share/sounds/jolla-ambient/stereo/video_record_stop.wav"
    }

    ListModel {
        id: slideshowModel
    }

    ListModel {
        id: storylineModel
    }

    ListModel {
        id: subtitleModel
    }

    Python {
        id: py
        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../py'));
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



        // file operations
        function getHomePath() {
            call("videox.getHomePath", [])
        }
        function createTmpAndSaveFolder() {
            call("videox.createTmpAndSaveFolder", [ tempMediaFolderPath, saveMediaFolderPath ])
        }
        function deleteAllTMPFunction() {
            undoNr = 0
            call("videox.deleteAllTMPFunction", [ tempMediaFolderPath ])
        }
        function deleteLastTMPFunction() {
            call("videox.deleteLastTmpFunction", [ lastTmpMedia2delete ])
        }
        function deleteFile() {
            idMediaPlayer.stop()
            py.deleteAllTMPFunction()
            call("videox.deleteFile", [ origMediaFilePath ])
        }
        function renameOriginal() {
            idMediaPlayer.stop()
            py.deleteAllTMPFunction()
            var newFilePath = origMediaFolderPath + idToolsRowFileRenameText.text + "." + origMediaType
            var newFileName = idToolsRowFileRenameText.text
            var newFileType = origMediaType
            call("videox.renameOriginal", [ origMediaFilePath, newFilePath, newFileName, newFileType ])
        }
        function getVideoInfo( pathToFile, isOriginal ) {
            var thumbnailSec = "0.25"
            if (undoNr === 0) { isOriginal = "true" } // Patch for undo when back to first
            call("videox.getVideoInfo", [ pathToFile, isOriginal, thumbnailPath, thumbnailSec ])
        }
        function getOverlayVideoInfo( pathToFile ) {
            var overlayPath = "/" + pathToFile.toString().replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"")
            call("videox.getOverlayVideoInfo", [ overlayPath, overlayThumbnailPath, "1" ])
        }
        function createPreviewImage() {
            var thumbnailSec = new Date(idMediaPlayer.position).toISOString().substr(11,12)
            call("videox.createPreviewImage", [ inputPathPy, thumbnailPath, thumbnailSec ])
        }
        function getPlaybackDuration( pathToFile, targetName ) {
            call("videox.getPlaybackDuration", [ pathToFile, targetName ])
        }


        // cut manipulations
        function trimFunction() {
            if (idComboBoxCutTrimWhere.currentIndex === 0) {var trimWhere = "inside" }
            else if (idComboBoxCutTrimWhere.currentIndex === 1) {trimWhere = "outside" }
            if (idComboBoxCutTrimHow.currentIndex === 0) { var trimType = "fast_copy_noKeyframe" }
            else if (idComboBoxCutTrimHow.currentIndex === 1) { trimType = "fast_copy_Keyframe" }
            else if (idComboBoxCutTrimHow.currentIndex === 2) { trimType = "slow_reencode_createKeyframe" }
            var encodeCodec = origCodecVideo // "ffv1"
            var encodeFramerate = origFrameRate.toString() // usually "25"
            var endTimestampPy = new Date(idMediaPlayer.duration).toISOString().substr(11,12)
            // if any marker is too close to start or end, just use the outmost positions
            if ( (fromPosMillisecond <= minTrimLength) && ( (idMediaPlayer.duration - toPosMillisecond) <= minTrimLength ) ) { var removeInsideCase = "remove_start_end" }
            if ( (fromPosMillisecond <= minTrimLength) && ( (idMediaPlayer.duration - toPosMillisecond) > minTrimLength ) ) { removeInsideCase = "remove_start_mid" }
            if ( (fromPosMillisecond > minTrimLength) && ( (idMediaPlayer.duration - toPosMillisecond) > minTrimLength ) ) { removeInsideCase = "remove_mid_mid" }
            if ( (fromPosMillisecond > minTrimLength) && ( (idMediaPlayer.duration - toPosMillisecond) <= minTrimLength ) ) { removeInsideCase = "remove_mid_end" }
            if ( ((fromPosMillisecond <= minTrimLength) && (toPosMillisecond <= minTrimLength )) || (( (idMediaPlayer.duration - fromPosMillisecond) <= minTrimLength) && ( (idMediaPlayer.duration - toPosMillisecond) <= minTrimLength )) ) {
                removeInsideCase = "remove_too_small" // if both markers are either at start or at end
            }

            if ( removeInsideCase === "remove_too_small" ) {
                banner.notify( qsTr("Both sliders are too close to the same end." + "\n" + "< " + minTrimLength + " ms" ), Theme.errorColor, 10000 )
            }
            else if ( removeInsideCase === "remove_start_end" ) {
                banner.notify( qsTr("Would you like to delete the track?" + "\n" + qsTr("Use 'delete' in file menu.") ), Theme.errorColor, 10000 )
            }
            else {
                preparePathAndUndo()
                var fromSec = ((fromPosMillisecond/1000)).toString()
                var toSec = ((toPosMillisecond/1000)).toString()
                call("videox.trimFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, tempMediaFolderPath, fromTimestampPy, toTimestampPy, fromSec, toSec, trimWhere, trimType, encodeCodec, encodeFramerate, removeInsideCase, endTimestampPy ])
            }
        }
        function speedFunction() {
            preparePathAndUndo()
            var speedVideoFactor = (1/(idToolsCutDetailsColumnCut3SpeedSlider.value)).toString()
            var speedAudioFactor = idToolsCutDetailsColumnCut3SpeedSlider.value.toString()
            call("videox.speedFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, speedVideoFactor, speedAudioFactor ])
        }
        function cropAreaFunction() {
            preparePathAndUndo()
            generateCroppingPixelsFromHandles()
            call("videox.cropAreaFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, cropX, cropY, cropWidth, cropHeight, scaleDisplayFactorCrop ])
        }
        function padAreaFunction() {
            if ( sourceVideoWidth / sourceVideoHeight > padRatio ) {
                var padWhere = "vertical"
                if (idComboBoxCutPadUpDown.currentIndex === 0) { // size+
                    var outWidth = sourceVideoWidth
                    var outHeight = Math.round( sourceVideoWidth / padRatio )
                }
                else { // size-
                    outHeight = sourceVideoHeight
                    outWidth = Math.round( sourceVideoHeight * padRatio )
                }
            }
            else {
                padWhere = "horizontal"
                if (idComboBoxCutPadUpDown.currentIndex === 0) { // size+
                    outHeight = sourceVideoHeight
                    outWidth = Math.round( sourceVideoHeight * padRatio )
                }
                else {
                    outWidth = sourceVideoWidth
                    outHeight = Math.round( sourceVideoWidth / padRatio )
                }
            }
            var padColor = "black"
            if ( outWidth > 1920 || outHeight > 1920) {
                banner.notify( qsTr("WARNING!") + "\n"
                      + qsTr("Large output resolution detected:") + " " + outWidth + "x" + outHeight + " px.\n"
                      + qsTr("Please reduce to max 1920x1920 pixels.")
                      , Theme.errorColor, 10000 )
            }
            else {
                preparePathAndUndo()
                call("videox.padAreaFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, padRatioText, padWhere, padColor, outWidth, outHeight ])
            }
        }
        function addTimeFunction() {
            var atTimestamp = new Date(idMediaPlayer.position).toISOString().substr(11,12)
            var addLength = (idToolsRowCutAddSlider.value).toString()
            var origContainer = origMediaType
            var addVideoPath = "/" + addFilePath.toString().replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"")
            if ( idComboBoxCutAddColor.currentIndex === 0 ) {
                var addColor = "black"
                var addClipType = "blank_clip"
            }
            else if ( idComboBoxCutAddColor.currentIndex === 1 ) {
                addColor = "white"
                addClipType = "blank_clip"
            }
            else if ( idComboBoxCutAddColor.currentIndex === 2 ) {
                addColor = "black"
                addClipType = "freeze_frame"
            }
            else if ( idComboBoxCutAddColor.currentIndex === 3 ) {
                addColor = "black"
                addClipType = "video_clip"
            }
            if (idProgressSlider.value === idProgressSlider.minimumValue ) { var whereInVideo = "start" }
            else if (idProgressSlider.value >= idProgressSlider.maximumValue * 0.99) { whereInVideo = "end" } // Patch: if it does not fully reach the end
            else { whereInVideo = "middle" }
            // Patch: make sure to have a file loaded when adding a video
            if ( idComboBoxCutAddColor.currentIndex === 0 || idComboBoxCutAddColor.currentIndex === 1 || idComboBoxCutAddColor.currentIndex === 2 || (idComboBoxCutAddColor.currentIndex === 3 && addFileLoaded === true ) ) {
                preparePathAndUndo() // Patch: call this after reading idMediaPlayer.value, otherwise slider position = idMediaPlayer.stop() = 0 = "start"
                call("videox.addTimeFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, tempMediaFolderPath, whereInVideo, atTimestamp, addLength, addColor, sourceVideoWidth.toString(), sourceVideoHeight.toString(), origFrameRate.toString(), origContainer, origCodecVideo, origCodecAudio, origAudioSamplerate, origAudioLayout, origPixelFormat, sourceSampleAspectRatio, addClipType, addVideoPath ])
            }
        }
        function resizeFunction() {
            preparePathAndUndo()
            var newWidth = idToolsCutDetailsColumn3Width.text
            var newHeight = idToolsCutDetailsColumn3Height.text
            if (idComboBoxCutResizeMaindimension.currentIndex === 0) {
                var autoScale = "fixWidth"
                var applyStretch ="false"
            }
            else if (idComboBoxCutResizeMaindimension.currentIndex === 1) {
                autoScale = "fixHeight"
                applyStretch ="false"
            }
            else if (idComboBoxCutResizeMaindimension.currentIndex === 2) {
                autoScale = "fixBoth"
                applyStretch = "pad"
            }
            else if (idComboBoxCutResizeMaindimension.currentIndex === 3 ) {
                autoScale = "fixBoth"
                applyStretch = "stretch"
            }
            call("videox.resizeFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, newWidth, newHeight, autoScale, applyStretch ])
        }
        function repairFramesFunction() {
            preparePathAndUndo()
            call("videox.repairFramesFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy ])
        }
        function removeBWframesFunction( colorRemove ) {
            preparePathAndUndo()
            var amountBW = (idToolsRowImageEffectsFrameDetectionBW_amount.value).toString()  // percentage of pixels in image that have to be below threshold; default = 98.
            var thresholdBW = (idToolsRowImageEffectsFrameDetectionBW_treshold.value).toString() // threshold below which a pixel value is considered black; default = 32.
            call("videox.removeBWframesFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, colorRemove, amountBW, thresholdBW ])
        }


        // image manipulations
        function imageFadeFunction() {
            preparePathAndUndo()
            var fromSec = ((fromPosMillisecond/1000)).toString()
            var toSec = ((toPosMillisecond/1000)).toString()
            if (idComboBoxImageEffectsFade.currentIndex === 0) {var fadeDirection = "in"; var fadeCase = "cursor0" }
            else if (idComboBoxImageEffectsFade.currentIndex === 1) {fadeDirection = "out"; fadeCase = "cursor1" }
            else if (idComboBoxImageEffectsFade.currentIndex === 2) {fadeDirection = "in"; fadeCase = "marker0" }
            else if (idComboBoxImageEffectsFade.currentIndex === 3) {fadeDirection = "out"; fadeCase = "marker1" }
            if (fadeCase === "cursor0" ) { //in
                var fadeFrom = "0"
                var fadeLength = ((idMediaPlayer.position)/1000).toString()
            }
            if (fadeCase === "cursor1") { //out
                fadeFrom = (idMediaPlayer.position/1000).toString()
                fadeLength = ((idMediaPlayer.duration - idMediaPlayer.position)/1000).toString()
            }
            if (fadeCase === "marker0") { //in-marker
                fadeFrom = ((fromPosMillisecond/1000)).toString()
                fadeLength = ((toPosMillisecond - fromPosMillisecond)/1000).toString()
            }
            if (fadeCase === "marker1" ) { //out-marker
                fadeFrom = ((fromPosMillisecond/1000)).toString()
                fadeLength = ((toPosMillisecond - fromPosMillisecond)/1000).toString()
            }
            call("videox.imageFadeFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, fadeFrom , fadeLength, fadeDirection, fadeCase, fromSec, toSec ])
        }
        function imageRotateFunction() {
            preparePathAndUndo()
            if ( idComboBoxImageGeometryRotate.currentIndex === 0 ) {var rotateDirection = "1" } // +90°
            else if ( idComboBoxImageGeometryRotate.currentIndex === 1 ) {rotateDirection = "2" } // -90°
            call("videox.imageRotateFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, rotateDirection ])
        }
        function imageMirrorFunction() {
            preparePathAndUndo()
            if ( idComboBoxImageGeometryMirror.currentIndex === 0 ) {var mirrorDirection = "hflip" }
            else if ( idComboBoxImageGeometryMirror.currentIndex === 1 ) {mirrorDirection = "vflip" }
            call("videox.imageMirrorFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, mirrorDirection ])
        }
        function imageGrayscaleFunction() {
            preparePathAndUndo()
            var fromSec = ((fromPosMillisecond/1000)).toString()
            var toSec = ((toPosMillisecond/1000)).toString()
            call("videox.imageGrayscaleFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, fromSec, toSec ])
        }
        function imageNormalizeFunction() {
            preparePathAndUndo()
            var fromSec = ((fromPosMillisecond/1000)).toString()
            var toSec = ((toPosMillisecond/1000)).toString()
            call("videox.imageNormalizeFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, fromSec, toSec ])
        }
        function imageStabilizeFunction() {
            preparePathAndUndo()
            console.log("now")
            var fromSec = ((fromPosMillisecond/1000)).toString()
            var toSec = ((toPosMillisecond/1000)).toString()
            call("videox.imageStabilizeFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, fromSec, toSec ])
        }
        function imageDeshakeFunction() { // deshake does not work in latest git ffmpeg, since there is an internal error with vid.stab as of Jan21 -> use older version
            preparePathAndUndo()
            var fromSec = ((fromPosMillisecond/1000)).toString()
            var toSec = ((toPosMillisecond/1000)).toString()
            call("videox.imageDeshakeFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, tempMediaFolderPath, fromSec, toSec ])
        }
        function imageReverseFunction() {
            preparePathAndUndo()
            call("videox.imageReverseFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy  ])
        }
        function imageVibranceFunction() {
            preparePathAndUndo()
            var fromSec = ((fromPosMillisecond/1000)).toString()
            var toSec = ((toPosMillisecond/1000)).toString()
            var newValue = idToolsRowImageColorsVibranceSlider.value.toString()
            call("videox.imageVibranceFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, newValue, fromSec, toSec  ])
        }
        function imageCurveFunction( applyCurve ) {
            preparePathAndUndo()
            var fromSec = ((fromPosMillisecond/1000)).toString()
            var toSec = ((toPosMillisecond/1000)).toString()
            call("videox.imageCurveFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, applyCurve, fromSec, toSec ])
        }
        function imageLUT3dFunction( attribute, fileType ) {
            preparePathAndUndo()
            if (attribute === "extern") {
                var cubeFile = cubeFilePath
            }
            else {
                cubeFile = filterFolder + attribute // load a preset .cube file
            }
            var fromSec = ((fromPosMillisecond/1000)).toString()
            var toSec = ((toPosMillisecond/1000)).toString()
            call("videox.imageLUT3dFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, cubeFile, fromSec, toSec ])
        }
        function imageBlurFunction() {
            preparePathAndUndo()
            generateCroppingPixelsFromHandles()
            var fromSec = ((fromPosMillisecond/1000)).toString()
            var toSec = ((toPosMillisecond/1000)).toString()
            var blurIntensity = (idToolsRowImageEffectsBlurSlider.value).toString()
            if ( idComboBoxImageEffectsBlurDirection.currentIndex === 0 ) { var blurWhere = "inside" }
            else if (idComboBoxImageEffectsBlurDirection.currentIndex === 1 ) { blurWhere = "outside" }
            call("videox.imageBlurFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, fromSec, toSec, cropX, cropY, cropWidth, cropHeight, scaleDisplayFactorCrop, blurIntensity, blurWhere ])
        }
        function imageGeneralEffectFunction( effectName ) {
            preparePathAndUndo()
            var fromSec = ((fromPosMillisecond/1000)).toString()
            var toSec = ((toPosMillisecond/1000)).toString()
            if ( effectName === "unsharp" ) { // =sharpen effect
                var someValue1 = (idToolsRowImageEffectsSharpenSlider.value).toString() // luma value
                var someValue2 = "0" // (idToolsRowImageEffectsSharpenSlider2.value).toString() //chroma value
            }
            else {
                someValue1 = "0"
                someValue2 = "0"
            }
            call("videox.imageGeneralEffectFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, effectName, fromSec, toSec, someValue1, someValue2 ])
        }
        function imageColorFunction( targetAttribute ) {
            preparePathAndUndo()
            var fromSec = ((fromPosMillisecond/1000)).toString()
            var toSec = ((toPosMillisecond/1000)).toString()
            if ( targetAttribute === "brightness" ) { var targetValue = (idToolsRowImageColorsBrightnessSlider.value).toString() }
            if ( targetAttribute === "contrast" ) { targetValue = (idToolsRowImageColorsContrastSlider.value).toString() }
            if ( targetAttribute === "saturation" ) { targetValue = (idToolsRowImageColorsSaturationSlider.value).toString() }
            if ( targetAttribute === "gamma" ) { targetValue = (idToolsRowImageColorsGammaSlider.value).toString() }
            call("videox.imageColorFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, targetValue, targetAttribute, fromSec, toSec ])
        }
        function imageFrei0rFunction( ) {
            preparePathAndUndo()
            var fromSec = ((fromPosMillisecond/1000)).toString()
            var toSec = ((toPosMillisecond/1000)).toString()
            if (idComboBoxImageEffectsFrei0r.currentIndex === 0) {
                var applyEffect = "pixeliz0r"
                var useParams = "true"
                var applyParams = "0.02|0.02"
            }
            else if (idComboBoxImageEffectsFrei0r.currentIndex === 1) {
                applyEffect = "lenscorrection"
                useParams = "false"
                applyParams = "0.5|0.5|0.5|0.5"
            }
            else if (idComboBoxImageEffectsFrei0r.currentIndex === 2) {
                applyEffect = "vertigo"
                useParams = "true"
                applyParams = "0.2"
            }
            else if (idComboBoxImageEffectsFrei0r.currentIndex === 3) {
                applyEffect = "posterize"
                useParams = "false"
                applyParams = "0.2"
            }
            else if (idComboBoxImageEffectsFrei0r.currentIndex === 4) {
                applyEffect = "glow"
                useParams = "false"
                applyParams = "0"
            }
            else if (idComboBoxImageEffectsFrei0r.currentIndex === 5) {
                applyEffect = "glitch0r"
                useParams = "true"
                applyParams = "0.5" // how often appears
            }
            else if (idComboBoxImageEffectsFrei0r.currentIndex === 6) {
                applyEffect = "colgate"
                useParams = "false"
                applyParams = " #7f7f7f|0.433333" // color that should be white | colorTemperature
            }
            call("videox.imageFrei0rFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, applyEffect, applyParams, fromSec, toSec, useParams, origCodecVideo ])
        }


        //audio manipulations
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
        function audioEffectsFilters( filterType ) {
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


        //adding manipulations
        function addTextFunction() {
            preparePathAndUndo()
            var placeX = rectDragText.x + rectDragText.width/2 - idPaintTextPreview.width/2
            var placeY = rectDragText.y + rectDragText.width/2  - idPaintTextPreview.height/3.5
            var addText = idToolsImageTextInput.text
            var addTextSize = Math.round( idPaintTextPreview.font.pixelSize * scaleDisplayFactorCrop )
            if (addTextboxColor === "transparent") { var addBox = "0" } else {addBox = "1" }
            if (fontFileLoaded === false) { var fontPath = "/usr/share/fonts/sail-sans-pro/SailSansPro-Light.ttf" } else { fontPath = "/" + localFont.source.toString().replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"") }
            var addBoxBorderWidth = Math.round((idPaintTextPreviewBox.width - idPaintTextPreview.width) / 2)
            var addBoxOpacity = (idToolsRowImageTextboxOpacity.value).toString()
            var fromSec = ((fromPosMillisecond/1000)).toString()
            var toSec = ((toPosMillisecond/1000)).toString()
            call("videox.addTextFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, fontPath, addText, addTextColor, addTextSize , addBox, addTextboxColor, addBoxOpacity, addBoxBorderWidth, placeX, placeY, scaleDisplayFactorCrop, fromSec, toSec ])
        }
        function overlayOldMovieFunction() {
            preparePathAndUndo()
            var origContainer = origMediaType
            var fromSec = ((fromPosMillisecond/1000)).toString()
            var toSec = ((toPosMillisecond/1000)).toString()
            var overlayDuration = (toPosMillisecond/1000 - fromPosMillisecond/1000).toString()
            var pathOverlayVideo = overlaysFolder + "oldOverlay.mp4"
            call("videox.overlayOldMovieFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, tempMediaFolderPath, origVideoWidth, origVideoHeight, origContainer, pathOverlayVideo, fromSec, toSec, overlayDuration ])
        }
        function overlayFileFunction() {
            preparePathAndUndo()
            generateCroppingPixelsFromHandles()
            var fromSec = ((fromPosMillisecond/1000)).toString()
            var toSec = ((toPosMillisecond/1000)).toString()
            var overlayDuration = (toPosMillisecond/1000 - fromPosMillisecond/1000).toString()
            var overlayOpacity = ( idComboBoxImageOverlayType.currentIndex === 3 ) ? "1" : ( (idToolsRowImageOverlayOpacitySlider.value).toString() )
            var overlayPath = "/" + overlayFilePath.toString().replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"")
            if ( idComboBoxImageOverlayType.currentIndex === 0 ) { var overlayType = "image" }
            else if ( idComboBoxImageOverlayType.currentIndex === 1 ) { overlayType = "video" }
            else if ( idComboBoxImageOverlayType.currentIndex === 2 ) {
                overlayType = "rectangle"
                drawRectangleThickness = "fill"
            }
            else if ( idComboBoxImageOverlayType.currentIndex === 3 ) {
                overlayType = "rectangle"
                drawRectangleThickness =  (Math.round( idPreviewOverlayRectangle.border.width * scaleDisplayFactorCrop)).toString()
            }
            call("videox.overlayFileFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, overlayPath, fromSec, toSec, cropX, cropY, cropWidth, cropHeight, scaleDisplayFactorCrop, overlayOpacity, overlayType, overlayDuration, drawRectangleColor, drawRectangleThickness ])
        }
        function overlayAlphaClipFunction( pathOverlayVideo, partFull, colorKey ) {
            if (debug) console.debug("path:" + pathOverlayVideo + ' partFull:' + partFull + " colorKey:" + colorKey)
            preparePathAndUndo()
            generateCroppingPixelsFromHandles()
            var overlayOpacity = "1"
            if (partFull === "part") {
                var fromSec = ((fromPosMillisecond/1000)).toString()
                var toSec = ((toPosMillisecond/1000)).toString()
                var overlayDuration = (toPosMillisecond/1000 - fromPosMillisecond/1000).toString()
            }
            else { // "full" clip
                fromSec = "0"
                toSec = ((idMediaPlayer.duration)/1000).toString()
                overlayDuration = ((idMediaPlayer.duration)/1000).toString()
            }
            // replace ColorKey and Path when needed
            if (colorKey === "manual") {  // colorKey = "black:0.3:0.2" // colorToAlpha:similarity(0=exact/1=everything):blendEdges(higher=semi transparent pixels are closer to keycolor)
                colorKey = colorToAlpha + ":" + (idToolsRowImageOverlayAlphaSlider_Similarity.value).toString() + ":" + (idToolsRowImageOverlayAlphaSlider_Blend.value).toString()
                pathOverlayVideo = overlayFilePath.toString().replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"")
            }
            // stretch if needed
            if ( idComboBoxImageOverlayAlphaStretch.currentIndex === 0 ) { var applyStretch = "stretch" }
            else { applyStretch = "noStretch" }
            call("videox.overlayAlphaClipFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, pathOverlayVideo, origVideoWidth, origVideoHeight, colorKey, overlayOpacity, fromSec, toSec, overlayDuration, applyStretch, cropX, cropY, cropWidth, cropHeight, scaleDisplayFactorCrop, previewAlphaType ])
        }


        //collage manipulations
        function splitscreenFunction() {
            preparePathAndUndo()
            var secondClipPath = overlayFilePath.toString().replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"")
            if (idComboBoxCollageSplitscreen.currentIndex === 0) { var stackDirection = "above" }
            else if (idComboBoxCollageSplitscreen.currentIndex === 1) { stackDirection = "below" }
            else if (idComboBoxCollageSplitscreen.currentIndex === 2) { stackDirection = "left" }
            else if (idComboBoxCollageSplitscreen.currentIndex === 3) { stackDirection = "right" }
            if (idComboBoxCollageSplitscreenAudio.currentIndex === 0) { var useAudioFrom = "first" }
            else if (idComboBoxCollageSplitscreenAudio.currentIndex === 1) { useAudioFrom = "second" }
            else if (idComboBoxCollageSplitscreenAudio.currentIndex === 2) { useAudioFrom = "none" }
            else if (idComboBoxCollageSplitscreenAudio.currentIndex === 3) { useAudioFrom = "both" }
            var sizeDevider = 2
            call("videox.splitscreenFunction", [ ffmpeg_staticPath, inputPathPy, outputPathPy, sourceVideoWidth, sourceVideoHeight, sizeDevider, secondClipPath, stackDirection, useAudioFrom ])
        }
        function createSlideshowFunction() {
            idMediaPlayer.stop()
            finishedLoading = false
            var newFileName = "slideshow_" + new Date().toLocaleString(Qt.locale("de_DE"), "yyyy-MM-dd_HH-mm-ss") + "." + tempMediaType
            outputPathPy = homeDirectory + "/Videos/" + newFileName
            allSelectedPathsSlideshow = ""
            allSelectedDurationsSlideshow = ""
            allSelectedTransitionsSlideshow = ""
            allSelectedTransitionDurationsSlideshow = ""
            for(var i = 0; i < slideshowModel.count; ++i) {
                var addPath = (slideshowModel.get(i).path).toString()
                var addDuration = (slideshowModel.get(i).duration).toString()
                var addTransition = (slideshowModel.get(i).transition).toString()
                var addTransitionDuration = (slideshowModel.get(i).transitionDuration).toString()
                allSelectedPathsSlideshow = allSelectedPathsSlideshow + addPath + ";;"
                allSelectedDurationsSlideshow = allSelectedDurationsSlideshow + addDuration + ";;"
                allSelectedTransitionsSlideshow = allSelectedTransitionsSlideshow + addTransition + ";;"
                allSelectedTransitionDurationsSlideshow = allSelectedTransitionDurationsSlideshow + addTransitionDuration + ";;"
            }
            var targetWidth = (idToolsCollageTargetWidth.text).toString()
            var targetHeight = (idToolsCollageTargetHeight.text).toString()

            if (idComboBoxCollageSlideshowEffect.currentIndex === 0 ) { var panZoom = "still_images" }
            else if (idComboBoxCollageSlideshowEffect.currentIndex === 1 ) { panZoom = "pan_and_zoom" }

            call("videox.createSlideshowFunction", [ ffmpeg_staticPath, outputPathPy, allSelectedPathsSlideshow, allSelectedDurationsSlideshow, allSelectedTransitionsSlideshow, allSelectedTransitionDurationsSlideshow, targetWidth, targetHeight, newFileName, panZoom ])
        }
        function createStorylineFunction() {
            idMediaPlayer.stop()
            finishedLoading = false
            var newFileName = "story_" + new Date().toLocaleString(Qt.locale("de_DE"), "yyyy-MM-dd_HH-mm-ss") + "." + tempMediaType
            outputPathPy = homeDirectory + "/Videos/"  + newFileName
            allSelectedPathsStoryline = ""
            allSelectedTransitionsStoryline = ""
            allSelectedTransitionDurationsStoryline = ""
            for(var i = 0; i < storylineModel.count; ++i) {
                var addPath = (storylineModel.get(i).path).toString()
                var addTransition = (storylineModel.get(i).transition).toString()
                var addTransitionDuration = (storylineModel.get(i).transitionDuration).toString()
                allSelectedPathsStoryline = allSelectedPathsStoryline + addPath + ";;"
                allSelectedTransitionsStoryline = allSelectedTransitionsStoryline + addTransition + ";;"
                allSelectedTransitionDurationsStoryline = allSelectedTransitionDurationsStoryline + addTransitionDuration + ";;"
            }
            var targetWidth = (idToolsCollageTargetWidth.text).toString()
            var targetHeight = (idToolsCollageTargetHeight.text).toString()
            call("videox.createStorylineFunction", [ ffmpeg_staticPath, outputPathPy, allSelectedPathsStoryline, allSelectedTransitionsStoryline, allSelectedTransitionDurationsStoryline, targetWidth, targetHeight, newFileName ])
        }
        function overlaySubtitleFunction() {
            preparePathAndUndo()
            showHintSavingSubtitles = true
            if ( idComboBoxCollageSubtitleMethod.currentIndex === 0 ) { var addMethod = "burn" }
            else if ( idComboBoxCollageSubtitleMethod.currentIndex === 1 ) { addMethod = "selectable" }
            var textFileText = ""
            if (idComboBoxCollageSubtitleAdd.currentIndex === 0) { // get from file
                var createTextfile = "false"
                var subtitlePath = "/" + addSubtitlePath.toString().replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"")
            }
            else if (idComboBoxCollageSubtitleAdd.currentIndex === 1) { // get from manual input
                createTextfile = "true"
                subtitlePath = subtitleTempPath
                for(var i = 0; i < subtitleModel.count; ++i) {
                    var addSceneNr = (i+1).toString()
                    var addDuration = (subtitleModel.get(i).timestamp).toString()
                    var addText = (subtitleModel.get(i).text).toString()
                    textFileText = textFileText + addSceneNr + "\n" + addDuration + "\n" + addText + "\n"
                }
                addSubtitleContainer = "srt"
            }
            call("videox.overlaySubtitleFunction", [ ffmpeg_staticPath, inputPathPy, tempMediaFolderPath, outputPathPy, subtitlePath, addSubtitleContainer, addMethod, createTextfile, textFileText ])
        }
        function parseSubtitleFile( pathToFile ) {
            var subtitlePath = "/" + pathToFile.toString().replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"")
            call("videox.parseSubtitleFile", [ ffmpeg_staticPath, subtitlePath ])
        }
        function extractImagesFunction() {
            idMediaPlayer.stop()
            finishedLoading = false
            var thumbnailSec = new Date(idMediaPlayer.position).toISOString().substr(11,12)
            var thumbnailSecFileName = thumbnailSec//.replace(":", "-").replace(":", "-").replace(".", "-")
            var imageInterval = (idToolsRowCollageImageExtractIntervall.value).toString()
            if ( idComboBoxCollageImageExtract.currentIndex === 0 ) { var modeExtractImg = "thumbnails" }
            else if ( idComboBoxCollageImageExtract.currentIndex === 1 ) { modeExtractImg = "iFrames" }
            else if ( idComboBoxCollageImageExtract.currentIndex === 2 ) { modeExtractImg = "singleImage" }
            call("videox.extractImagesFunction", [ ffmpeg_staticPath, inputPathPy, modeExtractImg, thumbnailSec, thumbnailSecFileName, imageInterval, origMediaFolderPath ])
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





    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        id: idSilicaFlickable
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            enabled: recordingAudioState === false // Patch: while recording do not allow slide down
            MenuItem {
                text: qsTr("About")
                onClicked: {
                    idMediaPlayer.stop()
                    pageStack.push(Qt.resolvedUrl("InfoPage.qml"), {} )
                }
            }
            MenuItem {
                text: qsTr("Files")
                onClicked: {
                    idMediaPlayer.stop()
                    pageStack.push(filePickerPage)
                }
            }
            MenuItem {
                text: qsTr("Videos")
                onClicked: {
                    idMediaPlayer.stop()
                    pageStack.push(videoPickerPage)
                }
            }
            MenuItem {
                text: qsTr("Save")
                enabled: ( noFile === false && finishedLoading === true && idMediaPlayer.height > idTimeInfoRow.height )
                onClicked: {
                    idMediaPlayer.stop()
                    pageStack.push(Qt.resolvedUrl("SavePage.qml"), {
                        homeDirectory : homeDirectory,
                        origMediaFilePath : origMediaFilePath,
                        origMediaFileName : origMediaFileName,
                        origMediaFolderPath : origMediaFolderPath,
                        origMediaName : origMediaName,
                        origMediaType : origMediaType,
                        tempMediaFolderPath : tempMediaFolderPath,
                        inputPathPy : idMediaPlayer.source.toString(),
                        ffmpeg_staticPath : ffmpeg_staticPath,
                        origCodecVideo : origCodecVideo,
                        origCodecAudio : origCodecAudio,
                        origFrameRate : origFrameRate,
                        showHintSavingSubtitles : showHintSavingSubtitles
                    } )
                }
            }
        }

        Column {
            id: column
            width: page.width

            SectionHeader {
                id: idSectionHeader
                height: idSectionHeaderColumn.height
                Column {
                    id: idSectionHeaderColumn
                    width: parent.width / 5 * 4
                    height: idLabelProgramName.height + idLabelFilePath.height
                    anchors.top: parent.top
                    anchors.topMargin: Theme.paddingMedium
                    anchors.right: parent.right
                    anchors.rightMargin: -Theme.paddingMedium
                    Label {
                        id: idLabelProgramName
                        width: parent.width
                        anchors.right: parent.right
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.primaryColor
                        text: qsTr("Videoworks")
                        /*
                        MouseArea {
                            anchors.fill: parent
                            onEntered: idVibration.start()
                        }
                        */
                    }
                    Label {
                        id: idLabelFilePath
                        width: parent.width
                        anchors.right: parent.right
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeTiny
                        color: Theme.primaryColor
                        truncationMode: TruncationMode.Elide
                        text: origMediaFilePath
                    }
                }
                IconButton {
                    id: idIconUndoButton
                    visible: ( enabled === true ) ? true : false
                    enabled: ( undoNr >= 1 && finishedLoading === true ) ? true : false
                    width: (parent.width) / 5 * 1
                    height: idLabelProgramName.height + idLabelFilePath.height
                    anchors.top: parent.top
                    anchors.topMargin: Theme.paddingMedium + Theme.paddingSmall/2
                    anchors.left: parent.left
                    anchors.leftMargin: -Theme.paddingMedium * 3
                    icon.source: "../symbols/icon-l-undo.svg"
                    icon.width: Theme.iconSizeMedium
                    icon.height: Theme.iconSizeMedium
                    scale: 1.5
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: Theme.fontSizeTiny
                        text: undoNr
                        scale: 1/1.5
                    }
                    onClicked: {
                        undoBackwards()
                    }
                }
                BusyIndicator {
                    anchors.horizontalCenter: idIconUndoButton.horizontalCenter
                    anchors.horizontalCenterOffset: -Theme.paddingSmall/3.5
                    anchors.verticalCenter: idIconUndoButton.verticalCenter
                    anchors.verticalCenterOffset: Theme.paddingSmall/3.5
                    running: (finishedLoading === true) ? false : true
                    size: BusyIndicatorSize.Medium
                }
            }
            Item {
                width: parent.width
                height: 1.5 * Theme.paddingLarge
            }

            Video {
                id: idMediaPlayer
                visible: ( noFile === false )
                width: page.width
                height: ( origVideoRotation !== 90 && origVideoRotation !== -90 ) ? (width / origVideoRatio) : (width * origVideoRatio)
                onPositionChanged: {
                    idProgressSlider.value = idMediaPlayer.position
                }
                onSourceChanged: {
                    delayShowCropMarkers = true
                }
                onStatusChanged: {
                    // make sure to mark everything when loading file has finished
                    if (status === MediaPlayer.Loaded) {
                        fromPosMillisecond = 0
                        toPosMillisecond = duration
                        finishedLoading = true
                        delayShowCropMarkers = true
                        idTimerDelaySetCropmarkers.start()
                    }
                }
                onHeightChanged: {
                    // Patch: when crop is active and undo some cropping
                    setCropmarkersRatio()
                }
                onStopped: {
                    thumbnailVisible = true
                }

                Image {
                    id: idThumbnailOverlay
                    visible: ( thumbnailVisible === true ) ? true : false
                    width: parent.width
                    height: parent.height
                    cache: false
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    //source: thumbnailPath
                }

                Rectangle {
                    id: idVideoBackgroundFillRectangle
                    z: -1
                    anchors.fill: parent
                    color: "black"
                }

                // crop zone and handles
                Item {
                    id: idItemCropzoneHandles
                    anchors.fill: parent
                    visible: (finishedLoading === true && delayShowCropMarkers === false)

                    // handles and remaining zone
                    Rectangle {
                        id: rectDrag1
                        visible: ( noFile === false && finishedLoading === true && cropAreaVisible === true )
                        x: parent.x
                        y: parent.y
                        width: handleWidth
                        height: width
                        color: Theme.errorColor
                        opacity: 0.75
                        MouseArea {
                            id: dragArea1
                            preventStealing: true
                            enabled: true
                            anchors.fill: parent
                            anchors.leftMargin: Theme.paddingLarge * 2
                            anchors.rightMargin: Theme.paddingLarge * 2
                            anchors.topMargin: Theme.paddingLarge * 2
                            anchors.bottomMargin: Theme.paddingLarge * 2
                            drag.target: parent
                            drag.minimumX: (stretchOversizeActive === true) ? (0-handleWidth/2) : (0)
                            drag.maximumX: (stretchOversizeActive === true) ? (idItemCropzoneHandles.width - handleWidth/2) : (idItemCropzoneHandles.width - handleWidth)
                            drag.minimumY: (stretchOversizeActive === true) ? (idItemCropzoneHandles.y - handleWidth/2) : (idItemCropzoneHandles.y)
                            drag.maximumY: (stretchOversizeActive === true) ? (idItemCropzoneHandles.height - handleWidth/2) : (idItemCropzoneHandles.height - handleWidth)
                            onEntered: {
                                oldPosX1 = rectDrag1.x
                                oldPosY1 = rectDrag1.y
                            }
                            onPositionChanged: {
                                if (croppingRatio != 0) {
                                    diffX1 = rectDrag1.x - oldPosX1
                                    diffY1 = (diffX1 / croppingRatio)
                                    rectDrag1.y = oldPosY1 + diffY1

                                    if (rectDrag1.y > (idItemCropzoneHandles.height - handleWidth)) {
                                        rectDrag1.y = idItemCropzoneHandles.height - handleWidth
                                        rectDrag1.x = stopX1
                                    }
                                    else if (rectDrag1.y < 0) {
                                        rectDrag1.y = 0
                                        rectDrag1.x = stopX1
                                    }
                                    else {
                                        stopX1 = rectDrag1.x
                                    }
                                }


                            }
                        }
                     }
                    Rectangle {
                        id: rectDrag2
                        visible: ( noFile === false && finishedLoading === true && cropAreaVisible === true)
                        x: parent.width - handleWidth
                        y: parent.height - handleWidth
                        width: handleWidth
                        height: width
                        color: Theme.errorColor
                        opacity: 0.75
                        MouseArea {
                            id: dragArea2
                            preventStealing: true
                            enabled: true
                            anchors.fill: parent
                            anchors.leftMargin: Theme.paddingLarge * 2
                            anchors.rightMargin: Theme.paddingLarge * 2
                            anchors.topMargin: Theme.paddingLarge * 2
                            anchors.bottomMargin: Theme.paddingLarge * 2
                            drag.target: parent
                            drag.minimumX: (stretchOversizeActive === true) ? (0-handleWidth/2) : (0)
                            drag.maximumX: (stretchOversizeActive === true) ? (idItemCropzoneHandles.width - handleWidth/2) : (idItemCropzoneHandles.width - handleWidth)
                            drag.minimumY: (stretchOversizeActive === true) ? (idItemCropzoneHandles.y - handleWidth/2) : (idItemCropzoneHandles.y)
                            drag.maximumY: (stretchOversizeActive === true) ? (idItemCropzoneHandles.height - handleWidth/2) : (idItemCropzoneHandles.height - handleWidth)
                            onEntered: {
                                oldPosX2 = rectDrag2.x
                                oldPosY2 = rectDrag2.y
                            }
                            onPositionChanged: {
                                if (croppingRatio != 0) {
                                    diffX2 = rectDrag2.x - oldPosX2
                                    diffY2 = (diffX2 / croppingRatio)
                                    rectDrag2.y = oldPosY2 + diffY2
                                    if (rectDrag2.y > (idItemCropzoneHandles.height - handleWidth)) {
                                        rectDrag2.y = idItemCropzoneHandles.height - handleWidth
                                        rectDrag2.x = stopX2
                                    }
                                    else if (rectDrag2.y < 0) {
                                        rectDrag2.y = 0
                                        rectDrag2.x = stopX2
                                    }
                                    else {
                                        stopX2 = rectDrag2.x
                                    }
                                }
                            }
                        }
                    }
                    Rectangle {
                        id: frameRectangleCroppingzone
                        z: -1
                        visible: ( noFile === false && finishedLoading === true && cropAreaVisible === true)
                        color: "transparent"
                        border.color: (idPreviewOverlayImage.visible || idPreviewOverlayRectangle.visible ) ? "transparent" : Theme.rgba(Theme.errorColor, 0.75)
                        border.width: Theme.paddingSmall / 5
                        anchors.top: (rectDrag1.y < rectDrag2.y) ? rectDrag1.top : rectDrag2.top
                        anchors.left: (rectDrag1.x < rectDrag2.x) ? rectDrag1.left : rectDrag2.left
                        anchors.bottom: ((rectDrag1.y + rectDrag1.height) > (rectDrag2.y + rectDrag2.height)) ? rectDrag1.bottom : rectDrag2.bottom
                        anchors.right: ((rectDrag1.x + rectDrag1.width) > (rectDrag2.x + rectDrag2.width)) ? rectDrag1.right : rectDrag2.right

                        MouseArea {
                            id: dragAreaFullCroppingZone
                            anchors.fill: parent
                            drag.target:  parent
                            onEntered: {
                                oldmouseX = mouseX
                                oldmouseY = mouseY
                                oldWidth = parent.width
                                oldHeight = parent.height
                                oldFullAreaWidth = idItemCropzoneHandles.width
                                oldFullAreaHeight = idItemCropzoneHandles.height
                                if (rectDrag1.x < rectDrag2.x) { oldWhichSquareLEFT = "left1" }
                                    else { oldWhichSquareLEFT = "left2" }
                                if (rectDrag1.y < rectDrag2.y) { oldWhichSquareUP = "up1" }
                                    else { oldWhichSquareUP = "up2" }
                            }
                            onMouseXChanged: {
                                rectDrag1.x = rectDrag1.x + (mouseX - oldmouseX)
                                rectDrag2.x = rectDrag2.x + (mouseX - oldmouseX)
                                if (oldWhichSquareLEFT === "left1") {
                                    if (rectDrag1.x < 0) {
                                        rectDrag1.x = 0
                                        rectDrag2.x = oldWidth - rectDrag1.width
                                    }
                                    if ((rectDrag2.x+rectDrag2.width) > oldFullAreaWidth) {
                                        rectDrag2.x = oldFullAreaWidth - rectDrag2.width
                                        rectDrag1.x = oldFullAreaWidth - oldWidth
                                    }
                                }
                                if (oldWhichSquareLEFT === "left2") {
                                    if (rectDrag2.x < 0) {
                                        rectDrag2.x = 0
                                        rectDrag1.x = oldWidth - rectDrag2.width
                                    }
                                    if ((rectDrag1.x+rectDrag1.width) > oldFullAreaWidth) {
                                        rectDrag1.x = oldFullAreaWidth - rectDrag1.width
                                        rectDrag2.x = oldFullAreaWidth - oldWidth
                                    }
                                }
                            }
                            onMouseYChanged: {
                                rectDrag1.y = rectDrag1.y + (mouseY - oldmouseY)
                                rectDrag2.y = rectDrag2.y + (mouseY - oldmouseY)
                                if (oldWhichSquareUP === "up1") {
                                    if (rectDrag1.y < 0) {
                                        rectDrag1.y = 0
                                        rectDrag2.y = oldHeight - rectDrag1.height
                                    }
                                    if ((rectDrag2.y+rectDrag2.height) > oldFullAreaHeight) {
                                        rectDrag2.y = oldFullAreaHeight - rectDrag2.height
                                        rectDrag1.y = oldFullAreaHeight - oldHeight
                                    }
                                }
                                if (oldWhichSquareUP === "up2") {
                                    if (rectDrag2.y < 0) {
                                        rectDrag2.y = 0
                                        rectDrag1.y = oldHeight - rectDrag2.height
                                    }
                                    if ((rectDrag1.y+rectDrag1.height) > oldFullAreaHeight) {
                                    rectDrag1.y = oldFullAreaHeight - rectDrag1.height
                                    rectDrag2.y = oldFullAreaHeight - oldHeight
                                    }
                                }
                            }
                        }
                        Image {
                            id: idPreviewOverlayImage
                            visible: ( idButtonImage.down && idButtonImageOverlays.down && overlayFilePath !== "" && ( idComboBoxImageOverlayType.currentIndex === 0 || idComboBoxImageOverlayType.currentIndex === 1 || idComboBoxImageOverlayType.currentIndex === 4 ) )
                            cache: false
                            autoTransform: true
                            opacity: (idComboBoxImageOverlayType.currentIndex === 4) ? 0.6 : idToolsRowImageOverlayOpacitySlider.value
                            source: ""
                            anchors.fill: parent
                        }
                        Rectangle {
                            id: idPreviewOverlayRectangle
                            visible: ( idButtonImage.down && idButtonImageOverlays.down && ( idComboBoxImageOverlayType.currentIndex === 2 || idComboBoxImageOverlayType.currentIndex === 3 ) )
                            anchors.fill: parent
                            opacity: ( idComboBoxImageOverlayType.currentIndex === 2 ) ? idToolsRowImageOverlayOpacitySlider.value : 1
                            color: ( idComboBoxImageOverlayType.currentIndex === 2 ) ? drawRectangleColor : "transparent"
                            border.color: drawRectangleColor
                            border.width: ( idComboBoxImageOverlayType.currentIndex === 2) ? 0 : (baseFrameThickness * idToolsRowImageOverlayFrameSizeSlider.value)
                        }

                    }
                    Rectangle {
                        id: rectDragText
                        visible: ( noFile === false && finishedLoading === true && textAreaVisible === true)
                        x: parent.width/2 - width/2
                        y: parent.height/2 - height/2
                        width: handleWidth
                        height: width
                        color: "transparent"

                        MouseArea {
                            id: dragAreaText
                            preventStealing: true
                            enabled: true
                            anchors.fill: parent
                            anchors.leftMargin: Theme.paddingLarge * 4
                            anchors.rightMargin: Theme.paddingLarge * 4
                            anchors.topMargin: Theme.paddingLarge * 4
                            anchors.bottomMargin: Theme.paddingLarge * 4
                            drag.target: parent
                            drag.minimumX: (stretchOversizeActive === true) ? (0-handleWidth/2) : (0)
                            drag.maximumX: (stretchOversizeActive === true) ? (idItemCropzoneHandles.width - handleWidth/2) : (idItemCropzoneHandles.width - handleWidth)
                            drag.minimumY: (stretchOversizeActive === true) ? (idItemCropzoneHandles.y - handleWidth/2) : (idItemCropzoneHandles.y)
                            drag.maximumY: (stretchOversizeActive === true) ? (idItemCropzoneHandles.height - handleWidth/2) : (idItemCropzoneHandles.height - handleWidth)
                        }
                        Label {
                            id: idPaintTextPreview
                            visible: true
                            anchors.centerIn: parent
                            color: addTextColor
                            font.pixelSize: fontSizePreview
                            text: idToolsImageTextInput.text
                            Rectangle {
                                id: idPaintTextPreviewBox
                                z: -2
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * addTextboxPlusFactor
                                height: ( (((parent.text).toString()).indexOf("q") !== -1)
                                         || (((parent.text).toString()).indexOf("p") !== -1)
                                         || (((parent.text).toString()).indexOf("g") !== -1)
                                         || (((parent.text).toString()).indexOf("j") !== -1)
                                         || (((parent.text).toString()).indexOf("y") !== -1)
                                         ) ? parent.height : (parent.height / 4 * 3)
                                color: addTextboxColor
                                opacity: idToolsRowImageTextboxOpacity.value
                            }
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            radius: parent.width / 2
                            border.color: Theme.errorColor
                            border.width: Theme.paddingSmall / 2.5
                        }
                    }

                    // these gray zones which will be cut away
                    Rectangle {
                        id: grayzoneUP
                        visible: ( noFile === false && finishedLoading === true && cropAreaVisible === true)
                        anchors.top: parent.top
                        anchors.left: parent.left
                        width: idItemCropzoneHandles.width
                        height: Math.min(rectDrag1.y, rectDrag2.y)
                        color: (idPreviewOverlayImage.visible || idPreviewOverlayRectangle.visible ) ? "transparent" : "black"
                        opacity: 0.75
                    }
                    Rectangle {
                        id: grayzoneLEFT
                        visible: ( noFile === false && finishedLoading === true && cropAreaVisible === true)
                        anchors.left: parent.left
                        y: Math.min(rectDrag1.y, rectDrag2.y)
                        width: Math.min(rectDrag1.x, rectDrag2.x)
                        height: Math.max(rectDrag1.y+rectDrag1.height, rectDrag2.y+rectDrag2.height) - Math.min(rectDrag1.y, rectDrag2.y)
                        color: (idPreviewOverlayImage.visible || idPreviewOverlayRectangle.visible) ? "transparent" : "black"
                        opacity: 0.75
                    }
                    Rectangle {
                        id: grayzoneDOWN
                        visible: ( noFile === false && finishedLoading === true && cropAreaVisible === true)
                        anchors.left: parent.left
                        y: Math.max((rectDrag1.y + rectDrag1.height), (rectDrag2.y + rectDrag2.height))
                        width: idItemCropzoneHandles.width
                        height: idItemCropzoneHandles.height - Math.max(rectDrag1.y + rectDrag1.height, rectDrag2.y + rectDrag2.height)
                        color: (idPreviewOverlayImage.visible || idPreviewOverlayRectangle.visible) ? "transparent" : "black"
                        opacity: 0.75
                    }
                    Rectangle {
                        id: grayzoneRIGHT
                        visible: ( noFile === false && finishedLoading === true && cropAreaVisible === true)
                        x: Math.max(rectDrag1.x + rectDrag1.width, rectDrag2.x + rectDrag2.width)
                        y: Math.min(rectDrag1.y, rectDrag2.y)
                        width: idItemCropzoneHandles.width - Math.max(rectDrag1.x + rectDrag1.width, rectDrag2.x + rectDrag2.width)
                        height: Math.max(rectDrag1.y+rectDrag1.height, rectDrag2.y+rectDrag2.height) - Math.min(rectDrag1.y, rectDrag2.y)
                        color: (idPreviewOverlayImage.visible || idPreviewOverlayRectangle.visible) ? "transparent" : "black"
                        opacity: 0.75
                    }
                }

                // labels
                Item {
                    id: idTimeInfoRow
                    visible: ( noFile === false && finishedLoading === true && cropAreaVisible === false && hideUpperTimeMarkers === false && delayShowCropMarkers === false )
                    anchors.top: parent.top
                    anchors.topMargin: Theme.paddingSmall
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: Theme.paddingSmall
                    anchors.rightMargin: Theme.paddingSmall

                    Label {
                        id: idAudioZeroTimeLabel
                        anchors.baseline: idCurrentPosition.baseline
                        anchors.left: parent.left
                        horizontalAlignment: Text.AlignLeft
                        font.pixelSize: Theme.fontSizeTiny
                        text: " 00:00:00 "
                        Rectangle {
                            z: -1
                            anchors.fill: parent
                            color: Theme.highlightDimmerColor
                            opacity: 0.75
                        }
                    }
                    Label {
                        id: idCurrentPosition
                        anchors.horizontalCenter: parent.horizontalCenter
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Theme.fontSizeTiny
                        text: " " + new Date(idMediaPlayer.position).toISOString().substr(11,8) + " "
                        Rectangle {
                            z: -1
                            anchors.fill: parent
                            color: Theme.highlightDimmerColor
                            opacity: 0.75
                        }
                    }
                    Label {
                        id: idAudioDurationLabel
                        anchors.right: parent.right
                        anchors.baseline: idCurrentPosition.baseline
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeTiny
                        text: " " + new Date(idMediaPlayer.duration).toISOString().substr(11,8) + " "
                        Rectangle {
                            z: -1
                            anchors.fill: parent
                            color: Theme.highlightDimmerColor
                            opacity: 0.75
                        }
                    }
                }
                Label {
                    id: idLeftMarkerLabel
                    text: " " + new Date(fromPosMillisecond).toISOString().substr(11,12) + " "
                    visible: (noFile === false && finishedLoading === true && hideLowerTimeMarkers === false && delayShowCropMarkers === false)
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeTiny
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.paddingSmall
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingSmall
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        color: Theme.highlightDimmerColor
                        opacity: 0.75
                    }
                }
                Label {
                    id: idChangeSliderToTimeLabel
                    visible: idProgressSlider.pressed
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.paddingSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: Theme.fontSizeTiny
                    text: " " + new Date(idProgressSlider.value).toISOString().substr(11,12) + " "
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        color: Theme.highlightDimmerColor
                        opacity: 0.75
                    }
                }
                Label {
                    id: idRightMarkerLabel
                    text: " " + new Date(toPosMillisecond).toISOString().substr(11,12) + " "
                    visible: (noFile === false && finishedLoading === true && hideLowerTimeMarkers === false && delayShowCropMarkers === false )
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeTiny
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.paddingSmall
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.paddingSmall
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        color: Theme.highlightDimmerColor
                        opacity: 0.75
                    }
                }
                Label {
                    id: idInfoPlusMinus
                    text: " " + plusMinusInfo + " "
                    visible: ( noFile === false && idTimerShowInfoPlusMinus.running === true )
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeTiny
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.paddingSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        color: Theme.highlightDimmerColor
                        opacity: 0.75
                    }
                }
                Label {
                    id: idWarningOutsideTrimShort
                    text: " " + qsTr("ERROR: remaining <") + " " + minTrimLength/1000 + "s "
                    visible: ( noFile === false && idTimerShowErrorLengthOutside.running === true )
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeTiny
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.paddingSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Theme.errorColor
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        color: Theme.highlightDimmerColor
                        opacity: 0.75
                    }
                }
                Rectangle {
                    visible: (finishedLoading === false)
                    anchors.right: parent.right
                    height: parent.height
                    width: parent.width / 100 * (100 - processedPercent)
                    color: Theme.rgba(Theme.highlightDimmerColor, 0.5)
                }
            }
            Item {
                width: parent.width
                height: Theme.paddingLarge
            }

            Slider {
                id: idProgressSlider
                enabled: ( noFile === false && finishedLoading === true )
                width: parent.width
                leftMargin: Theme.paddingSmall + Theme.paddingMedium
                rightMargin: Theme.paddingSmall + Theme.paddingMedium
                minimumValue: 0
                maximumValue: (idMediaPlayer.duration <= minimumValue) ? 1 : idMediaPlayer.duration
                value: idMediaPlayer.position
                color: Theme.primaryColor

                onReleased: {
                    idMediaPlayer.seek(value)
                    if ( thumbnailVisible === true ) {
                        py.createPreviewImage()
                    }
                    thumbnailVisible = false
                }
                handleVisible: false

                Rectangle {
                    id: idSliderHandle1
                    x: idProgressSlider._highlightX
                    z: 5
                    width: Theme.itemSizeMedium
                    height: Theme.itemSizeMedium
                    anchors.verticalCenter: parent.verticalCenter
                    color: "transparent"
                    Rectangle {
                        id: idSliderHandle1Rect
                        anchors.centerIn: parent
                        width: Theme.paddingLarge
                        height: width
                        radius: width/2
                        color: idProgressSlider.highlighted ? idProgressSlider.highlightColor : idProgressSlider.color
                    }
                }
                Item {
                    id: idCutRectangleBackground
                    visible: ( noFile === false && finishedLoading === true && hideLowerTimeMarkers === false && delayShowCropMarkers === false )
                    z: -2
                    anchors.fill: parent
                    anchors.leftMargin: Theme.paddingLarge + addThemeSliderPaddingSides
                    anchors.rightMargin: Theme.paddingLarge + addThemeSliderPaddingSides

                    Rectangle {
                        id: idLabelFromTo
                        y: Theme.paddingMedium
                        height: parent.height - 2 * y
                        x: parent.width / idMediaPlayer.duration * fromPosMillisecond
                        width: parent.width / idMediaPlayer.duration * toPosMillisecond - x
                        color: Theme.secondaryHighlightColor
                        opacity: 0.5
                    }
                    Label {
                        text: " " + ((toPosMillisecond-fromPosMillisecond)/1000).toFixed(1) + "s "
                        visible: ( noFile === false && finishedLoading === true && idLabelFromTo.visible )
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Theme.fontSizeTiny
                        anchors.bottom: idLabelFromTo.top
                        anchors.horizontalCenter: idLabelFromTo.horizontalCenter
                    }
                }

                Rectangle {
                    id: idLabelFromToLeft
                    visible: ( (finishedLoading === true && noFile === false) && ( (idButtonImage.down && idButtonImageEffects.down && idComboBoxImageEffects.currentIndex === 0 && idComboBoxImageEffectsBasics.currentIndex === 0 && idComboBoxImageEffectsFade.currentIndex === 0) || (idButtonAudio.down && idButtonAudioFade.down &&  idComboBoxAudioFade.currentIndex === 0 ) ) )
                    z: -1
                    y: Theme.paddingMedium
                    height: parent.height - 2 * y
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingLarge + addThemeSliderPaddingSides
                    anchors.right: idSliderHandle1.horizontalCenter
                    color: Theme.secondaryHighlightColor
                    opacity: 0.5
                }
                Label {
                    text: " " + (idMediaPlayer.position/1000).toFixed(1) + "s "
                    visible: ( noFile === false && finishedLoading === true && idLabelFromToLeft.visible )
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeTiny
                    anchors.bottom: idLabelFromToLeft.top
                    anchors.horizontalCenter: idLabelFromToLeft.horizontalCenter
                    //color: Theme.errorColor
                }

                Rectangle {
                    id: idLabelFromToRight
                    visible: ( (finishedLoading === true && noFile === false) && ( (idButtonImage.down && idButtonImageEffects.down && idComboBoxImageEffects.currentIndex === 0 && idComboBoxImageEffectsBasics.currentIndex === 0 && idComboBoxImageEffectsFade.currentIndex === 1) || (idButtonAudio.down && idButtonAudioFade.down &&  idComboBoxAudioFade.currentIndex === 1 ) ) )
                    z: -1
                    y: Theme.paddingMedium
                    height: parent.height - 2 * y
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.paddingLarge + addThemeSliderPaddingSides
                    anchors.left: idSliderHandle1.horizontalCenter
                    color: Theme.secondaryHighlightColor
                    opacity: 0.5
                }
                Label {
                    text: " " + ((idMediaPlayer.duration - idMediaPlayer.position)/1000).toFixed(1) + "s "
                    visible: ( noFile === false && finishedLoading === true && idLabelFromToRight.visible )
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeTiny
                    anchors.bottom: idLabelFromToRight.top
                    anchors.horizontalCenter: idLabelFromToRight.horizontalCenter
                    //color: Theme.errorColor
                }

                Rectangle {
                    id: idRectangleMixer
                    visible: ( finishedLoading === true && noFile === false && idButtonAudio.down && idButtonAudioMixer.down && idComboBoxAudioNewLength.currentIndex === 0 && addAudioLoaded === true )
                    z: -1
                    y: Theme.paddingMedium
                    height: parent.height - 2 * y
                    width: ( (idSliderHandle1.x + idSliderHandle1.width/2 + resultingFilePreviewWidth) < (page.width - (Theme.paddingLarge + addThemeSliderPaddingSides))) ? resultingFilePreviewWidth : (page.width - ( Theme.paddingLarge + addThemeSliderPaddingSides) - idSliderHandle1.x - idSliderHandle1.width/2 )
                    anchors.left: idSliderHandle1.horizontalCenter
                    color: Theme.secondaryHighlightColor
                    opacity: 0.5
                }
                Label {
                    //text: new Date(filePreviewDuration).toISOString().substr(11,8)
                    text: (filePreviewDuration/1000).toFixed(1) + "s "
                    visible: ( noFile === false && finishedLoading === true && idRectangleMixer.visible )
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeTiny
                    anchors.bottom: idRectangleMixer.top
                    anchors.horizontalCenter: idRectangleMixer.horizontalCenter
                    //color: Theme.errorColor
                }

                Rectangle {
                    id: idRectangleAudioRecording
                    visible: ( idButtonAudio.down && idButtonAudioRecord.down && recordingAudioState === true )
                    z: -1
                    y: Theme.paddingMedium
                    x: startRecordingHandlePosX
                    width: (idSliderHandle1.x + idSliderHandle1.width/2) - x
                    height: parent.height - 2 * y
                    color: Theme.secondaryHighlightColor
                    opacity: 0.5
                }
            }

            Row {
                id: idPlayPauseMarkerRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge * 2
                anchors.rightMargin: Theme.paddingLarge * 2
                height: Theme.itemSizeLarge

                IconButton {
                    enabled: (noFile === false && finishedLoading === true && hideLowerTimeMarkers === false )
                    height: parent.height
                    width: parent.width / 5
                    icon.source : "../symbols/icon-m-marker.svg"
                    icon.height: Theme.iconSizeMedium * 1.05
                    icon.width: Theme.iconSizeMedium * 1.05
                    onClicked: {
                        if (idMediaPlayer.position > toPosMillisecond) {
                            fromPosMillisecond = toPosMillisecond
                            toPosMillisecond = idMediaPlayer.position
                        }
                        else {
                            fromPosMillisecond = idMediaPlayer.position
                        }
                    }
                    onPressAndHold: {
                        idMediaPlayer.seek(fromPosMillisecond)
                    }
                }
                IconButton {
                    enabled: (noFile === false && finishedLoading === true && (idMediaPlayer.height > idTimeInfoRow.height) )
                    height: parent.height
                    width: parent.width / 5
                    icon.source : "image://theme/icon-m-media-rewind?"
                    icon.height: Theme.iconSizeMedium * 1.33
                    icon.width: Theme.iconSizeMedium * 1.33
                    onClicked: {
                        if ( (idMediaPlayer.position - 1000) >= 0 ) {
                            idMediaPlayer.seek(idMediaPlayer.position - 1000)
                            plusMinusInfo = "-1 sec"
                            idTimerShowInfoPlusMinus.start()
                            if ( thumbnailVisible === true ) {
                                py.createPreviewImage()
                            }
                            thumbnailVisible = false
                        }
                    }
                    onPressAndHold: {
                        if ( (idMediaPlayer.position - 10000) >= 0 ) {
                            idMediaPlayer.seek(idMediaPlayer.position - 10000)
                            plusMinusInfo = "-10 sec"
                            idTimerShowInfoPlusMinus.start()
                            if ( thumbnailVisible === true ) {
                                py.createPreviewImage()
                            }
                            thumbnailVisible = false
                        }
                    }
                }
                IconButton {
                    id: idButtonPlayPauseStop
                    enabled: (noFile === false && finishedLoading === true && (idMediaPlayer.height > idTimeInfoRow.height) )
                    height: parent.height
                    width: parent.width / 5
                    icon.source: ( idMediaPlayer.playbackState !== MediaPlayer.PlayingState) ? "image://theme/icon-m-play?" : "image://theme/icon-m-pause?"
                    icon.width: Theme.iconSizeMedium * 1.1
                    icon.height: Theme.iconSizeMedium * 1.1
                    onClicked: {
                        if (idMediaPlayer.playbackState === MediaPlayer.PlayingState ) {
                            idMediaPlayer.pause()
                        }
                        else {
                            idMediaPlayer.play()
                        }
                        thumbnailVisible = false
                    }
                    onPressAndHold: {
                        idMediaPlayer.seek(0)
                        idMediaPlayer.stop()
                        //thumbnailVisible = true
                    }
                    Rectangle {
                        //visible: (noFile === false && finishedLoading === true)
                        anchors.centerIn: parent
                        width: Theme.iconSizeMedium * 1.1 - border.width /2 + border.width * 1.9
                        height: width
                        radius: width/2
                        color: "transparent"
                        border.color: ( idMediaPlayer.playbackState !== MediaPlayer.PlayingState ) ? ( Theme.rgba(Theme.presenceColor(Theme.PresenceAvailable),0.7) ) : ( ( recordingAudioState === true ) ? ( Theme.errorColor ) : ( Theme.rgba(Theme.presenceColor(Theme.PresenceAway),0.7) ) )
                        border.width: Theme.paddingMedium * 0.6
                    }
                }
                IconButton {
                    enabled: (noFile === false && finishedLoading === true && (idMediaPlayer.height > idTimeInfoRow.height) )
                    height: parent.height
                    width: parent.width / 5
                    icon.source : "image://theme/icon-m-media-forward?"
                    icon.height: Theme.iconSizeMedium * 1.33
                    icon.width: Theme.iconSizeMedium * 1.33
                    //icon.color: Theme.highlightColor
                    onClicked: {
                        if ( (idMediaPlayer.position + 1000) <= idMediaPlayer.duration ) {
                            idMediaPlayer.seek(idMediaPlayer.position + 1000)
                            plusMinusInfo = "+1 sec"
                            idTimerShowInfoPlusMinus.start()
                            if ( thumbnailVisible === true ) {
                                py.createPreviewImage()
                            }
                            thumbnailVisible = false
                        }
                    }
                    onPressAndHold: {
                        if ( (idMediaPlayer.position + 10000) <= idMediaPlayer.duration ) {
                            idMediaPlayer.seek(idMediaPlayer.position + 10000)
                            plusMinusInfo = "+10 sec"
                            idTimerShowInfoPlusMinus.start()
                            if ( thumbnailVisible === true ) {
                                py.createPreviewImage()
                            }
                            thumbnailVisible = false
                        }
                    }
                }
                IconButton {
                    enabled: (noFile === false && finishedLoading === true && hideLowerTimeMarkers === false )
                    height: parent.height
                    width: parent.width / 5
                    icon.source : "../symbols/icon-m-marker.svg"
                    icon.height: Theme.iconSizeMedium * 1.05
                    icon.width: Theme.iconSizeMedium * 1.05
                    onClicked: {
                        if (idMediaPlayer.position < fromPosMillisecond) {
                            toPosMillisecond = fromPosMillisecond
                            fromPosMillisecond = idMediaPlayer.position
                        }
                        else {
                            toPosMillisecond = idMediaPlayer.position
                        }
                    }
                    onPressAndHold: {
                        idMediaPlayer.seek(toPosMillisecond)
                        if ( idMediaPlayer.position === idMediaPlayer.duration ) {
                            idMediaPlayer.pause()
                        }
                    }
                }
            }
            Item {
                width: parent.width
                height: Theme.paddingLarge * 3
            }





            // main toolbar
            Row {
                id: idToolsCategoriesRow
                x: Theme.paddingSmall
                width: parent.width - 2*x

                Item {
                    id: borderRectTools
                    width: (parent.width / 6 - parent.width / 7) / 2 // adjust centered position of 6 elements with next line that has 6 elements
                    height: parent.height
                }
                IconButton {
                    id: idButtonCut
                    icon.opacity: 1
                    down: true
                    height: Theme.itemSizeSmall
                    width: parent.width / 7
                    icon.source : "../symbols/icon-m-cut.svg"
                    icon.width: Theme.iconSizeMedium
                    icon.height: Theme.iconSizeMedium
                    onClicked: {
                        idButtonCut.down = true
                        idButtonImage.down = false
                        idButtonAudio.down = false
                        idButtonFile.down = false
                        idButtonCollage.down = false
                    }
                }
                IconButton {
                    id: idButtonImage
                    icon.opacity: 1
                    down: false
                    height: Theme.itemSizeSmall
                    width: parent.width / 7
                    icon.source : "image://theme/icon-m-ambience?"
                    icon.width: Theme.iconSizeMedium
                    icon.height: Theme.iconSizeMedium
                    onClicked: {
                        idButtonCut.down = false
                        idButtonImage.down = true
                        idButtonAudio.down = false
                        idButtonFile.down = false
                        idButtonCollage.down = false
                    }
                }
                IconButton {
                    id: idButtonAudio
                    icon.opacity: 1
                    down: false
                    height: Theme.itemSizeSmall
                    width: parent.width / 7
                    icon.height: Theme.itemSizeSmall * 0.8
                    icon.source : "image://theme/icon-m-sounds?" // speaker
                    onClicked: {
                        idButtonCut.down = false
                        idButtonImage.down = false
                        idButtonAudio.down = true
                        idButtonFile.down = false
                        idButtonCollage.down = false
                    }
                }
                IconButton {
                    id: idButtonCollage
                    icon.opacity: 1
                    down: false
                    height: Theme.itemSizeSmall
                    width: parent.width / 7
                    icon.source: "../symbols/icon-m-timeline.svg"
                    icon.width: Theme.itemSizeSmall
                    icon.height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonCut.down = false
                        idButtonImage.down = false
                        idButtonAudio.down = false
                        idButtonFile.down = false
                        idButtonCollage.down = true
                    }
                }
                IconButton {
                    id: idButtonFile
                    icon.opacity: 1
                    down: false
                    height: Theme.itemSizeSmall
                    width: parent.width / 7
                    icon.source: "image://theme/icon-m-file-document-light?"
                    onClicked: {
                        idButtonCut.down = false
                        idButtonImage.down = false
                        idButtonAudio.down = false
                        idButtonFile.down = true
                        idButtonCollage.down = false
                    }
                }
                Item {
                    width: parent.width / 7 - 2 * borderRectTools.width
                    height: parent.height
                }
                Item {
                    id: idButtonRecordingItem
                    visible: ( idButtonAudio.down && idButtonAudioRecord.down )
                    height: Theme.itemSizeSmall
                    width: parent.width / 7

                    IconButton {
                        id: idButtonRecord
                        enabled: ( noFile === false && finishedLoading === true && idButtonAudio.down && idButtonAudioRecord.down )
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -Theme.paddingSmall / 2.5
                        anchors.horizontalCenterOffset: Theme.paddingSmall / 5
                        width: parent.width
                        height: parent.height
                        icon.source: "image://theme/icon-m-mic?"
                        icon.width: Theme.iconSizeMedium * 0.8
                        icon.height: icon.width

                        Rectangle {
                            z: -1
                            anchors.centerIn: parent
                            width: parent.icon.width * 1/0.8
                            height: width
                            radius: width/2
                            color: (parent.down) ? Theme.rgba(Theme.errorColor, 0.2) : Theme.rgba(Theme.primaryColor, 0.2)
                        }
                        onEntered: {
                            startRecordingHandlePosX = idSliderHandle1.x + idSliderHandle1.width/2
                            idMediaPlayer.pause() // in case it did not pause yet

                            // this makes no sense since we have to mute to record
                            //recordingBeepStart.play()
                            //idTimerDelayRecording.start() // records, commands are issued when beep sound has finished

                            recordingOverlayStart = (idMediaPlayer.position/1000).toString()
                            recordingAudioState = true
                            audioRecorder_Sample.record()
                            idMediaPlayer.play()
                            thumbnailVisible = false
                        }
                        onReleased: {
                            audioRecorder_Sample.stop()
                            recordingAudioState = false
                            idMediaPlayer.pause()
                            //thumbnailVisible = false
                            // this makes no sense since we have to mute to record
                            //recordingBeepStop.play()
                            py.recordAudioFunction()
                        }
                    }
                }
                IconButton {
                    id: idButtonConfirm
                    enabled: ( (noFile === false && finishedLoading === true && idButtonRecord.down === false && (idMediaPlayer.height > idTimeInfoRow.height)) || ( idButtonCollage.down && idButtonCollageSlideshow.down && slideshowModel.count !== 0 ) || ( idButtonCollage.down && idButtonCollageStoryline.down && storylineModel.count !== 0 ) )
                    height: Theme.itemSizeSmall
                    width: parent.width / 7
                    icon.source : ("image://theme/icon-m-accept?")
                    icon.width: Theme.iconSizeMedium * 0.9// * 1.25
                    icon.height: icon.width
                    icon.color: (enabled) ? Theme.primaryColor : "transparent"

                    Rectangle {
                        z: -1
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -Theme.paddingSmall / 2.5
                        anchors.horizontalCenterOffset: Theme.paddingSmall / 5
                        width: parent.icon.width * 1/0.9
                        height: width
                        radius: width/2
                        color: (parent.enabled) ? Theme.rgba(Theme.primaryColor, 0.2) : "transparent"
                    }
                    onClicked: {
                        idSilicaFlickable.scrollToTop()
                        if ( idButtonCut.down ) {
                            if ( idButtonCutTrim.down ) { py.trimFunction() }
                            if ( idButtonCutAdd.down ) { py.addTimeFunction() }
                            if ( idButtonCutCrop.down ) { py.cropAreaFunction() }
                            if ( idButtonCutPad.down ) { py.padAreaFunction() }
                            if ( idButtonCutResize.down ) { py.resizeFunction() }
                            if ( idButtonCutSpeed.down ) { py.speedFunction() }
                        }
                        if ( idButtonImage.down ) {
                            if ( idButtonImageFilters.down ) {
                                if ( idComboBoxImageFilters.currentIndex === 0 && cubeFileLoaded === true ) { py.imageLUT3dFunction( "extern" ) }
                                if ( idComboBoxImageFilters.currentIndex === 1 ) { py.imageLUT3dFunction ( "cineAnime.png" ) }
                                if ( idComboBoxImageFilters.currentIndex === 2 ) { py.imageGrayscaleFunction() }
                                if ( idComboBoxImageFilters.currentIndex === 3 ) { py.imageLUT3dFunction ( "cineBleak.png" ) }
                                if ( idComboBoxImageFilters.currentIndex === 4 ) { py.imageLUT3dFunction ( "cineBleach.png" ) }
                                if ( idComboBoxImageFilters.currentIndex === 5 ) { py.imageLUT3dFunction( "cineCold.cube" ) }
                                if ( idComboBoxImageFilters.currentIndex === 6 ) { py.imageLUT3dFunction( "cineDrama.cube" ) }
                                if ( idComboBoxImageFilters.currentIndex === 7 ) { py.imageLUT3dFunction ( "cineFall.png" ) }
                                if ( idComboBoxImageFilters.currentIndex === 8 ) { py.imageLUT3dFunction( "cineMoonlight.png" ) }
                                if ( idComboBoxImageFilters.currentIndex === 9 ) { py.imageCurveFunction("negative") }
                                if ( idComboBoxImageFilters.currentIndex === 10 ) { py.imageLUT3dFunction ( "cineOld.png" ) }
                                if ( idComboBoxImageFilters.currentIndex === 11 ) { py.imageLUT3dFunction( "cineOrangeTeal.cube" ) }
                                if ( idComboBoxImageFilters.currentIndex === 12 ) { py.imageLUT3dFunction ( "cineSpring.png" ) }
                                if ( idComboBoxImageFilters.currentIndex === 13 ) { py.imageLUT3dFunction ( "cineSummer.png" ) }
                                if ( idComboBoxImageFilters.currentIndex === 14 ) { py.imageLUT3dFunction ( "cineTealMagentaGold.png" ) }
                                if ( idComboBoxImageFilters.currentIndex === 15 ) { py.imageLUT3dFunction( "cineSunset.png" ) }
                                if ( idComboBoxImageFilters.currentIndex === 16 ) { py.imageLUT3dFunction( "cineVibrant.cube" ) }
                                if ( idComboBoxImageFilters.currentIndex === 17 ) { py.imageCurveFunction("vintage") }
                                if ( idComboBoxImageFilters.currentIndex === 18 ) { py.imageLUT3dFunction ( "cineWarm.cube" ) }
                                if ( idComboBoxImageFilters.currentIndex === 19 ) { py.imageLUT3dFunction ( "cineWinter.png" ) }
                            }

                            if ( idButtonImageEffects.down ) {
                                if ( idComboBoxImageEffects.currentIndex === 0 ) { // basics
                                    if (idComboBoxImageEffectsBasics.currentIndex === 0 ) { py.imageFadeFunction() }
                                    else if (idComboBoxImageEffectsBasics.currentIndex === 1 ) { py.imageBlurFunction() }
                                    else if (idComboBoxImageEffectsBasics.currentIndex === 2 ) { py.imageGeneralEffectFunction("unsharp") }
                                    else if (idComboBoxImageEffectsBasics.currentIndex === 3 ) { py.imageGeneralEffectFunction( "erosion" ) }
                                    else if (idComboBoxImageEffectsBasics.currentIndex === 4 ) { py.imageNormalizeFunction() }
                                    else if (idComboBoxImageEffectsBasics.currentIndex === 5 ) { py.imageReverseFunction() }
                                }
                                else if ( idComboBoxImageEffects.currentIndex === 1 ) { // overlay
                                    previewAlphaType = "video"
                                    if (idComboBoxImageEffectsOverlays.currentIndex === 0) { py.overlayAlphaClipFunction( overlaysFolder + "flowersFalling.m4v", "part", "black:0.3:0.1" ) }
                                    else if (idComboBoxImageEffectsOverlays.currentIndex === 1) { py.overlayOldMovieFunction() }
                                    else if (idComboBoxImageEffectsOverlays.currentIndex === 2) { py.overlayAlphaClipFunction( overlaysFolder + "winterSnow.mp4", "part", "black:0.3:0.2" ) }
                                    else if (idComboBoxImageEffectsOverlays.currentIndex === 3) { py.imageGeneralEffectFunction( "vignette" ) }
                                }
                                else if ( idComboBoxImageEffects.currentIndex === 2 ) { // repair
                                    if (idComboBoxImageEffectsRepair.currentIndex === 0 ) { py.imageGeneralEffectFunction( "deblock" ) }
                                    else if (idComboBoxImageEffectsRepair.currentIndex === 1 ) { py.imageGeneralEffectFunction( "vaguedenoiser" ) }
                                    else if (idComboBoxImageEffectsRepair.currentIndex === 2 ) { py.imageGeneralEffectFunction( "fftdnoiz" ) } // denoise 3D
                                    else if (idComboBoxImageEffectsRepair.currentIndex === 3 ) { py.imageDeshakeFunction() }
                                    else if (idComboBoxImageEffectsRepair.currentIndex === 4 ) { py.repairFramesFunction() }
                                    else if (idComboBoxImageEffectsRepair.currentIndex === 5 ) { py.imageStabilizeFunction() }
                                }
                                else if ( idComboBoxImageEffects.currentIndex === 3 ) { // detect
                                    if (idComboBoxImageEffectsFinders.currentIndex === 0 ) { py.imageGeneralEffectFunction( "sobel" ) }
                                    else if (idComboBoxImageEffectsFinders.currentIndex === 1 ) { py.imageGeneralEffectFunction( "edgedetect" ) }
                                    else if (idComboBoxImageEffectsFinders.currentIndex === 2 ) { py.removeBWframesFunction( "black" ) }
                                    else if (idComboBoxImageEffectsFinders.currentIndex === 3 ) { py.removeBWframesFunction( "white" ) }
                                }
                                else if ( idComboBoxImageEffects.currentIndex === 4 ) { py.imageFrei0rFunction() } // frei0r plugins
                            }

                            if ( idButtonImageColors.down ) {
                                if ( idComboBoxImageColors.currentIndex === 0 ) { py.imageVibranceFunction() }
                                if ( idComboBoxImageColors.currentIndex === 1 ) { py.imageColorFunction("brightness") }
                                if ( idComboBoxImageColors.currentIndex === 2 ) { py.imageColorFunction("contrast") }
                                if ( idComboBoxImageColors.currentIndex === 3 ) { py.imageColorFunction("saturation") }
                                if ( idComboBoxImageColors.currentIndex === 4 ) { py.imageColorFunction("gamma") }
                                if ( idComboBoxImageColors.currentIndex === 5 ) { py.imageCurveFunction("lighter") }
                                if ( idComboBoxImageColors.currentIndex === 6 ) { py.imageCurveFunction("darker") }
                                if ( idComboBoxImageColors.currentIndex === 7 ) { py.imageCurveFunction("increase_contrast") }
                                if ( idComboBoxImageColors.currentIndex === 8 ) { py.imageLUT3dFunction("cineLessContrast.cube") }
                            }

                            if ( idButtonImageGeometry.down ) {
                                if ( idComboBoxImageGeometry.currentIndex === 0 ) { py.imageMirrorFunction() }
                                if ( idComboBoxImageGeometry.currentIndex === 1 ) { py.imageRotateFunction() }
                            }

                            if ( idButtonImageText.down ) { py.addTextFunction() }

                            if ( idButtonImageOverlays.down && ( (idComboBoxImageOverlayType.currentIndex === 0 && overlayFileLoaded === true)
                                                                || (idComboBoxImageOverlayType.currentIndex === 1 && overlayFileLoaded === true)
                                                                || idComboBoxImageOverlayType.currentIndex === 2
                                                                || idComboBoxImageOverlayType.currentIndex === 3
                                                                ) ) { py.overlayFileFunction() }

                            if ( idButtonImageOverlays.down && idComboBoxImageOverlayType.currentIndex === 4 && overlayFileLoaded === true )  { py.overlayAlphaClipFunction( "file", "part", "manual") }
                        }
                        if ( idButtonAudio.down ) {
                            if (idButtonAudioFade.down === true) {
                                py.audioFadeFunction()
                            }
                            if (idButtonAudioVolume.down === true) {
                                py.audioVolumeFunction()
                            }
                            if (idButtonAudioExtract.down === true) {
                                py.audioExtractFunction()
                            }
                            if (idButtonAudioMixer.down === true && addAudioLoaded === true) {
                                py.audioMixerFunction()
                            }
                            if (idButtonAudioFilters.down === true) {
                                if ( idComboBoxAudioFilters.currentIndex === 0 ) { py.audioEffectsFilters( "denoise" ) }
                                if ( idComboBoxAudioFilters.currentIndex === 1 ) { py.audioEffectsFilters( "echo" ) }
                                if ( idComboBoxAudioFilters.currentIndex === 2 ) { py.audioEffectsFilters( "highpass" ) }
                                if ( idComboBoxAudioFilters.currentIndex === 3 ) { py.audioEffectsFilters( "lowpass" ) }
                            }
                        }

                        if ( idButtonCollage.down ) {
                            if (idButtonCollageSlideshow.down && slideshowModel.count > 0 ) {
                                py.createSlideshowFunction()
                            }
                            if ( idButtonCollageSplitscreen.down && overlayFileLoaded === true ) {
                                py.splitscreenFunction()
                            }
                            if ( idButtonCollageStoryline.down && storylineModel.count > 0 ) {
                                py.createStorylineFunction()
                            }
                            if ( idButtonCollageSubtitle.down && ( (idComboBoxCollageSubtitleAdd.currentIndex === 0 && addSubtitleLoaded === true) || (idComboBoxCollageSubtitleAdd.currentIndex === 1 && subtitleModel.count > 0 ) )) {
                                py.overlaySubtitleFunction()
                            }
                            if ( idButtonCollageImageExtract.down ) {
                                py.extractImagesFunction()
                            }
                        }
                        if ( idButtonFile.down ) {
                            //DISABLE share
                            if (idButtonFileShare.down === true) {
                                /*pageStack.push(Qt.resolvedUrl("SharePage.qml"), {
                                    shareFilePath : idMediaPlayer.source.toString(),
                                    shareFileName : origMediaFileName,
                                    tmpVideoFileSize : tmpVideoFileSize,
                                })*/
                                if (debug) console.log(tmpVideoFileSize)
                            }
                            if (idButtonFileRename.down === true) {
                                py.renameOriginal()
                            }
                            if (idButtonFileDelete.down === true) {
                                remorse.execute( qsTr("Delete file?"))
                            }
                        }
                    }
                }
                Item {
                    width: borderRectTools.width
                    height: borderRectTools.height
                }
            }

            // tool-details CUT
            Row {
                id: idToolsRowCut
                visible: idButtonCut.down
                x: idToolsCategoriesRow.x
                width: idToolsCategoriesRow.width

                IconButton {
                    id: idButtonCutTrim
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    down: true
                    onClicked: {
                        idButtonCutTrim.down = true
                        idButtonCutAdd.down = false
                        idButtonCutCrop.down = false
                        idButtonCutPad.down = false
                        idButtonCutResize.down = false
                        idButtonCutSpeed.down = false
                    }
                    Label {
                        text: qsTr("trim")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
                IconButton {
                    id: idButtonCutAdd
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonCutTrim.down = false
                        idButtonCutAdd.down = true
                        idButtonCutCrop.down = false
                        idButtonCutPad.down = false
                        idButtonCutResize.down = false
                        idButtonCutSpeed.down = false
                    }
                    Label {
                        text: qsTr("insert")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
                IconButton {
                    id: idButtonCutCrop
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonCutTrim.down = false
                        idButtonCutAdd.down = false
                        idButtonCutCrop.down = true
                        idButtonCutPad.down = false
                        idButtonCutResize.down = false
                        idButtonCutSpeed.down = false
                    }
                    Label {
                        text: qsTr("crop")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
                IconButton {
                    id: idButtonCutPad
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonCutTrim.down = false
                        idButtonCutAdd.down = false
                        idButtonCutCrop.down = false
                        idButtonCutPad.down = true
                        idButtonCutResize.down = false
                        idButtonCutSpeed.down = false
                    }
                    Label {
                        text: qsTr("pad")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
                IconButton {
                    id: idButtonCutResize
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonCutTrim.down = false
                        idButtonCutAdd.down = false
                        idButtonCutCrop.down = false
                        idButtonCutPad.down = false
                        idButtonCutResize.down = true
                        idButtonCutSpeed.down = false
                    }
                    Label {
                        text: qsTr("resize")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
                IconButton {
                    id: idButtonCutSpeed
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonCutTrim.down = false
                        idButtonCutAdd.down = false
                        idButtonCutCrop.down = false
                        idButtonCutPad.down = false
                        idButtonCutResize.down = false
                        idButtonCutSpeed.down = true
                    }
                    Label {
                        text: qsTr("speed")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
            }

            // tool-details IMAGE
            Row {
                id: idToolsRowImage
                visible: idButtonImage.down
                x: idToolsCategoriesRow.x
                width: idToolsCategoriesRow.width

                IconButton {
                    id: idButtonImageEffects
                    down: true
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonImageFilters.down = false
                        idButtonImageEffects.down = true
                        idButtonImageGeometry.down = false
                        idButtonImageColors.down = false
                        idButtonImageText.down = false
                        idButtonImageOverlays.down = false
                    }
                    Label {
                        text: qsTr("effects")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
                IconButton {
                    id: idButtonImageFilters
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonImageFilters.down = true
                        idButtonImageEffects.down = false
                        idButtonImageGeometry.down = false
                        idButtonImageColors.down = false
                        idButtonImageText.down = false
                        idButtonImageOverlays.down = false
                    }
                    Label {
                        text: qsTr("filters")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
                IconButton {
                    id: idButtonImageColors
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonImageFilters.down = false
                        idButtonImageEffects.down = false
                        idButtonImageGeometry.down = false
                        idButtonImageColors.down = true
                        idButtonImageText.down = false
                        idButtonImageOverlays.down = false
                    }
                    Label {
                        text: qsTr("colors")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
                IconButton {
                    id: idButtonImageGeometry
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonImageFilters.down = false
                        idButtonImageEffects.down = false
                        idButtonImageGeometry.down = true
                        idButtonImageColors.down = false
                        idButtonImageText.down = false
                        idButtonImageOverlays.down = false
                    }
                    Label {
                        text: qsTr("geometry")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
                IconButton {
                    id: idButtonImageText
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonImageFilters.down = false
                        idButtonImageEffects.down = false
                        idButtonImageGeometry.down = false
                        idButtonImageColors.down = false
                        idButtonImageText.down = true
                        idButtonImageOverlays.down = false
                        idTimerScrollToBottom.start()
                    }
                    Label {
                        text: qsTr("text")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
                IconButton {
                    id: idButtonImageOverlays
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonImageFilters.down = false
                        idButtonImageEffects.down = false
                        idButtonImageGeometry.down = false
                        idButtonImageColors.down = false
                        idButtonImageText.down = false
                        idButtonImageOverlays.down = true
                    }
                    Label {
                        text: qsTr("overlay")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
            }

            // tool-details AUDIO
            Row {
                id: idToolsRowAudio
                visible: idButtonAudio.down
                x: idToolsCategoriesRow.x
                width: idToolsCategoriesRow.width

                IconButton {
                    id: idButtonAudioVolume
                    down: true
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonAudioFade.down = false
                        idButtonAudioFilters.down = false
                        idButtonAudioExtract.down = false
                        idButtonAudioVolume.down = true
                        idButtonAudioMixer.down = false
                        idButtonAudioRecord.down = false
                    }
                    Label {
                        text: qsTr("volume")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
                IconButton {
                    id: idButtonAudioFilters
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonAudioFade.down = false
                        idButtonAudioFilters.down = true
                        idButtonAudioExtract.down = false
                        idButtonAudioVolume.down = false
                        idButtonAudioMixer.down = false
                        idButtonAudioRecord.down = false
                    }
                    Label {
                        text: qsTr("filters")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
                IconButton {
                    id: idButtonAudioFade
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonAudioFade.down = true
                        idButtonAudioFilters.down = false
                        idButtonAudioExtract.down = false
                        idButtonAudioVolume.down = false
                        idButtonAudioMixer.down = false
                        idButtonAudioRecord.down = false
                    }
                    Label {
                        text: qsTr("fade")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
                IconButton {
                    id: idButtonAudioExtract
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonAudioFade.down = false
                        idButtonAudioFilters.down = false
                        idButtonAudioExtract.down = true
                        idButtonAudioVolume.down = false
                        idButtonAudioMixer.down = false
                        idButtonAudioRecord.down = false
                    }
                    Label {
                        text: qsTr("extract")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
                IconButton {
                    id: idButtonAudioMixer
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonAudioFade.down = false
                        idButtonAudioFilters.down = false
                        idButtonAudioExtract.down = false
                        idButtonAudioVolume.down = false
                        idButtonAudioMixer.down = true
                        idButtonAudioRecord.down = false
                        idTimerScrollToBottom.start()
                    }
                    Label {
                        text: qsTr("mixer")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
                IconButton {
                    id: idButtonAudioRecord
                    //visible: false
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonAudioFade.down = false
                        idButtonAudioFilters.down = false
                        idButtonAudioExtract.down = false
                        idButtonAudioVolume.down = false
                        idButtonAudioMixer.down = false
                        idButtonAudioRecord.down = true
                        idTimerScrollToBottom.start()
                    }
                    Label {
                        text: qsTr("recorder")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
            }

            // tool-details COLLAGE
            Row {
                id: idToolsRowCollage
                visible: idButtonCollage.down
                x: idToolsCategoriesRow.x
                width: idToolsCategoriesRow.width

                IconButton {
                    id: idButtonCollageStoryline
                    down: true
                    width: parent.width / 5
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonCollageStoryline.down = true
                        idButtonCollageSlideshow.down = false
                        idButtonCollageSplitscreen.down = false
                        idButtonCollageSubtitle.down = false
                        idButtonCollageImageExtract.down = false
                        idTimerScrollToBottom.start()
                    }
                    Label {
                        text: qsTr("storyline")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
                IconButton {
                    id: idButtonCollageSlideshow
                    width: parent.width / 5
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonCollageStoryline.down = false
                        idButtonCollageSlideshow.down = true
                        idButtonCollageSplitscreen.down = false
                        idButtonCollageSubtitle.down = false
                        idButtonCollageImageExtract.down = false
                        idTimerScrollToBottom.start()
                    }
                    Label {
                        text: qsTr("slideshow")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
                IconButton {
                    id: idButtonCollageSubtitle
                    width: parent.width / 5
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonCollageStoryline.down = false
                        idButtonCollageSlideshow.down = false
                        idButtonCollageSplitscreen.down = false
                        idButtonCollageSubtitle.down = true
                        idButtonCollageImageExtract.down = false
                    }
                    Label {
                        text: qsTr("subtitles")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
                IconButton {
                    id: idButtonCollageSplitscreen
                    width: parent.width / 5
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonCollageStoryline.down = false
                        idButtonCollageSlideshow.down = false
                        idButtonCollageSplitscreen.down = true
                        idButtonCollageSubtitle.down = false
                        idButtonCollageImageExtract.down = false
                    }
                    Label {
                        text: qsTr("splitscreen")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
                IconButton {
                    id: idButtonCollageImageExtract
                    width: parent.width / 5
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonCollageStoryline.down = false
                        idButtonCollageSlideshow.down = false
                        idButtonCollageSplitscreen.down = false
                        idButtonCollageSubtitle.down = false
                        idButtonCollageImageExtract.down = true
                    }
                    Label {
                        text: qsTr("thumbnail")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
            }

            // tool-details FILE
            Row {
                id: idToolsRowFile
                visible: idButtonFile.down
                x: idToolsCategoriesRow.x
                width: idToolsCategoriesRow.width

                //Disable Share
                IconButton {
                    id: idButtonFileShare
                    down: true
                    width: parent.width / 4
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonFileShare.down = true
                        idButtonFileInfo.down = false
                        idButtonFileRename.down = false
                        idButtonFileDelete.down = false
                        idTimerScrollToBottom.start()
                    }
                    Label {
                        text: qsTr("share")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
                IconButton {
                    id: idButtonFileInfo
                    width: parent.width / 4
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonFileShare.down = false
                        idButtonFileInfo.down = true
                        idButtonFileRename.down = false
                        idButtonFileDelete.down = false
                        idTimerScrollToBottom.start()
                    }
                    Label {
                        text: qsTr("fileinfo")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
                IconButton {
                    id: idButtonFileRename
                    width: parent.width / 4
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonFileShare.down = false
                        idButtonFileInfo.down = false
                        idButtonFileRename.down = true
                        idButtonFileDelete.down = false
                    }
                    Label {
                        text: qsTr("rename")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
                IconButton {
                    id: idButtonFileDelete
                    width: parent.width / 4
                    height: Theme.itemSizeSmall
                    onClicked: {
                        idButtonFileShare.down = false
                        idButtonFileInfo.down = false
                        idButtonFileRename.down = false
                        idButtonFileDelete.down = true
                    }
                    Label {
                        text: qsTr("delete")
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: anchors.topMargin
                        color: backColorTools
                    }
                }
                /*
                Rectangle {
                    width: parent.width / 6 * 2
                    y: Theme.paddingMedium
                    height: parent.height - 2*Theme.paddingMedium
                    color: backColorTools
                }
                */
            }


            // more details CUT
            Row {
                id: idToolsRowCutTrim
                visible: (idButtonCut.down && idButtonCutTrim.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                ComboBox {
                    id: idComboBoxCutTrimWhere
                    width: parent.width / 6 * 2
                    description: qsTr("area removal")
                    //_backgroundColor: backColorTools
                    menu: ContextMenu {
                        MenuItem { text: qsTr("marked") }
                        MenuItem { text: qsTr("unmarked") }
                    }
                    onCurrentIndexChanged: {
                        if (idComboBoxCutTrimHow.currentIndex === 2) { idComboBoxCutTrimHow.currentIndex = 0 }
                    }
                }
                ComboBox {
                    id: idComboBoxCutTrimHow
                    width: parent.width / 6 * 4
                    description: qsTr("method suitable for all files")
                    currentIndex: 2
                    menu: ContextMenu {
                        MenuItem { text: qsTr("fast precise (markers)") }
                        MenuItem { text: qsTr("fast quality (i-frames)") }
                        MenuItem {
                            enabled: (idComboBoxCutTrimWhere.currentIndex !== 1)
                            text: qsTr("slow re-encode")
                        }
                    }
                    onCurrentIndexChanged: {
                        if ( currentIndex === 0 ) { description = qsTr("method prefers non-compressed") }
                        if ( currentIndex === 1 ) { description = qsTr("method prefers compressed") }
                        if ( currentIndex === 2 ) { description = qsTr("method suitable for all files") }
                    }
                }
            }
            Row {
                id: idToolsRowCutAdd
                visible: (idButtonCut.down && idButtonCutAdd.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                ComboBox {
                    id: idComboBoxCutAddColor
                    width: parent.width / 6 * 2
                    description: qsTr("frame source")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("black") }
                        MenuItem { text: qsTr("white") }
                        MenuItem { text: qsTr("freeze") }
                        MenuItem { text: qsTr("video file") }
                    }
                }
                Slider {
                    id: idToolsRowCutAddSlider
                    visible: ( idComboBoxCutAddColor.currentIndex !== 3 )
                    width: parent.width / 6 * 4
                    leftMargin: Theme.paddingMedium * 1.1
                    rightMargin: leftMargin
                    minimumValue: 1
                    maximumValue: 60
                    value: 10
                    stepSize: 1
                    handleVisible: false
                    color: Theme.primaryColor

                    Label {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -Theme.paddingSmall / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor //highlightColor
                        text: qsTr("for") + " " + idToolsRowCutAddSlider.value + " s"
                    }
                }
                ValueButton {
                    enabled: ( noFile === false && finishedLoading === true )
                    visible: ( idComboBoxCutAddColor.currentIndex === 3 )
                    width: parent.width / 6 * 4.5
                    height: standardDetailItemHeight
                    value: (addFileLoaded === false) ? qsTr("[none]"): ( addFileName )
                    description: qsTr("file")
                    onClicked: {
                        pageStack.push(addFilePickerPageVideo )
                    }
                }
            }
            Row {
                id: idToolsRowCutCrop
                visible: (idButtonCut.down && idButtonCutCrop.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                ComboBox {
                    id: idComboBoxCutCropRatio
                    width: parent.width / 6 * 6
                    description: qsTr("output")
                    label: qsTr("ratio")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("free") }
                        MenuItem { text: qsTr("original") }
                        MenuItem { text: qsTr("1:1") }
                        MenuItem { text: qsTr("4:3") }
                        MenuItem { text: qsTr("16:9") }
                        MenuItem { text: qsTr("21:9") }
                        MenuItem { text: qsTr("3:4") }
                        MenuItem { text: qsTr("9:16") }
                        MenuItem { text: qsTr("9:21") }
                    }
                    onCurrentIndexChanged: {
                        if (currentIndex === 0) { croppingRatio = 0 }
                        else if (currentIndex === 1) { croppingRatio = origVideoWidth / origVideoHeight }
                        else if (currentIndex === 2) { croppingRatio = 1 }
                        else if (currentIndex === 3) { croppingRatio = 4/3 }
                        else if (currentIndex === 4) { croppingRatio = 16/9 }
                        else if (currentIndex === 5) { croppingRatio = 21/9 }
                        else if (currentIndex === 6) { croppingRatio = 3/4 }
                        else if (currentIndex === 7) { croppingRatio = 9/16 }
                        else if (currentIndex === 8) { croppingRatio = 9/21 }
                        setCropmarkersRatio() // reset crop markers
                    }
                }
            }
            Row {
                id: idToolsRowCutPad
                visible: (idButtonCut.down && idButtonCutPad.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                ComboBox {
                    id: idComboBoxCutPadRatio
                    width: parent.width / 6 * 2
                    description: qsTr("output")
                    label: qsTr("ratio")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("1:1") }
                        MenuItem { text: qsTr("4:3") }
                        MenuItem { text: qsTr("16:9") }
                        MenuItem { text: qsTr("21:9") }
                        MenuItem { text: qsTr("3:4") }
                        MenuItem { text: qsTr("9:16") }
                        MenuItem { text: qsTr("9:21") }
                    }
                    onCurrentIndexChanged: {
                        if (currentIndex === 0) {
                            padRatioText = "1/1"
                            padRatio = 1
                        }
                        else if (currentIndex === 1) {
                            padRatioText = "4/3"
                            padRatio = 4/3
                        }
                        else if (currentIndex === 2) {
                            padRatioText = "16/9"
                            padRatio = 16/9
                        }
                        else if (currentIndex === 3) {
                            padRatioText = "21/9"
                            padRatio = 21/9
                        }
                        else if (currentIndex === 4) {
                            padRatioText = "3/4"
                            padRatio = 3/4
                        }
                        else if (currentIndex === 5) {
                            padRatioText = "9/16"
                            padRatio = 9/16
                        }
                        else if (currentIndex === 6) {
                            padRatioText = "9/21"
                            padRatio = 9/21
                        }
                    }
                }
                ComboBox {
                    id: idComboBoxCutPadUpDown
                    width: parent.width / 6 * 4
                    description: qsTr("method")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("expand") }
                        MenuItem { text: qsTr("reduce") }
                    }
                }
            }
            Row {
                id: idToolsRowCutResize
                visible: (idButtonCut.down && idButtonCutResize.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                ComboBox {
                    id: idComboBoxCutResizeMaindimension
                    width: parent.width / 6 * 2
                    description: qsTr("target")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("width") }
                        MenuItem { text: qsTr("height") }
                        MenuItem { text: qsTr("pad") }
                        MenuItem { text: qsTr("stretch") }
                    }
                }
                Item {
                    width: parent.width / 6 * 4
                    height: standardDetailItemHeight
                    Row {
                        width: parent.width
                        height: parent.height
                        TextField {
                            id: idToolsCutDetailsColumn3Width
                            enableSoftwareInputPanel: ( idComboBoxCutResizeMaindimension.currentIndex !== 1 )
                            enabled: ( idComboBoxCutResizeMaindimension.currentIndex !== 1 )
                            width: parent.width / 2
                            height: Theme.itemSizeMedium
                            textTopMargin: Theme.paddingMedium
                            text: ( idComboBoxCutResizeMaindimension.currentIndex !== 1 ) ? sourceVideoWidth : qsTr("auto")
                            color: Theme.highlightColor
                            inputMethodHints: Qt.ImhDigitsOnly
                            validator: IntValidator { bottom: 1; top: 9999 }
                            EnterKey.onClicked: {
                                if (idToolsCutDetailsColumn3Width.text < 1 || idToolsCutDetailsColumn3Width.text === "") {
                                    idToolsCutDetailsColumn3Width.text = sourceVideoWidth
                                }
                                idToolsCutDetailsColumn3Width.focus = false
                            }
                            /*
                            Label {
                                anchors.left: parent.right
                                anchors.leftMargin: - 2 * width
                                anchors.verticalCenter: parent.verticalCenter
                                font.pixelSize: Theme.fontSizeExtraSmall
                                color: Theme.secondaryColor
                                text: qsTr("px")
                            }
                            */
                            Label {
                                anchors.top: parent.bottom
                                font.pixelSize: Theme.fontSizeExtraSmall
                                color: Theme.secondaryColor
                                text: qsTr("px-width")
                            }
                        }
                        TextField {
                            id: idToolsCutDetailsColumn3Height
                            enableSoftwareInputPanel: ( idComboBoxCutResizeMaindimension.currentIndex !== 0 )
                            enabled: ( idComboBoxCutResizeMaindimension.currentIndex !== 0 )
                            width: parent.width / 2
                            height: Theme.itemSizeMedium
                            textTopMargin: Theme.paddingMedium
                            text: ( idComboBoxCutResizeMaindimension.currentIndex !== 0 ) ? sourceVideoHeight : qsTr("auto")
                            color: Theme.highlightColor
                            inputMethodHints: Qt.ImhDigitsOnly
                            validator: IntValidator { bottom: 1; top: 9999 }
                            EnterKey.onClicked: {
                                if (idToolsCutDetailsColumn3Height.text < 1 || idToolsCutDetailsColumn3Height.text === "") {
                                    idToolsCutDetailsColumn3Height.text = sourceVideoHeight
                                }
                                idToolsCutDetailsColumn3Height.focus = false
                            }
                            /*
                            Label {
                                anchors.left: parent.right
                                anchors.leftMargin: - 2 * width
                                anchors.verticalCenter: parent.verticalCenter
                                font.pixelSize: Theme.fontSizeExtraSmall
                                color: Theme.secondaryColor
                                text: qsTr("px")
                            }
                            */
                            Label {
                                anchors.top: parent.bottom
                                font.pixelSize: Theme.fontSizeExtraSmall
                                color: Theme.secondaryColor
                                text: qsTr("px-height")
                            }
                        }

                    }
                }
            }
            Row {
                id: idToolsRowCutSpeed
                visible: (idButtonCut.down && idButtonCutSpeed.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                Slider {
                    id: idToolsCutDetailsColumnCut3SpeedSlider
                    width: parent.width / 6 * 6
                    leftMargin: Theme.paddingMedium * 1.1
                    rightMargin: leftMargin
                    minimumValue: 0.5
                    maximumValue: 2
                    value: 1
                    stepSize: 0.01
                    smooth: true
                    handleVisible: false
                    color: Theme.primaryColor

                    Label {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -Theme.paddingSmall / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor //highlightColor
                        text: idToolsCutDetailsColumnCut3SpeedSlider.value + " x"
                    }
                }
            }


            // more details IMAGE
            Row {
                id: idToolsRowImageFilters
                visible: (idButtonImage.down && idButtonImageFilters.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                ComboBox {
                    id: idComboBoxImageFilters
                    width: ( currentIndex !== 0 ) ? parent.width : (parent.width / 6 * 2)
                    description: qsTr("presets")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("LUT/HALD") }
                        MenuItem { text: qsTr("anime") }
                        MenuItem { text: qsTr("black and white") }
                        MenuItem { text: qsTr("bleak future") }
                        MenuItem { text: qsTr("bleach") }
                        MenuItem { text: qsTr("cold") }
                        MenuItem { text: qsTr("drama") }
                        MenuItem { text: qsTr("fall colors") }
                        MenuItem { text: qsTr("moonlight") }
                        MenuItem { text: qsTr("negative") }
                        MenuItem { text: qsTr("old style") }
                        MenuItem { text: qsTr("orange-teal") }
                        MenuItem { text: qsTr("spring colors") }
                        MenuItem { text: qsTr("summer colors") }
                        MenuItem { text: qsTr("teal-magenta-gold") }
                        MenuItem { text: qsTr("sunset") }
                        MenuItem { text: qsTr("vibrant") }
                        MenuItem { text: qsTr("vintage") }
                        MenuItem { text: qsTr("warm") }
                        MenuItem { text: qsTr("winter") }
                    }
                }
                ValueButton {
                    enabled: ( noFile === false && finishedLoading === true )
                    width: parent.width / 6 * 4
                    height: standardDetailItemHeight
                    value: (cubeFileLoaded === false) ? qsTr("[none]"): ( cubeFileName )
                    description: qsTr("file")
                    onClicked: {
                        pageStack.push(lutHaldFilePickerPage)
                    }
                }
            }
            Row {
                id: idToolsRowImageEffects
                visible: (idButtonImage.down && idButtonImageEffects.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                ComboBox {
                    id: idComboBoxImageEffects
                    width: parent.width / 6 * 2
                    description: qsTr("apply")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("basics") }
                        MenuItem { text: qsTr("overlays") }
                        MenuItem { text: qsTr("repairs") }
                        MenuItem { text: qsTr("finder") }
                        MenuItem { text: qsTr("frei0r FX") }
                    }
                }
                ComboBox {
                    id: idComboBoxImageEffectsBasics
                    visible: (idComboBoxImageEffects.currentIndex === 0)
                    width: (currentIndex === 0 || currentIndex === 1) ? (parent.width / 6 * 2) : (parent.width / 6 * 4)
                    description: qsTr("effect")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("fade") }
                        MenuItem { text: qsTr("blur") }
                        MenuItem { text: qsTr("sharpen") }
                        MenuItem { text: qsTr("erosion") }
                        MenuItem { text: qsTr("normalize") }
                        MenuItem { text: qsTr("reverse") }
                        //MenuItem { text: qsTr("anti-epileptics") } //photosensitivity filter gives error on playback as of ffmpeg_static Jan21
                        //MenuItem { text: qsTr("stereo3d") } //stereo3d filter gives error on playback as of ffmpeg_static Jan21
                        // MenuItem { text: qsTr("x-deshake (intense analysis)") }
                        // MenuItem { text: qsTr("deflate") } // works, but little effect
                        // MenuItem { text: qsTr("inflate") } // works, but little effect
                        // MenuItem { text: qsTr("telecine") } // works, but little effect
                        // MenuItem { text: qsTr("de-rain") } // needs some extra file
                        // MenuItem { text: qsTr("posterize (elbg)") } // process is too slow
                    }
                }
                ComboBox {
                    id: idComboBoxImageEffectsFade
                    visible: ( idComboBoxImageEffects.currentIndex === 0 && idComboBoxImageEffectsBasics.currentIndex === 0 )
                    width: parent.width / 6 * 2
                    description: qsTr("direction")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("from black - clip") }
                        MenuItem { text: qsTr("to black - clip") }
                        MenuItem { text: qsTr("from black - markers") }
                        MenuItem { text: qsTr("to black - markers") }
                    }
                }
                ComboBox {
                    id: idComboBoxImageEffectsBlurDirection
                    visible: ( idComboBoxImageEffects.currentIndex === 0 && idComboBoxImageEffectsBasics.currentIndex === 1)
                    width: parent.width / 6 * 2
                    description: qsTr("region")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("inside") }
                        MenuItem { text: qsTr("outside") }
                    }
                }
                ComboBox {
                    id: idComboBoxImageEffectsOverlays
                    visible: (idComboBoxImageEffects.currentIndex === 1)
                    width: parent.width / 6 * 4
                    description: qsTr("effect")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("flower rain") }
                        MenuItem { text: qsTr("old film") }
                        MenuItem { text: qsTr("snow falling") }
                        MenuItem { text: qsTr("vignette") }
                    }
                }
                ComboBox {
                    id: idComboBoxImageEffectsRepair
                    visible: (idComboBoxImageEffects.currentIndex === 2)
                    width: parent.width / 6 * 4
                    description: qsTr("effect")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("de-block") }
                        MenuItem { text: qsTr("de-noise") }
                        MenuItem { text: qsTr("de-noise 3D") } //fftdnoiz
                        MenuItem { text: qsTr("de-shake quality") }
                        MenuItem { text: qsTr("repair bad frames") }
                        MenuItem { text: qsTr("stabilize (full clip)") }
                    }
                }
                ComboBox {
                    id: idComboBoxImageEffectsFinders
                    visible: (idComboBoxImageEffects.currentIndex === 3)
                    width: parent.width / 6 * 4
                    description: qsTr("find")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("contour (sobel)") }
                        MenuItem { text: qsTr("find edges") }
                        MenuItem { text: qsTr("clear black frames (covered lens)") }
                        MenuItem { text: qsTr("clear white frames (strobe flash)") }
                    }
                }
                ComboBox {
                    id: idComboBoxImageEffectsFrei0r
                    visible: (idComboBoxImageEffects.currentIndex === 4)
                    width: parent.width / 6 * 4
                    description: qsTr("effect (full clip)")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("pixelize") }
                        MenuItem { text: qsTr("lenscorrection") }
                        MenuItem { text: qsTr("drunken (vertigo)") }
                        MenuItem { text: qsTr("posterize") }
                        MenuItem { text: qsTr("glow") }
                        MenuItem { text: qsTr("add glitches") }
                        MenuItem { text: qsTr("whitebalance") }
                    }
                }
            }
            Row {
                id: idToolsRowImageEffectsBasics
                visible: (idButtonImage.down && idButtonImageEffects.down && idComboBoxImageEffects.currentIndex === 0 && (idComboBoxImageEffectsBasics.currentIndex === 1 || idComboBoxImageEffectsBasics.currentIndex === 2) )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                Slider {
                    id: idToolsRowImageEffectsBlurSlider
                    visible: idComboBoxImageEffectsBasics.currentIndex === 1
                    width: parent.width // 6 * 4
                    leftMargin: Theme.paddingSmall + Theme.paddingMedium
                    rightMargin: leftMargin
                    minimumValue: 0
                    maximumValue: 30
                    value: 10
                    stepSize: 1
                    handleVisible: false
                    color: Theme.primaryColor

                    Label {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -Theme.paddingSmall / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor //highlightColor
                        text: qsTr("intensity") + " " + parent.value
                    }
                }
                Slider {
                    id: idToolsRowImageEffectsSharpenSlider
                    visible: idComboBoxImageEffectsBasics.currentIndex === 2
                    width: parent.width // 6 * 4
                    leftMargin: Theme.paddingSmall + Theme.paddingMedium
                    rightMargin: leftMargin
                    minimumValue: 0
                    maximumValue: 4
                    value: 1
                    stepSize: 0.05
                    handleVisible: false
                    color: Theme.primaryColor

                    Label {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -Theme.paddingSmall / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor //highlightColor
                        text: qsTr("intensity") + " " + parent.value
                    }
                }

            }
            Row {
                id: idToolsRowImageEffectsFrameDetectionBW
                visible: (idButtonImage.down && idButtonImageEffects.down && idComboBoxImageEffects.currentIndex === 3 && (idComboBoxImageEffectsFinders.currentIndex === 2 || idComboBoxImageEffectsFinders.currentIndex === 3) )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                Slider {
                    id: idToolsRowImageEffectsFrameDetectionBW_amount
                    width: parent.width / 6 * 3
                    leftMargin: Theme.paddingMedium * 1.1
                    rightMargin: leftMargin
                    minimumValue: 1
                    maximumValue: 100
                    value: 98
                    stepSize: 1
                    handleVisible: false
                    color: Theme.primaryColor

                    Label {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -Theme.paddingSmall / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor //highlightColor
                        text: (idComboBoxImageEffectsFinders.currentIndex === 2) ? (parent.value + " " + qsTr("% pixels black")) : (parent.value + " " + qsTr("% pixels white"))
                    }
                }
                Slider {
                    id: idToolsRowImageEffectsFrameDetectionBW_treshold
                    width: parent.width / 6 * 3
                    leftMargin: Theme.paddingMedium * 1.1
                    rightMargin: leftMargin
                    minimumValue: 1
                    maximumValue: 255
                    value: 32
                    stepSize: 1
                    handleVisible: false
                    color: Theme.primaryColor

                    Label {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -Theme.paddingSmall / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor //highlightColor
                        text: (idComboBoxImageEffectsFinders.currentIndex === 2) ? (qsTr("black treshold <") + " " + parent.value) : (qsTr("white treshold <") + " " + parent.value)
                    }
                }


            }
            Row {
                id: idToolsRowImageColors
                visible: (idButtonImage.down && idButtonImageColors.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                ComboBox {
                    id: idComboBoxImageColors
                    width: ( currentIndex === 0 || currentIndex === 1 || currentIndex === 2 || currentIndex === 3 || currentIndex === 4 ) ? (parent.width / 6 * 2) : (parent.width)
                    description: qsTr("apply")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("vibrance") }
                        MenuItem { text: qsTr("brightness") }
                        MenuItem { text: qsTr("contrast") }
                        MenuItem { text: qsTr("saturation") }
                        MenuItem { text: qsTr("gamma") }
                        MenuItem { text: qsTr("light (+)") }
                        MenuItem { text: qsTr("light (-)") }
                        MenuItem { text: qsTr("contrast (+)") }
                        MenuItem { text: qsTr("contrast (-)") }
                    }
                }
                Slider {
                    id: idToolsRowImageColorsVibranceSlider
                    visible: ( idComboBoxImageColors.currentIndex === 0 )
                    width: parent.width / 6 * 4
                    leftMargin: Theme.paddingMedium * 1.1
                    rightMargin: leftMargin
                    minimumValue: -2
                    maximumValue: 2
                    value: 0
                    stepSize: 0.01
                    handleVisible: false
                    color: Theme.primaryColor

                    Label {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -Theme.paddingSmall / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        text: (parent.value < 0) ? (parent.value) : ("+" + parent.value)
                    }
                }
                Slider {
                    id: idToolsRowImageColorsBrightnessSlider
                    visible: ( idComboBoxImageColors.currentIndex === 1 )
                    width: parent.width / 6 * 4
                    leftMargin: Theme.paddingMedium * 1.1
                    rightMargin: leftMargin
                    minimumValue: -1
                    maximumValue: 1
                    value: 0
                    stepSize: 0.01 / 2
                    handleVisible: false
                    color: Theme.primaryColor

                    Label {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -Theme.paddingSmall / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        text: (parent.value < 0) ? (parent.value * 2) : ("+" + parent.value * 2)
                    }
                }
                Slider {
                    id: idToolsRowImageColorsContrastSlider
                    visible: ( idComboBoxImageColors.currentIndex === 2 )
                    width: parent.width / 6 * 4
                    leftMargin: Theme.paddingMedium * 1.1
                    rightMargin: leftMargin
                    minimumValue: -1000
                    maximumValue: 1000
                    value: 0
                    stepSize: 0.01 * 500
                    handleVisible: false
                    color: Theme.primaryColor

                    Label {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -Theme.paddingSmall / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        text: (parent.value < 0) ? (parent.value / 500) : ("+" + parent.value / 500)
                    }
                }
                Slider {
                    id: idToolsRowImageColorsSaturationSlider
                    visible: ( idComboBoxImageColors.currentIndex === 3 )
                    width: parent.width / 6 * 4
                    leftMargin: Theme.paddingMedium * 1.1
                    rightMargin: leftMargin
                    minimumValue: 0
                    maximumValue: 3
                    value: 1
                    stepSize: 0.01
                    handleVisible: false
                    color: Theme.primaryColor

                    Label {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -Theme.paddingSmall / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        text: (parent.value < 0) ? (parent.value) : ( parent.value )
                    }
                }
                Slider {
                    id: idToolsRowImageColorsGammaSlider
                    visible: ( idComboBoxImageColors.currentIndex === 4 )
                    width: parent.width / 6 * 4
                    leftMargin: Theme.paddingMedium * 1.1
                    rightMargin: leftMargin
                    minimumValue: 0.1
                    maximumValue: 10
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
                        text: (parent.value < 0) ? (parent.value) : (parent.value)
                    }
                }
            }
            Row {
                id: idToolsRowImageGeometry
                visible: (idButtonImage.down && idButtonImageGeometry.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                ComboBox {
                    id: idComboBoxImageGeometry
                    width: parent.width / 6 * 2
                    description: qsTr("modus")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("mirror") }
                        MenuItem { text: qsTr("rotate") }
                    }
                }
                ComboBox {
                    id: idComboBoxImageGeometryMirror
                    visible: ( idComboBoxImageGeometry.currentIndex === 0 )
                    width: parent.width / 6 * 4
                    description: qsTr("direction")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("horizontal") }
                        MenuItem { text: qsTr("vertical") }
                    }
                }
                ComboBox {
                    id: idComboBoxImageGeometryRotate
                    visible: ( idComboBoxImageGeometry.currentIndex === 1 )
                    width: parent.width / 6 * 4
                    description: qsTr("angle")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("90° right") }
                        MenuItem { text: qsTr("90° left") }
                    }
                }
            }
            Row {
                id: idToolsRowImageText
                visible: (idButtonImage.down && idButtonImageText.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                ComboBox {
                    id: idComboBoxImageTextSize
                    width: parent.width / 6 * 1.5
                    currentIndex: 5 // extra large
                    description: qsTr("font-size")
                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("tiny")
                        }
                        MenuItem {
                            text: qsTr("small 1")
                        }
                        MenuItem {
                            text: qsTr("small 2")
                        }
                        MenuItem {
                            text: qsTr("medium")
                        }
                        MenuItem {
                            text: qsTr("large 1")
                        }
                        MenuItem {
                            text: qsTr("large 2")
                        }
                        MenuItem {
                            text: qsTr("huge 1")
                        }
                        MenuItem {
                            text: qsTr("huge 2")
                        }
                        MenuItem {
                            text: qsTr("huge 3")
                        }
                    }
                    onCurrentIndexChanged: {
                        if ( currentIndex === 0 ) { fontSizePreview = Theme.fontSizeTiny }
                        if ( currentIndex === 1 ) { fontSizePreview = Theme.fontSizeExtraSmall }
                        if ( currentIndex === 2 ) { fontSizePreview = Theme.fontSizeSmall }
                        if ( currentIndex === 3 ) { fontSizePreview = Theme.fontSizeMedium }
                        if ( currentIndex === 4 ) { fontSizePreview = Theme.fontSizeLarge }
                        if ( currentIndex === 5 ) { fontSizePreview = Theme.fontSizeExtraLarge }
                        if ( currentIndex === 6 ) { fontSizePreview = Theme.fontSizeHuge }
                        if ( currentIndex === 7 ) { fontSizePreview = Theme.fontSizeHuge * 1.25 }
                        if ( currentIndex === 8 ) { fontSizePreview = Theme.fontSizeHuge * 1.5 }
                    }
                }
                Slider {
                    id: idToolsRowImageTextboxOpacity
                    width: parent.width / 6 * 3
                    leftMargin: Theme.paddingMedium * 1.1
                    rightMargin: leftMargin
                    minimumValue: 0
                    maximumValue: 1
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
                        text: qsTr("background") + " " + Math.round(parent.value * 100) + " %"
                    }
                }
                ComboBox {
                    id: idComboBoxImageTextColor
                    width: parent.width / 6 * 1.5
                    description: qsTr("color-set")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("white"); color : "white" }
                        MenuItem { text: qsTr("black"); color : "black" }
                        MenuItem { text: qsTr("yellow"); color : "yellow" }
                        MenuItem { text: qsTr("red"); color : "red" }
                    }
                    onCurrentIndexChanged: {
                         if ( currentIndex === 0 ) {
                             addTextColor = "white"
                             addTextboxColor = "black"
                         }
                         if ( currentIndex === 1 ) {
                             addTextColor = "black"
                             addTextboxColor = "white"
                         }
                         if ( currentIndex === 2 ) {
                             addTextColor = "yellow"
                             addTextboxColor = "black"
                         }
                         if ( currentIndex === 3 ) {
                             addTextColor = "red"
                             addTextboxColor = "white"
                         }
                    }
                }
            }
            Row {
                id: idToolsRowImageTextInput
                visible: (idButtonImage.down && idButtonImageText.down )
                enabled: ( finishedLoading === true )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                Item {
                    width: parent.width / 6 * 4.5
                    height: parent.height

                    TextField {
                        id: idToolsImageTextInput
                        width: parent.width
                        textTopMargin: Theme.paddingLarge
                        inputMethodHints: Qt.ImhNoPredictiveText
                        font.pixelSize: Theme.fontSizeExtraSmall
                        placeholderText: qsTr("type here ...")
                        validator: RegExpValidator { regExp: /^[^<>'\"/;*:`#?]*$/ } // negative list
                        EnterKey.onClicked: {
                            idSilicaFlickable.scrollToTop()
                            idToolsImageTextInput.focus = false
                        }
                    }
                }
                Item {
                    width: parent.width / 5
                    height: parent.height

                    Label {
                        width: parent.width
                        color: Theme.highlightColor
                        anchors.bottom: parent.verticalCenter
                        horizontalAlignment: Text.AlignHCenter
                        truncationMode: TruncationMode.Elide
                        font.pixelSize: Theme.fontSizeExtraSmall
                        text: (fontFileLoaded === false) ? qsTr("[font]") : ( customFontName )
                    }
                    MouseArea {
                        enabled: ( noFile === false && finishedLoading === true )
                        anchors.fill: parent
                        onClicked: {
                            pageStack.push(fontPickerPage)
                        }
                        onPressAndHold: {
                            fontFileLoaded = false
                            idPaintTextPreview.font.family = standardFont
                        }
                    }
                }
                /*
                ValueButton {
                    width: parent.width / 6 * 1.5
                    enabled: ( noFile === false && finishedLoading === true )
                    height: standardDetailItemHeight
                    value: qsTr("font")
                    description: (fontFileLoaded === false) ? qsTr("[Sailfish]") : ( customFontName )
                    onClicked: {
                        pageStack.push(fontPickerPage)
                    }
                    onPressAndHold: {
                        fontFileLoaded = false
                        idPaintTextPreview.font.family = standardFont
                    }
                }
                */
            }
            Row {
                id: idToolsRowImageOverlays
                visible: (idButtonImage.down && idButtonImageOverlays.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                ComboBox {
                    id: idComboBoxImageOverlayType
                    width: parent.width / 6 * 1.5
                    description: qsTr("type")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("image") }
                        MenuItem { text: qsTr("video") }
                        MenuItem { text: qsTr("rectangle") }
                        MenuItem { text: qsTr("frame") }
                        MenuItem { text: qsTr("greenscreen") }
                    }
                    onCurrentIndexChanged: {
                        clearOverlayFunction()
                    }
                }
                ValueButton {
                    width: parent.width / 6 * 2
                    enabled: ( noFile === false && finishedLoading === true )
                    visible: ( idComboBoxImageOverlayType.currentIndex === 0 || idComboBoxImageOverlayType.currentIndex === 1 )
                    height: standardDetailItemHeight
                    value: (overlayFileLoaded === false) ? qsTr("[none]"): ( overlayFileName )
                    description: qsTr("file")
                    onClicked: {
                        if ( idComboBoxImageOverlayType.currentIndex === 0 ) { pageStack.push(overlayFilePickerPageImage) }
                        else if ( idComboBoxImageOverlayType.currentIndex === 1 ) { pageStack.push(overlayFilePickerPageVideo) }
                        else if ( idComboBoxImageOverlayType.currentIndex === 2 ) {
                            clearOverlayFunction()
                            croppingRatio = 0
                            setCropmarkersRatio()
                        }
                    }
                }
                ComboBox {
                    id: idComboBoxImageOverlayTypeRectangle
                    visible: ( idComboBoxImageOverlayType.currentIndex === 2 || idComboBoxImageOverlayType.currentIndex === 3 )
                    width: (parent.width / 6 * 2)
                    description: qsTr("color")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("black"); color : "black" }
                        MenuItem { text: qsTr("white"); color : "white" }
                        MenuItem { text: qsTr("yellow"); color : "yellow" }
                        MenuItem { text: qsTr("red"); color : "red" }
                        MenuItem { text: qsTr("green"); color : "green" }
                    }
                    onCurrentIndexChanged: {
                        if (currentIndex === 0) { drawRectangleColor = "black" }
                        else if (currentIndex === 1) { drawRectangleColor = "white" }
                        else if (currentIndex === 2) { drawRectangleColor = "yellow" }
                        else if (currentIndex === 3) { drawRectangleColor = "red" }
                        else if (currentIndex === 3) { drawRectangleColor = "green" }
                    }
                }
                Slider {
                    id: idToolsRowImageOverlayOpacitySlider
                    visible: ( idComboBoxImageOverlayType.currentIndex === 0 || idComboBoxImageOverlayType.currentIndex === 1 || idComboBoxImageOverlayType.currentIndex === 2 )
                    width: parent.width / 6 * 2.5
                    leftMargin: Theme.paddingMedium * 1.1
                    rightMargin: leftMargin
                    minimumValue: 0
                    maximumValue: 1
                    value: 0.6
                    stepSize: 0.01
                    handleVisible: false
                    color: Theme.primaryColor

                    Label {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -Theme.paddingSmall / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        text: qsTr("opacity") + " " + Math.round(parent.value * 100) + " %"
                    }
                }
                Slider {
                    id: idToolsRowImageOverlayFrameSizeSlider
                    visible: (idComboBoxImageOverlayType.currentIndex === 3 )
                    width: parent.width / 6 * 2.5
                    leftMargin: Theme.paddingMedium * 1.1
                    rightMargin: leftMargin
                    minimumValue: 0.1
                    maximumValue: 7
                    value: 1
                    stepSize: 0.1
                    handleVisible: false
                    color: Theme.primaryColor

                    Label {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -Theme.paddingSmall / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        text: qsTr("size") + " " + parent.value
                    }
                }
                ValueButton {
                    width: parent.width / 6 * 2
                    enabled: ( noFile === false && finishedLoading === true )
                    visible: ( idComboBoxImageOverlayType.currentIndex === 4 )
                    height: standardDetailItemHeight
                    value: (overlayFileLoaded === false) ? qsTr("[none]"): ( overlayFileName )
                    description: qsTr("file")
                    onClicked: {
                        pageStack.push(overlayFilePickerPageAlpha)
                    }
                }
                ComboBox {
                    id: idComboBoxImageOverlayAlphaStretch
                    visible: ( idComboBoxImageOverlayType.currentIndex === 4 )
                    width: parent.width / 6 * 2
                    description: qsTr("size")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("fill") }
                        MenuItem { text: qsTr("manual") }
                    }
                }
            }
            Row {
                id: idToolsRowImageOverlaysAlpha
                visible: (idButtonImage.down && idButtonImageOverlays.down && idComboBoxImageOverlayType.currentIndex === 4)
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                ComboBox {
                    id: idComboBoxImageOverlayTypeColorToAlpha
                    width: (parent.width / 6 * 1.5)
                    description: qsTr("alpha")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("black"); color : "black" }
                        MenuItem { text: qsTr("white"); color : "white" }
                        MenuItem { text: qsTr("green"); color : "green" }
                        MenuItem { text: qsTr("blue"); color : "blue" }
                    }
                    onCurrentIndexChanged: {
                        if (currentIndex === 0) { colorToAlpha = "black" }
                        else if (currentIndex === 1) { colorToAlpha = "white" }
                        else if (currentIndex === 2) { colorToAlpha = "green" } //0x44FB00
                        else if (currentIndex === 3) { colorToAlpha = "blue" }
                    }
                }
                Slider {
                    id: idToolsRowImageOverlayAlphaSlider_Similarity
                    width: parent.width / 6 * 2.25
                    leftMargin: Theme.paddingMedium * 1.1
                    rightMargin: leftMargin
                    minimumValue: 0
                    maximumValue: 1
                    value: 0.3
                    stepSize: 0.01
                    handleVisible: false
                    color: Theme.primaryColor

                    Label {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -Theme.paddingSmall / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        text: qsTr("color similarity") + " " + parent.value
                    }
                }
                Slider {
                    id: idToolsRowImageOverlayAlphaSlider_Blend
                    visible: idComboBoxImageOverlayTypeColorToAlpha.visible
                    width: parent.width / 6 * 2.25
                    leftMargin: Theme.paddingMedium * 1.1
                    rightMargin: leftMargin
                    minimumValue: 0
                    maximumValue: 1
                    value: 0.2
                    stepSize: 0.01
                    handleVisible: false
                    color: Theme.primaryColor

                    Label {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -Theme.paddingSmall / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        text: qsTr("edge blend") + " " + parent.value
                    }
                }
            }


            // more details AUDIO
            Row {
                id: idToolsRowAudioFade
                visible: (idButtonAudio.down && idButtonAudioFade.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
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
                }
            }
            Row {
                id: idToolsRowAudioVolume
                visible: (idButtonAudio.down && idButtonAudioVolume.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
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
                id: idToolsRowAudioExtract
                visible: (idButtonAudio.down && idButtonAudioExtract.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
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
                visible: (idButtonAudio.down && idButtonAudioMixer.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
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
                visible: ( idButtonAudio.down && idButtonAudioRecord.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
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
                visible: (idButtonAudio.down && (idButtonAudioMixer.down || idButtonAudioRecord.down) )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                ValueButton {
                    visible: idButtonAudioRecord.down
                    width: parent.width / 6 * 2
                    height: standardDetailItemHeight
                    value: qsTr("recording")
                    valueColor: Theme.primaryColor //highlightColor
                    description: qsTr("overlay audio")
                }
                ValueButton {
                    visible: idButtonAudioMixer.down
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
                visible: (idButtonAudio.down && (idButtonAudioMixer.down || idButtonAudioRecord.down) )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
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
            Row {
                id: idToolsRowAudioFilters
                visible: (idButtonAudio.down && idButtonAudioFilters.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
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


            // more details COLLAGE
            Row {
                id: idToolsRowCollageSplitscreen
                visible: (idButtonCollage.down && idButtonCollageSplitscreen.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                ComboBox {
                    id: idComboBoxCollageSplitscreen
                    width: parent.width / 6 * 2
                    description:  qsTr("new clip")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("above") }
                        MenuItem { text: qsTr("below") }
                        MenuItem { text: qsTr("left") }
                        MenuItem { text: qsTr("right") }
                    }
                }
                ValueButton {
                    width: parent.width / 6 * 2
                    enabled: ( noFile === false && finishedLoading === true )
                    height: standardDetailItemHeight
                    value: (overlayFileLoaded === false) ? qsTr("[none]"): ( overlayFileName )
                    description: qsTr("file")
                    onClicked: {
                        pageStack.push(timelineFilePickerPage)
                    }
                }
                ComboBox {
                    id: idComboBoxCollageSplitscreenAudio
                    width: parent.width / 6 * 2
                    description:  qsTr("use audio from")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("new clip") }
                        MenuItem { text: qsTr("source clip") }
                        MenuItem { text: qsTr("none") }
                        MenuItem { text: qsTr("both") }
                    }
                }
            }
            Row {
                id: idToolsRowCollage1
                visible: (idButtonCollage.down && ( idButtonCollageSlideshow.down || idButtonCollageStoryline.down ) )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                ComboBox {
                    id: idComboBoxCollageSlideshowEffect
                    visible: idButtonCollageSlideshow.down
                    width: parent.width / 6 * 3
                    description: (currentIndex === 0) ? qsTr("no camera movement") : qsTr("camera movement")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("still images") }
                        MenuItem { text: qsTr("random pan & zoom") }
                    }
                }
                ValueButton {
                    id: idComboBoxCollageStorylineEffect
                    visible: idButtonCollageStoryline.down
                    width: parent.width / 6 * 3
                    height: standardDetailItemHeight
                    value: qsTr("target resolution")
                    valueColor: Theme.primaryColor
                    description: qsTr("keep low on phones")
                }
                TextField {
                    id: idToolsCollageTargetWidth
                    width: parent.width / 6 * 1.5
                    height: Theme.itemSizeMedium
                    textTopMargin: Theme.paddingMedium
                    text: "1024"
                    color: Theme.highlightColor
                    inputMethodHints: Qt.ImhDigitsOnly
                    validator: IntValidator { bottom: 0; top: 9999 }
                    EnterKey.onClicked: {
                        if (idToolsCollageTargetWidth.text.length < 1  || idToolsCollageTargetWidth.text === "" ) {
                            idToolsCollageTargetWidth.text = "1024"
                        }
                        idToolsCollageTargetWidth.focus = false
                    }
                    Label {
                        anchors.top: parent.bottom
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        text: qsTr("px-width")
                    }
                }
                TextField {
                    id: idToolsCollageTargetHeight
                    width: parent.width / 6 * 1.5
                    height: Theme.itemSizeMedium
                    textTopMargin: Theme.paddingMedium
                    text: "576"
                    color: Theme.highlightColor
                    inputMethodHints: Qt.ImhDigitsOnly
                    validator: IntValidator { bottom: 0; top: 9999 }
                    EnterKey.onClicked: {
                        if (idToolsCollageTargetHeight.text.length < 1  || idToolsCollageTargetHeight.text === "" ) {
                            idToolsCollageTargetHeight.text = "576"
                        }
                        idToolsCollageTargetHeight.focus = false
                    }
                    Label {
                        anchors.top: parent.bottom
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        text: qsTr("px-height")
                    }
                }
            }
            Separator {
                width: parent.width
                visible: (idButtonCollage.down && ( idButtonCollageSlideshow.down || idButtonCollageStoryline.down ) )
                horizontalAlignment: Qt.AlignHCenter
                color: Theme.primaryColor
            }
            Row {
                id: idToolsRowCollage2TransitionDuration
                visible: (idButtonCollage.down && ( idButtonCollageSlideshow.down || idButtonCollageStoryline.down ) )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                ValueButton {
                    visible: idButtonCollageSlideshow.down
                    width: parent.width / 6 * 1.5
                    enabled: ( finishedLoading === true )
                    height: standardDetailItemHeight
                    value: (slideshowAddFileLoaded === false ) ? qsTr("[none]"): ( slideshowAddFileName )
                    description: qsTr("image")
                    onClicked: { pageStack.push(slideshowImagePicker) }
                }
                ValueButton {
                    visible: idButtonCollageStoryline.down
                    width: parent.width / 6 * 3
                    enabled: ( finishedLoading === true )
                    height: standardDetailItemHeight
                    value: (storylineAddFileLoaded === false ) ? qsTr("[none]"): ( storylineAddFileName )
                    description: qsTr("video")
                    onClicked: { pageStack.push(storylineVideoPicker) }
                }
                TextField {
                    id: idToolsCollageImageDuration
                    visible: idButtonCollageSlideshow.down
                    width: parent.width / 6 * 1.5
                    height: Theme.itemSizeMedium
                    textTopMargin: Theme.paddingMedium
                    text: "5"
                    color: Theme.highlightColor
                    inputMethodHints: Qt.ImhDigitsOnly
                    validator: IntValidator { bottom: 1; top: 9999 }
                    EnterKey.onClicked: {
                        if (idToolsCollageImageDuration.text.length < 1 || idToolsCollageImageDuration.text < 1 ) {
                            idToolsCollageImageDuration.text = "5"
                        }
                        idToolsCollageImageDuration.focus = false
                    }
                    onFocusChanged: {
                        if (idToolsCollageImageDuration.focus === false) {
                            if (idToolsCollageImageDuration.text.length < 1 || idToolsCollageImageDuration.text < 1 ) {
                                idToolsCollageImageDuration.text = "1"
                            }
                        }
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
                        text: qsTr("duration")
                    }
                }
                ComboBox {
                    id: idComboBoxCollageStoryTransition
                    width: parent.width / 6 * 1.5
                    description:  qsTr("transition")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("none") } // use any other, e.g. fade, but set transition-duration to 0 seconds
                        MenuItem { text: qsTr("fade") }

                        MenuItem { text: qsTr("fade-black") }
                        MenuItem { text: qsTr("fade-white") }
                        //MenuItem { text: qsTr("fade-gray") }
                        MenuItem { text: qsTr("distance") }

                        MenuItem { text: qsTr("wipe-left") }
                        MenuItem { text: qsTr("wipe-right") }
                        MenuItem { text: qsTr("wipe-up") }
                        MenuItem { text: qsTr("wipe-down") }

                        MenuItem { text: qsTr("slide-left") }
                        MenuItem { text: qsTr("slide-right") }
                        MenuItem { text: qsTr("slide-up") }
                        MenuItem { text: qsTr("slide-down") }

                        MenuItem { text: qsTr("smooth-left") }
                        MenuItem { text: qsTr("smooth-right") }
                        MenuItem { text: qsTr("smooth-up") }
                        MenuItem { text: qsTr("smooth-down") }

                        MenuItem { text: qsTr("rect-crop") }
                        MenuItem { text: qsTr("circle-crop") }
                        MenuItem { text: qsTr("circle-close") }
                        MenuItem { text: qsTr("circle-open") }

                        MenuItem { text: qsTr("horizontal-close") }
                        MenuItem { text: qsTr("horizontal-open") }
                        MenuItem { text: qsTr("vertical-close") }
                        MenuItem { text: qsTr("vertical-open") }

                        MenuItem { text: qsTr("diagonal-down-left") }
                        MenuItem { text: qsTr("diagonal-down-right") }
                        MenuItem { text: qsTr("diagonal-up-left") }
                        MenuItem { text: qsTr("diagonal-uo-right") }

                        MenuItem { text: qsTr("slice left") }
                        MenuItem { text: qsTr("slice right") }
                        MenuItem { text: qsTr("slice up") }
                        MenuItem { text: qsTr("slice down") }

                        MenuItem { text: qsTr("dissolve") }
                        MenuItem { text: qsTr("pixelize") }
                        MenuItem { text: qsTr("radial") }
                        /*
                        MenuItem { text: qsTr("horizontal blur") }

                        MenuItem { text: qsTr("wipe-up-left") }
                        MenuItem { text: qsTr("wipe-up-right") }
                        MenuItem { text: qsTr("wipe-down-left") }
                        MenuItem { text: qsTr("wipe-down-right") }
                        */
                        MenuItem { text: qsTr("squeeze-horizontal") }
                        MenuItem { text: qsTr("squeeze-vertical") }
                        //MenuItem { text: qsTr("diagonal") }
                    }
                }
                TextField {
                    id: idToolsCollageImageTransitionDuration
                    enabled: idComboBoxCollageStoryTransition.currentIndex !== 0
                    width: parent.width / 6 * 1.5
                    height: Theme.itemSizeMedium
                    textTopMargin: Theme.paddingMedium
                    text: "1"
                    color: (idComboBoxCollageStoryTransition.currentIndex !== 0) ? Theme.highlightColor : "transparent"
                    inputMethodHints: Qt.ImhDigitsOnly
                    validator: IntValidator { bottom: 1; top: (idButtonCollageSlideshow.down) ? (parseInt(idToolsCollageImageDuration.text)) : (Math.round(storylineAddFileDuration)) }
                    EnterKey.onClicked: {
                        if (idToolsCollageImageTransitionDuration.text.length < 1 || idToolsCollageImageTransitionDuration.text < 1 ) {
                            idToolsCollageImageTransitionDuration.text = "1"
                        }
                        idToolsCollageImageTransitionDuration.focus = false
                    }
                    onFocusChanged: {
                        if (idToolsCollageImageTransitionDuration.focus === false) {
                            if (idToolsCollageImageTransitionDuration.text.length < 1 || idToolsCollageImageTransitionDuration.text < 1 ) {
                                idToolsCollageImageTransitionDuration.text = "1"
                            }
                        }
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
                        text: qsTr("transition")
                    }
                }
            }
            Row {
                id: idToolsRowCollage3AddButton
                visible: (idButtonCollage.down && (idButtonCollageSlideshow.down || idButtonCollageStoryline.down) )
                x: spacerLandscapeLowerToolRow
                topPadding: -Theme.paddingMedium
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                Item {
                    width: parent.width / 6 * 2
                    height: standardDetailItemHeight
                }
                IconButton {
                    width: parent.width / 6 * 2
                    height: standardDetailItemHeight * 1.3
                    enabled: ( ( (idButtonCollageSlideshow.down && slideshowAddFileLoaded === true) || ( idButtonCollageStoryline.down && storylineAddFileLoaded === true) ) && idToolsCollageImageDuration.focus === false && idToolsCollageImageTransitionDuration.focus === false )
                    icon.source: "image://theme/icon-m-add?"
                    icon.width: Theme.iconSizeMedium * 1.35
                    icon.height: icon.width
                    onClicked: {
                        idToolsCollageImageDuration.focus = false
                        idToolsCollageImageTransitionDuration.focus = false
                        if ( idButtonCollageSlideshow.down ) { var targetModel = "slideshow" }
                        else if ( idButtonCollageStoryline.down ) { targetModel = "storyline" }
                        prepareCollageModel( targetModel )
                    }
                }
                Item {
                    width: parent.width / 6 * 2
                    height: standardDetailItemHeight
                }
            }
            Row {
                id: idToolsRowCollage4Slideshow
                visible: (idButtonCollage.down && idButtonCollageSlideshow.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: 1 // standardDetailItemHeight
                }
                Rectangle {
                    id: mainContent
                    width: parent.width
                    visible: slideshowModel.count > 0
                    height: ( oldSlideshowHeight > listView.contentHeight ) ? oldSlideshowHeight : listView.contentHeight
                    color: Theme.rgba(Theme.primaryColor, 0.1)

                    ListView {
                        id: listView
                        anchors.fill: parent
                        model: slideshowModel
                        onCountChanged: {
                            // on loading this is calculatet once, when items added and removed recalculate
                            idTimerRecalculateSlideshowListHeight.start() //oldSlideshowHeight = contentHeight -> too quick, so needs a few ms
                        }
                        delegate: DraggableItem {
                            draggedItemParent: mainContent
                            onMoveItemRequested: { slideshowModel.move(from, to, 1) }

                            Item {
                                height: textLabel.height * 2
                                width: listView.width

                                Row {
                                    width: parent.width
                                    height: parent.height

                                    IconButton {
                                        // Patch: IconButtons overlay mouse area and prevent accidential re-ordering
                                        width: parent.width / 6
                                        height: parent.height
                                        Label {
                                            anchors.centerIn: parent
                                            font.pixelSize: Theme.fontSizeExtraSmall
                                            color: Theme.primaryColor
                                            text: (model.index + 1)
                                        }
                                    }
                                    Label {
                                        id: textLabel
                                        width: parent.width / 6 * 2.5 //3.25
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: model.file
                                        font.pixelSize: Theme.fontSizeExtraSmall
                                        truncationMode: TruncationMode.Elide
                                        color: Theme.primaryColor
                                    }
                                    Label {
                                        width: parent.width / 6 * 0.75
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: model.transition
                                        font.pixelSize: Theme.fontSizeExtraSmall
                                        truncationMode: TruncationMode.Elide
                                        color: Theme.primaryColor
                                    }
                                    IconButton {
                                        // Patch: IconButtons overlay mouse area and prevent accidential re-ordering
                                        width: parent.width / 6 * 0.75
                                        height: parent.height
                                        Label {
                                            width: parent.width
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: (model.transition !== "none") ? (model.duration + "+" + model.transitionDuration + "s") : (model.duration + "s")
                                            font.pixelSize: Theme.fontSizeExtraSmall
                                            horizontalAlignment: Text.AlignRight
                                            truncationMode: TruncationMode.Elide
                                            color: Theme.primaryColor
                                        }
                                    }
                                    IconButton {
                                        width: parent.width / 6
                                        height: parent.height
                                        icon.source: "image://theme/icon-cover-cancel?" // "image://theme/icon-s-decline?" //
                                        onClicked: {
                                            slideshowModel.remove(model.index)
                                        }
                                    }
                                }
                            }
                        } // end dragable
                    } // end listView
                } // end rectangle
            }
            Row {
                id: idToolsRowCollage4Storyline
                visible: (idButtonCollage.down && idButtonCollageStoryline.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: 1 // standardDetailItemHeight
                }
                Rectangle {
                    id: mainContent2
                    width: parent.width
                    visible: storylineModel.count > 0
                    height: ( oldStorylineHeight > listView2.contentHeight ) ? oldStorylineHeight : listView2.contentHeight
                    color: Theme.rgba(Theme.primaryColor, 0.1)

                    ListView {
                        id: listView2
                        anchors.fill: parent
                        model: storylineModel
                        onCountChanged: {
                            // on loading this is calculatet once, when items added and removed recalculate
                            idTimerRecalculateStorylineListHeight.start() //oldStorylineHeight = contentHeight -> too quick, so needs a few ms
                        }
                        delegate: DraggableItem {
                            draggedItemParent: mainContent2
                            onMoveItemRequested: { storylineModel.move(from, to, 1) }

                            Item {
                                height: textLabel2.height * 2
                                width: listView2.width

                                Row {
                                    width: parent.width
                                    height: parent.height

                                    IconButton {
                                        // Patch: IconButtons overlay mouse area and prevent accidential re-ordering
                                        width: parent.width / 10 * 1
                                        height: parent.height
                                        Label {
                                            anchors.centerIn: parent
                                            font.pixelSize: Theme.fontSizeExtraSmall
                                            color: Theme.primaryColor
                                            text: (model.index + 1)
                                        }
                                    }
                                    Label {
                                        id: textLabel2
                                        width: parent.width / 10 * 4
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: model.file
                                        font.pixelSize: Theme.fontSizeExtraSmall
                                        truncationMode: TruncationMode.Elide
                                        color: Theme.primaryColor
                                    }
                                    Label {
                                        width: parent.width / 10 * 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: model.transition
                                        font.pixelSize: Theme.fontSizeExtraSmall
                                        truncationMode: TruncationMode.Elide
                                        color: Theme.primaryColor
                                    }
                                    IconButton {
                                        // Patch: IconButtons overlay mouse area and prevent accidential re-ordering
                                        width: parent.width / 10 * 2
                                        height: parent.height
                                        Label {
                                            width: parent.width
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: (model.transition !== "none") ? (model.duration + "+" + model.transitionDuration + "s") : (model.duration + "s")
                                            font.pixelSize: Theme.fontSizeExtraSmall
                                            horizontalAlignment: Text.AlignRight
                                            truncationMode: TruncationMode.Elide
                                            color: Theme.primaryColor
                                        }
                                    }
                                    IconButton {
                                        width: parent.width / 10 * 1
                                        height: parent.height
                                        icon.source: "image://theme/icon-cover-cancel?" // "image://theme/icon-s-decline?" //
                                        onClicked: {
                                            storylineModel.remove(model.index)
                                        }
                                    }
                                }
                            }
                        } // end dragable
                    } // end listView
                } // end rectangle
            }

            Row {
                id: idToolsRowCollageSubtitles
                visible: (idButtonCollage.down && idButtonCollageSubtitle.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                ComboBox {
                    id: idComboBoxCollageSubtitleAdd
                    width: parent.width / 6 * 2
                    description:  qsTr("add data")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("from file") }
                        MenuItem { text: qsTr("manual") }
                    }
                }
                ValueButton {
                    width: parent.width / 6 * 2
                    visible: idComboBoxCollageSubtitleAdd.currentIndex === 0
                    enabled: ( noFile === false && finishedLoading === true )
                    height: standardDetailItemHeight
                    value: (addSubtitleLoaded === false) ? qsTr("[none]"): ( addSubtitleName )
                    description: qsTr("file")
                    onClicked: {
                        pageStack.push( addFilePickerPageSubtitle  )
                    }
                }
                ValueButton {
                    width: parent.width / 6 * 2
                    visible: idComboBoxCollageSubtitleAdd.currentIndex === 1
                    enabled: ( noFile === false && finishedLoading === true )
                    height: standardDetailItemHeight
                    value: qsTr("markers")
                    valueColor: Theme.primaryColor
                    description: qsTr("timestamp")
                }
                ComboBox {
                    id: idComboBoxCollageSubtitleMethod
                    width: parent.width / 6 * 2
                    description:  qsTr("method")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("burn-in") }
                        MenuItem { text: qsTr("selectable") }
                    }
                }
            }
            Row {
                id: idToolsRowCollageSubtitlesInput
                visible: (idButtonCollage.down && idButtonCollageSubtitle.down && idComboBoxCollageSubtitleAdd.currentIndex === 1)
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                Item {
                    width: parent.width / 6 * 4.5
                    height: parent.height

                    TextField {
                        id: idSubtitleTextInput
                        width: parent.width
                        textTopMargin: Theme.paddingLarge
                        inputMethodHints: Qt.ImhNoPredictiveText
                        font.pixelSize: Theme.fontSizeExtraSmall
                        placeholderText: qsTr("type here ...")
                        validator: RegExpValidator { regExp: /^[^<>'\"/;*:`#?]*$/ } // negative list
                        EnterKey.onClicked: {
                            //idSilicaFlickable.scrollToTop()
                            idSubtitleTextInput.focus = false
                        }
                    }
                }
                IconButton {
                    width: parent.width / 6 * 2
                    //height: standardDetailItemHeight
                    enabled: ( noFile === false && finishedLoading === true )
                    icon.source: "image://theme/icon-m-add?"
                    icon.width: Theme.iconSizeMedium * 1.15
                    icon.height: icon.width
                    onClicked: {
                        prepareSubtitleModel()
                        idTimerScrollToBottom.start()
                    }
                }
            }
            Row {
                id: idToolsRowCollageSubtitlesOutput
                visible: (idButtonCollage.down && idButtonCollageSubtitle.down && idComboBoxCollageSubtitleAdd.currentIndex === 1)
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                Rectangle {
                    id: mainContent3
                    width: parent.width
                    visible: subtitleModel.count > 0
                    height: ( oldSubtitleHeight > listView3.contentHeight ) ? oldSubtitleHeight : listView3.contentHeight
                    color: Theme.rgba(Theme.primaryColor, 0.1)

                    ListView {
                        id: listView3
                        anchors.fill: parent
                        model: subtitleModel
                        onCountChanged: {
                            // on loading this is calculatet once, when items added and removed recalculate
                            idTimerRecalculateSubtitleListHeight.start() //oldSlideshowHeight = contentHeight -> too quick, so needs a few ms
                        }
                        delegate: DraggableItem {
                            draggedItemParent: mainContent3
                            onMoveItemRequested: { subtitleModel.move(from, to, 1) }

                            Item {
                                height: textLabel3.height + Theme.paddingMedium
                                width: listView3.width

                                Row {
                                    width: parent.width
                                    height: parent.height

                                    IconButton {
                                        // Patch: IconButtons overlay mouse area and prevent accidential re-ordering
                                        width: parent.width / 6
                                        height: parent.height
                                        Label {
                                            anchors.centerIn: parent
                                            font.pixelSize: Theme.fontSizeExtraSmall
                                            color: Theme.primaryColor
                                            text: (model.index + 1)
                                        }
                                    }
                                    Label {
                                        id: textLabel3
                                        width: parent.width / 6 * 4
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: model.timestamp + "\n" + model.text
                                        font.pixelSize: Theme.fontSizeExtraSmall
                                        wrapMode: TextEdit.Wrap
                                        color: Theme.primaryColor
                                    }
                                    IconButton {
                                        width: parent.width / 6
                                        height: parent.height
                                        icon.source: "image://theme/icon-cover-cancel?" // "image://theme/icon-s-decline?" //
                                        onClicked: {
                                            subtitleModel.remove(model.index)
                                        }
                                    }
                                }
                            }
                        } // end dragable
                    }

                    /*
                    SilicaListView {
                        id: listView3
                        height: contentHeight
                        anchors.fill: parent
                        model: subtitleModel
                        delegate: Item {
                            width: parent.width
                            height: testLabel.height

                            Row {
                                width: parent.width
                                height: parent.height

                                Label {
                                    id: testLabel
                                    width: parent.width / 6 * 5
                                    leftPadding: Theme.paddingLarge + Theme.paddingSmall
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    wrapMode: TextEdit.Wrap
                                    color: Theme.primaryColor
                                    text: (model.index + 1) + "\n" + model.timestamp + "\n" + model.text
                                }
                                IconButton {
                                    width: parent.width / 6
                                    height: parent.height / 4 * 3
                                    icon.source: "image://theme/icon-cover-cancel?"
                                    onClicked: {
                                        subtitleModel.remove(model.index)
                                    }
                                }
                            } // end row
                        }

                    }
                    */
                }
            }

            Row {
                id: idToolsRowCollageImageExtract
                visible: (idButtonCollage.down && idButtonCollageImageExtract.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                ComboBox {
                    id: idComboBoxCollageImageExtract
                    width: ( currentIndex !== 0 ) ? parent.width : (parent.width / 6 * 2)
                    description: ( currentIndex !== 2 ) ? qsTr("full clip") : qsTr("at cursor")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("interval") }
                        MenuItem { text: qsTr("i-frames") }
                        MenuItem { text: qsTr("image") }
                    }
                }
                Slider {
                    id: idToolsRowCollageImageExtractIntervall
                    visible: ( idComboBoxCollageImageExtract.currentIndex === 0 )
                    width: parent.width / 6 * 4
                    leftMargin: Theme.paddingMedium * 1.1
                    rightMargin: leftMargin
                    minimumValue: 1
                    maximumValue: 60
                    value: 5
                    stepSize: 1
                    handleVisible: false
                    color: Theme.primaryColor

                    Label {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -Theme.paddingSmall / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor //highlightColor
                        text: idToolsRowCollageImageExtractIntervall.value + " " + qsTr("sec")
                    }
                }
            }

            // more details FILE
            Item {
                id: idToolsRowFileShare
                visible: (idButtonFile.down && idButtonFileShare.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow
                height: idFileShareColumn.height

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                Column {
                    id: idFileShareColumn
                    width: parent.width
                    DetailItem {
                        label: qsTr("CURRENT FILE")
                        value:  ( idMediaPlayer.source.toString().length <=0 ) ? "none" : ( "/" + idMediaPlayer.source.toString().replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2}|)/,"") )
                    }
                    DetailItem {
                        label: qsTr("size")
                        value: tmpVideoFileSize+ " MB"
                    }
                    DetailItem {
                        label: qsTr("duration")
                        value: new Date(idMediaPlayer.duration).toISOString().substr(11,8)
                    }
                }
            }
            Item {
                id: idToolsRowFileInfo
                visible: (idButtonFile.down && idButtonFileInfo.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow
                height: idFileInfoColumn.height

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                Column {
                    id: idFileInfoColumn
                    width: parent.width
                    DetailItem {
                        label: qsTr("SOURCE FILE")
                        value: origMediaFileName
                    }
                    DetailItem {
                        label: qsTr("size")
                        value: origFileSize+ " MB"
                    }
                    DetailItem {
                        label: qsTr("duration")
                        value: origVideoDuration
                    }
                    DetailItem {
                        label: qsTr("container")
                        value: origMediaType
                    }
                    DetailItem {
                        label: qsTr("width")
                        value: origVideoWidth
                    }
                    DetailItem {
                        label: qsTr("height")
                        value: origVideoHeight
                    }
                    DetailItem {
                        label: qsTr("display-ratio")
                        value: origDAR
                    }
                    DetailItem {
                        label: qsTr("pixel-ratio")
                        value: origSAR
                    }
                    DetailItem {
                        label: qsTr("rotation")
                        value: origVideoRotation
                    }
                    DetailItem {
                        label: qsTr("frames/s")
                        value: origFrameRate
                    }
                    DetailItem {
                        label: qsTr("video-codec")
                        value: origCodecVideo
                    }
                    DetailItem {
                        label: qsTr("pixel-format")
                        value: origPixelFormat
                    }
                    DetailItem {
                        label: qsTr("audio-codec")
                        value: origCodecAudio
                    }
                    DetailItem {
                        label: qsTr("samplerate")
                        value: origAudioSamplerate + " Hz"
                    }
                    DetailItem {
                        label: qsTr("layout")
                        value: origAudioLayout
                    }
                }
            }
            Row {
                id: idToolsRowFileRename
                visible: (idButtonFile.down && idButtonFileRename.down )
                x: spacerLandscapeLowerToolRow
                width: idToolsCategoriesRow.width - 2 * spacerLandscapeLowerToolRow
                height: idToolsRowFileRenameText.height

                Item {
                    width: idToolsCategoriesRow.x
                    height: standardDetailItemHeight
                }
                Item {
                    width: parent.width / 5 * 4
                    height: parent.height //standardDetailItemHeight

                    TextField {
                        id: idToolsRowFileRenameText
                        enabled: ( finishedLoading === true )
                        visible: ( idButtonFile.down && idButtonFileRename.down )
                        width: parent.width
                        textTopMargin: Theme.paddingLarge
                        inputMethodHints: Qt.ImhNoPredictiveText
                        font.pixelSize: Theme.fontSizeExtraSmall
                        text: origMediaName
                        validator: RegExpValidator { regExp: /^[^<>'\"/;*:`#?]*$/ } // negative list
                        EnterKey.onClicked: {
                            if (idToolsRowFileRenameText.text < 1 || idToolsRowFileRenameText.text === "") {
                                idToolsRowFileRenameText.text = origMediaName
                            }
                            idToolsRowFileRenameText.focus = false
                        }
                        Label {
                            anchors.top: parent.bottom
                            anchors.topMargin: Theme.paddingSmall
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryColor
                            text: qsTr("new filename")
                        }
                    }
                }
                Item {
                    width: parent.width / 5
                    height: parent.height

                    Label {
                        width: parent.width
                        color: Theme.highlightColor
                        anchors.bottom: parent.verticalCenter
                        horizontalAlignment: Text.AlignHCenter
                        truncationMode: TruncationMode.Elide
                        font.pixelSize: Theme.fontSizeExtraSmall
                        text: "." + origMediaType
                    }
                }
            }
            Item {
                visible: (idButtonFile.down && idButtonFileDelete.down )
                width: parent.width
                height: standardDetailItemHeight
            }


            Item {
                id: idSpacerBottom
                width: parent.width
                height: Theme.paddingLarge
            }




        } // end column
    } // end flickable







// *********************************************** useful functions *********************************************** //

    function openWithPath() {
        // only apply if app is opened with file
        if (openingArguments.length === 2) {
            idMediaPlayer.stop()
            origMediaFilePath = (openingArguments[1])
            var origMediaPathArray = (origMediaFilePath.toString()).split("/")
            origMediaFileName = (origMediaPathArray[origMediaPathArray.length - 1])
            origMediaFolderPath = (origMediaFilePath.replace(origMediaFileName, ""))
            var origMediaFileNameArray = origMediaFileName.split(".")
            origMediaName = (origMediaFileNameArray.slice(0, origMediaFileNameArray.length-1)).join(".")
            origMediaType = origMediaFileNameArray[origMediaFileNameArray.length - 1]
            idMediaPlayer.source = ""
            idMediaPlayer.source = encodeURI(origMediaFilePath)
            py.deleteAllTMPFunction()
            py.getVideoInfo( inputPathPy, "true" )
            undoNr = 0
            noFile = false
            //finishedLoading = false
        }
    }

    function checkThemechangeAdjustMarkerPadding() {
        // Patch: sliderwidth makes a different
        if ((Theme.primaryColor).toString() === "#ffffff" ) { // -> white font on dark themes, slider is wider as of SF 3.4
            addThemeSliderPaddingSides = 0
        }
        else { // "#000000" -> black font on light themes, slider is smaller as of SF 3.4
            addThemeSliderPaddingSides = Theme.paddingMedium
        }
    }

    function preparePathAndUndo() {
        idMediaPlayer.stop()
        finishedLoading = false
        undoNr = undoNr + 1
        outputPathPy = tempMediaFolderPath + "video" + ".tmp" + undoNr + "." + tempMediaType
        console.debug("pyPath: "+ outputPathPy)
    }

    function undoBackwards() {
        idMediaPlayer.stop()
        finishedLoading = false
        brandNewFile = false // Patch: size warning banner will not show again when going backwards to original image
        undoNr = undoNr - 1
        lastTmpMedia2delete = decodeURIComponent( "/" + idMediaPlayer.source.toString().replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"") )
        if (undoNr <= 0) {
            undoNr = 0
            idMediaPlayer.source = encodeURI(origMediaFilePath)
        }
        else {
            idMediaPlayer.source = idMediaPlayer.source.toString().replace(".tmp"+(undoNr+1), ".tmp"+(undoNr))
        }
        py.deleteLastTMPFunction()
        py.getVideoInfo(decodeURIComponent( "/" + idMediaPlayer.source.toString().replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"") ), "false" )
    }

    function setCropmarkersRatio() {
        rectDrag1.x = 0
        rectDrag1.y = 0
        idItemCropzoneHandles.width = parent.width
        idItemCropzoneHandles.height = parent.height
        // check how the cropping zone in the image, to define which value touches the border first: x or y?
        if ( croppingRatio <= (idMediaPlayer.width / idMediaPlayer.height) ) {
            rectDrag2.y = idItemCropzoneHandles.height - handleWidth
            // Patch: takes into account handle disposition
            var correctionFactorY = handleWidth - (handleWidth * croppingRatio)
            rectDrag2.x = rectDrag2.y * croppingRatio - correctionFactorY
        }
        else {
            rectDrag2.x = idItemCropzoneHandles.width - handleWidth
            // Patch: takes into account handle disposition
            var correctionFactorX = handleWidth - (handleWidth / croppingRatio)
            rectDrag2.y = rectDrag2.x / croppingRatio - correctionFactorX
        }
        // place cropping zone in vertical center
        var diffMarkerRatiosY = (idItemCropzoneHandles.height - (rectDrag2.y + rectDrag2.height))
        if ((rectDrag2.y + diffMarkerRatiosY/2) <= idItemCropzoneHandles.height) {
            rectDrag1.y = rectDrag1.y + diffMarkerRatiosY/2
            rectDrag2.y = rectDrag2.y + diffMarkerRatiosY/2
        }
        else {
            rectDrag1.x = 0
            rectDrag1.y = 0
            rectDrag2.y = idItemCropzoneHandles.height - handleWidth
            rectDrag2.x = rectDrag2.y * croppingRatio
            var diffMarkerRatiosX2 = (idItemCropzoneHandles.width - (rectDrag2.x + rectDrag2.width))
            rectDrag1.x = rectDrag1.x + diffMarkerRatiosX2/2
            rectDrag2.x = rectDrag2.x + diffMarkerRatiosX2/2
        }
        // place cropping zone in horizontal center
        var diffMarkerRatiosX = (idItemCropzoneHandles.width - (rectDrag2.x + rectDrag2.width))
        if ((rectDrag1.x + diffMarkerRatiosX/2) >= 0) {
            rectDrag1.x = rectDrag1.x + diffMarkerRatiosX/2
            rectDrag2.x = rectDrag2.x + diffMarkerRatiosX/2
        }
        else {
            rectDrag1.x = 0
            rectDrag1.y = 0
            rectDrag2.x = idItemCropzoneHandles.width - handleWidth
            rectDrag2.y = rectDrag2.x / croppingRatio
            var diffMarkerRatiosY1 = (idItemCropzoneHandles.height - (rectDrag2.y + rectDrag2.height))
            rectDrag1.y = rectDrag1.y + diffMarkerRatiosY1/2
            rectDrag2.y = rectDrag2.y + diffMarkerRatiosY1/2
        }

        // check here
        if (croppingRatio === 0) {
            if ( stretchOversizeActive === true ) {
                rectDrag1.x = parent.x - handleWidth/2
                rectDrag1.y = parent.y - handleWidth/2
                rectDrag2.x = idItemCropzoneHandles.width - handleWidth/2
                rectDrag2.y = idItemCropzoneHandles.height - handleWidth/2
            }
            else {
                rectDrag1.x = parent.x
                rectDrag1.y = parent.y
                rectDrag2.x = idItemCropzoneHandles.width - handleWidth
                rectDrag2.y = idItemCropzoneHandles.height - handleWidth
            }
        }
        // set text markers too
        rectDragText.x = idItemCropzoneHandles.width/2 - handleWidth/2
        rectDragText.y = idItemCropzoneHandles.height/2 - handleWidth/2
    }

    function generateCroppingPixelsFromHandles() {
        cropX = Math.min(rectDrag1.x, rectDrag2.x)
        cropY = Math.min(rectDrag1.y, rectDrag2.y)
        cropWidth = Math.max(rectDrag1.x+rectDrag1.width, rectDrag2.x+rectDrag2.width) - Math.min(rectDrag1.x, rectDrag2.x)
        cropHeight = Math.max(rectDrag1.y+rectDrag1.height, rectDrag2.y+rectDrag2.height) - Math.min(rectDrag1.y, rectDrag2.y)
    }

    function clearOverlayFunction() {
        croppingRatio = 0
        overlayFilePath = ""
        overlayFileName = ""
        overlayFileNamePure = ""
        idPreviewOverlayImage.source = ""
        overlayFileLoaded = false
    }

    function prepareCollageModel( targetModel) {
        if (idComboBoxCollageStoryTransition.currentIndex === 0) { var transitionType = "none" } // use any one but set transition-duration to zero
        else if (idComboBoxCollageStoryTransition.currentIndex === 1) { transitionType = "fade" }

        else if (idComboBoxCollageStoryTransition.currentIndex === 2) { transitionType = "fadeblack" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 3) { transitionType = "fadewhite" }
        //else if (idComboBoxCollageStoryTransition.currentIndex === 4) { transitionType = "fadegrays" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 4) { transitionType = "distance" }

        else if (idComboBoxCollageStoryTransition.currentIndex === 5) { transitionType = "wipeleft" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 6) { transitionType = "wiperight" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 7) { transitionType = "wipeup" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 8) { transitionType = "wipedown" }

        else if (idComboBoxCollageStoryTransition.currentIndex === 9) { transitionType = "slideleft" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 10) { transitionType = "slideright" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 11) { transitionType = "slideup" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 12) { transitionType = "slidedown" }

        else if (idComboBoxCollageStoryTransition.currentIndex === 13) { transitionType = "smoothleft" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 14) { transitionType = "smoothtight" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 15) { transitionType = "smoothup" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 16) { transitionType = "smoothdown" }

        else if (idComboBoxCollageStoryTransition.currentIndex === 17) { transitionType = "rectcrop" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 18) { transitionType = "circlecrop" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 19) { transitionType = "circleclose" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 20) { transitionType = "circleopen" }

        else if (idComboBoxCollageStoryTransition.currentIndex === 21) { transitionType = "horzclose" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 22) { transitionType = "horzopen" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 23) { transitionType = "vertclose" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 24) { transitionType = "vertopen" }

        else if (idComboBoxCollageStoryTransition.currentIndex === 25) { transitionType = "diagbl" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 26) { transitionType = "diagbr" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 27) { transitionType = "diagtl" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 28) { transitionType = "diagtr" }

        else if (idComboBoxCollageStoryTransition.currentIndex === 29) { transitionType = "hlslice" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 30) { transitionType = "hrslice" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 31) { transitionType = "vuslice" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 32) { transitionType = "vdslice" }

        else if (idComboBoxCollageStoryTransition.currentIndex === 33) { transitionType = "dissolve" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 34) { transitionType = "pixelize" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 35) { transitionType = "radial" }
        /*
        else if (idComboBoxCollageStoryTransition.currentIndex === 37) { transitionType = "hblur" }

        else if (idComboBoxCollageStoryTransition.currentIndex === 38) { transitionType = "wipetl" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 39) { transitionType = "wipetr" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 40) { transitionType = "wipebl" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 41) { transitionType = "wipebr" }
        */
        else if (idComboBoxCollageStoryTransition.currentIndex === 36) { transitionType = "squeezev" }
        else if (idComboBoxCollageStoryTransition.currentIndex === 37) { transitionType = "squeezeh" }

        if ( targetModel === "slideshow" ) {
            slideshowModel.append({
                file: slideshowAddFileName,
                path: slideshowAddFilePath.toString().replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,""),
                duration: ( idToolsCollageImageDuration.text === "0" ) ? "1" : idToolsCollageImageDuration.text,
                transition: transitionType,
                transitionDuration : (idComboBoxCollageStoryTransition.currentIndex === 0) ? "0" : (idToolsCollageImageTransitionDuration.text) // in case of "no transition, just use a duration of 0 sec
            })
        }
        else if ( targetModel === "storyline" ) {
            storylineModel.append({
                file: storylineAddFileName,
                path: storylineAddFilePath.toString().replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,""),
                duration: storylineAddFileDuration,
                transition: transitionType,
                transitionDuration : (idComboBoxCollageStoryTransition.currentIndex === 0) ? "0" : (idToolsCollageImageTransitionDuration.text) // in case of "no transition, just use a duration of 0 sec
            })
        }
        idTimerScrollToBottom.start()
    }

    function prepareSubtitleModel( targetModel) {
        idSubtitleTextInput.focus = false
        subtitleModel.append({
            timestamp: ( fromTimestampPy + " --> " + toTimestampPy ).replace(".", ",").replace(".", ","),
            text: idSubtitleTextInput.text
        })
    }
}
