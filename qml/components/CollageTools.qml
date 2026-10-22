import QtQuick 2.6
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
import io.thp.pyotherside 1.5
Item {
    Component.onCompleted:  {
        console.debug(mainToolbar.width)
        console.debug(collageToolbar.buttonStoryline.selected)
    }
    function hello() {
        py.createSlideshowFunction()
    }

    // Python
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
        else if (idComboBoxCollageStoryTransition.currentIndex === 14) { transitionType = "smoothright" }
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

    Row {
        id: idToolsRowCollage1
        visible: (mainToolbar.buttonCollage.selected && ( collageToolbar.buttonSlideshow.selected || collageToolbar.buttonStoryline.selected ) )
        x: spacerLandscapeLowerToolRow
        width: mainToolbar.width - 2 * spacerLandscapeLowerToolRow

        ValueButton {
            id: idComboBoxCollageStorylineEffect
            width: parent.width / 6 * 3
            height: standardDetailItemHeight
            value: qsTr("target resolution")
            valueColor: Theme.primaryColor
            description: qsTr("storyline keep low ")
        }
        TextField {
            id: idToolsCollageTargetWidth
            width: parent.width / 6 * 1.5
            height: Theme.itemSizeMedium
            textTopMargin: Theme.paddingMedium
            text: "960"
            color: Theme.highlightColor
            inputMethodHints: Qt.ImhDigitsOnly
            validator: IntValidator { bottom: 0; top: 9999 }
            EnterKey.onClicked: {
                if (idToolsCollageTargetWidth.text.length < 1  || idToolsCollageTargetWidth.text === "" ) {
                    idToolsCollageTargetWidth.text = "960"
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
            text: "540"
            color: Theme.highlightColor
            inputMethodHints: Qt.ImhDigitsOnly
            validator: IntValidator { bottom: 0; top: 9999 }
            EnterKey.onClicked: {
                if (idToolsCollageTargetHeight.text.length < 1  || idToolsCollageTargetHeight.text === "" ) {
                    idToolsCollageTargetHeight.text = "540"
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
    Row {
        id: idToolsRowCollage11
        visible:  (mainToolbar.buttonCollage.selected && collageToolbar.buttonSlideshow.selected )
        anchors.top: idToolsRowCollage1.bottom
        x: spacerLandscapeLowerToolRow
        width: mainToolbar.width - 2 * spacerLandscapeLowerToolRow

        ComboBox {
            id: idComboBoxCollageSlideshowEffect
            width: parent.width /  3
            description: (currentIndex === 0) ? qsTr("no camera movement") : qsTr("camera movement")
            menu: ContextMenu {
                MenuItem { text: qsTr("still images") }
                MenuItem { text: qsTr("random pan & zoom") }
            }
        }
        ValueButton {
            width: parent.width / 3
            enabled: ( finishedLoading === true )
            height: standardDetailItemHeight
            value: (slideshowAddFileLoaded === false ) ? qsTr("[none]"): ( slideshowAddFileName )
            description: qsTr("image")
            onClicked: { pageStack.push(slideshowImagePicker) }
        }
        TextField {
            id: idToolsCollageImageDuration
            width: parent.width / 3
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
    }

    Row {
        anchors.top: idToolsRowCollage11.bottom
        id: idToolsRowCollage2TransitionDuration
        visible: (mainToolbar.buttonCollage.selected && ( collageToolbar.buttonSlideshow.selected || collageToolbar.buttonStoryline.selected ) )
        x: spacerLandscapeLowerToolRow
        //width: mainToolbar.width //- 2 * spacerLandscapeLowerToolRow

        Item {
            width: mainToolbar.x
            height: standardDetailItemHeight
        }

        ValueButton {
            visible: collageToolbar.buttonStoryline.selected
            width: parent.width /3
            enabled: ( finishedLoading === true )
            height: standardDetailItemHeight
            value: (storylineAddFileLoaded === false ) ? qsTr("[none]"): ( storylineAddFileName )
            description: qsTr("video")
            onClicked: { pageStack.push(storylineVideoPicker) }
        }

        ComboBox {
            id: idComboBoxCollageStoryTransition
            width: parent.width / 3
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
            width: parent.width / 3
            height: Theme.itemSizeMedium
            textTopMargin: Theme.paddingMedium
            text: "1"
            color: (idComboBoxCollageStoryTransition.currentIndex !== 0) ? Theme.highlightColor : "transparent"
            inputMethodHints: Qt.ImhDigitsOnly
            validator: IntValidator { bottom: 1; top: (collageToolbar.buttonSlideshow.selected) ? (parseInt(idToolsCollageImageDuration.text)) : (Math.round(storylineAddFileDuration)) }
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

    Separator {
        id: sep
        anchors.top: idToolsRowCollage3AddButton.bottom
        width: mainToolbar.width
        visible: (mainToolbar.buttonCollage.selected && ( collageToolbar.buttonSlideshow.selected || collageToolbar.buttonStoryline.selected ) )
        horizontalAlignment: Qt.AlignHCenter
        color: Theme.primaryColor
    }

    Row {
        id: idToolsRowCollage3AddButton
        anchors.top: sep.bottom
        visible: (mainToolbar.buttonCollage.selected && (collageToolbar.buttonSlideshow.selected || collageToolbar.buttonStoryline.selected) )
        x: spacerLandscapeLowerToolRow
        topPadding: -Theme.paddingMedium
        width: mainToolbar.width - 2 * spacerLandscapeLowerToolRow

        Item {
            width: mainToolbar.x
            height: standardDetailItemHeight
        }
        Item {
            width: parent.width / 6 * 2
            height: standardDetailItemHeight
        }
        IconButton {
            width: parent.width / 6 * 2
            height: standardDetailItemHeight * 1.3
            enabled: ( ( (collageToolbar.buttonSlideshow.selected && slideshowAddFileLoaded === true) || ( collageToolbar.buttonStoryline.selected && storylineAddFileLoaded === true) ) && idToolsCollageImageDuration.focus === false && idToolsCollageImageTransitionDuration.focus === false )
            icon.source: "image://theme/icon-m-add?"
            icon.width: Theme.iconSizeMedium * 1.35
            icon.height: icon.width
            onClicked: {
                idToolsCollageImageDuration.focus = false
                idToolsCollageImageTransitionDuration.focus = false
                if ( collageToolbar.buttonSlideshow.selected ) { var targetModel = "slideshow" }
                else if ( collageToolbar.buttonStoryline.selected ) { targetModel = "storyline" }
                prepareCollageModel( targetModel )
            }
        }
        Item {
            width: parent.width / 6 * 2
            height: standardDetailItemHeight
        }
    }
    Row {
        anchors.top:idToolsRowCollage3AddButton.bottom
        id: idToolsRowCollage4Slideshow
        visible:  (mainToolbar.buttonCollage.selected && collageToolbar.buttonSlideshow.selected )
        x: spacerLandscapeLowerToolRow
        width: mainToolbar.width - 2 * spacerLandscapeLowerToolRow

        Item {
            width: mainToolbar.x
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
        anchors.top:idToolsRowCollage3AddButton.bottom
        id: idToolsRowCollage4Storyline
        visible: (mainToolbar.buttonCollage.selected && collageToolbar.buttonStoryline.selected )
        x: spacerLandscapeLowerToolRow
        width: mainToolbar.width - 2 * spacerLandscapeLowerToolRow

        Item {
            width: mainToolbar.x
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
        visible: (mainToolbar.buttonCollage.selected && collageToolbar.buttonSubtitles.selected )
        x: spacerLandscapeLowerToolRow
        width: mainToolbar.width - 2 * spacerLandscapeLowerToolRow

        Item {
            width: mainToolbar.x
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
        visible: (mainToolbar.buttonCollage.selected && collageToolbar.buttonSubtitles.selected && idComboBoxCollageSubtitleAdd.currentIndex === 1)
        x: spacerLandscapeLowerToolRow
        width: mainToolbar.width - 2 * spacerLandscapeLowerToolRow

        Item {
            width: mainToolbar.x
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
        visible: (mainToolbar.buttonCollage.selected && collageToolbar.buttonSubtitles.selected && idComboBoxCollageSubtitleAdd.currentIndex === 1)
        x: spacerLandscapeLowerToolRow
        width: mainToolbar.width - 2 * spacerLandscapeLowerToolRow

        Item {
            width: mainToolbar.x
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
        }
    }

    Row {
        id: idToolsRowCollageSplitscreen
        visible: (mainToolbar.buttonCollage.selected && collageToolbar.buttonSplitScreen.selected )
        x: spacerLandscapeLowerToolRow
        width: mainToolbar.width - 2 * spacerLandscapeLowerToolRow

        Item {
            width: mainToolbar.x
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
        id: idToolsRowCollageImageExtract
        visible: (mainToolbar.buttonCollage.selected && collageToolbar.buttonThumbnail.selected )
        x: spacerLandscapeLowerToolRow
        width: mainToolbar.width - 2 * spacerLandscapeLowerToolRow

        Item {
            width: mainToolbar.x
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

}
