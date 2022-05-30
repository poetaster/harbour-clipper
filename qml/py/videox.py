# -*- coding: utf-8 -*-

import pyotherside
import time
import os
import subprocess, signal
import random
from pathlib import Path

# other for progressbar
import re
#from collections.abc import Iterator
from typing import Iterator


# global variables
currentFunctionErrorName = ""
success = "false"

# Functions for file operations
# #######################################################################################

def getHomePath ():
    homeDir = str(Path.home())
    pyotherside.send('homePathFolder', homeDir )

def createTmpAndSaveFolder ( tempMediaFolderPath, saveAudioFolderPath ):
    if not os.path.exists( "/"+tempMediaFolderPath ):
        os.makedirs( "/"+tempMediaFolderPath )
        pyotherside.send('folderExistence', )
    if not os.path.exists( "/"+saveAudioFolderPath ):
        os.makedirs( "/"+saveAudioFolderPath )
        pyotherside.send('folderExistence', )

def deleteAllTMPFunction ( tempMediaFolderPath ):
    # pkill not allowed
    #subprocess.run([ "pkill", "-f", "ffmpeg" ])
    for i in os.listdir( "/"+tempMediaFolderPath ) :
        if (i.find(".tmp") != -1):
            os.remove ( "/"+tempMediaFolderPath+i )
            pyotherside.send('tempFilesDeleted', i )
        if (i.find(".png") != -1): # also delete last preview png
            os.remove ( "/"+tempMediaFolderPath+i )
            pyotherside.send('tempFilesDeleted', i )
        if (i.find(".trf") != -1): # also delete last vid.stab deshake filter analyzer file
            os.remove ( "/"+tempMediaFolderPath+i )
            pyotherside.send('tempFilesDeleted', i )
        if (i.find(".wav") != -1): # also delete last recordings
            os.remove ( "/"+tempMediaFolderPath+i )
            pyotherside.send('tempFilesDeleted', i )
        if (i.find(".srt") != -1): # also delete last manual subtitle file
            os.remove ( "/"+tempMediaFolderPath+i )
            pyotherside.send('tempFilesDeleted', i )

def deleteLastTmpFunction ( lastTmpMedia2delete ):
    if ".tmp" in lastTmpMedia2delete :
        os.remove ( lastTmpMedia2delete )
    pyotherside.send('deletedLastTmp', )

def deleteFile ( inputPathPy ):
    os.remove ( "/" + inputPathPy )
    pyotherside.send('deletedFile', )

def renameOriginal ( inputPathPy, newFilePath, newFileName, newFileType ) :
    os.rename( "/" + inputPathPy, "/" + newFilePath )
    pyotherside.send('finishedSavingRenaming', newFilePath, newFileName, newFileType)

def getVideoInfo ( inputPathPy, isOriginal, thumbnailPath, thumbnailSec ):
    if "true" in isOriginal:
        videoRotation = subprocess.check_output(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream_tags=rotate", "-of", "default=noprint_wrappers=1:nokey=1", "/"+inputPathPy ])
    else:
        videoRotation = 0
    videoResolution = subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "stream=width,height", "-of", "csv=p=0:s=x", inputPathPy ])
    playbackDuration = subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0:s=x", inputPathPy ])
    videoInfos = ( subprocess.check_output(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=codec_name,sample_aspect_ratio,display_aspect_ratio,pix_fmt,avg_frame_rate", "-of", "default=noprint_wrappers=1:nokey=1", inputPathPy ]) ).splitlines()
    videoCodec = videoInfos[0]
    sampleAspectRatio = videoInfos[1]
    displayAspectRatio = videoInfos[2]
    pixelFormat = videoInfos[3]
    frameRate = videoInfos[4]
    audioInfos = ( subprocess.check_output(["ffprobe", "-v", "error", "-select_streams", "a:0", "-show_entries", "stream=codec_name,sample_rate,channel_layout", "-of", "default=noprint_wrappers=1:nokey=1", inputPathPy ]) ).splitlines()
    try: #Patch: if there is audio track after all
        audioCodec = audioInfos[0]
    except:
        audioCodec = "none"
    try:
        audioSamplerate = audioInfos[1]
    except:
        audioSamplerate = "0"
    try:
        audioLayout = audioInfos[2]
    except:
        audioLayout = "none"
    estimatedSize = os.stat( "/" + inputPathPy ).st_size
    # generate thumbnail image
    subprocess.run([ "ffmpeg", "-hide_banner", "-y", "-ss", thumbnailSec, "-i", "/"+inputPathPy, "-frames:v", "1", "/"+thumbnailPath ], shell = False )
    pyotherside.send( 'previewImageCreated', )
    pyotherside.send( 'sourceVideoInfo', videoResolution, videoCodec, audioCodec, frameRate, pixelFormat, audioSamplerate, audioLayout, isOriginal, estimatedSize, videoRotation, playbackDuration, sampleAspectRatio, displayAspectRatio )

def getOverlayVideoInfo ( inputPathPy, thumbnailPath, thumbnailSec ):
    videoResolution = subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "stream=width,height", "-of", "csv=p=0:s=x", "/"+inputPathPy ])
    subprocess.run([ "ffmpeg", "-hide_banner", "-y", "-ss", thumbnailSec, "-i", "/"+inputPathPy, "-frames:v", "1", "/"+thumbnailPath ], shell = False )
    pyotherside.send( 'overlayVideoInfo', videoResolution )

def saveFile ( ffmpeg_staticPath, inputPathPy, savePath, tempMediaFolderPath, newFileName, newFileType, ignoreAllCodecs, newAudioCodec, newVideoCodec, newVideoFrameRate, needFrameChange ):
    if "true" in ignoreAllCodecs:
        #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "/"+savePath ])
        for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "/"+savePath ]):
            pyotherside.send('progressPercentageSave', progress)
    else:
        if "true" in needFrameChange:
            #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-c:v", newVideoCodec, "-c:a", newAudioCodec, "-r", newVideoFrameRate, "/"+savePath ])
            for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-c:v", newVideoCodec, "-c:a", newAudioCodec, "-r", newVideoFrameRate, "/"+savePath ]):
                pyotherside.send('progressPercentageSave', progress)
        else:
            #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-c:v", newVideoCodec, "-c:a", newAudioCodec, "/"+savePath ])
            for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-c:v", newVideoCodec, "-c:a", newAudioCodec, "/"+savePath ]):
                pyotherside.send('progressPercentageSave', progress)
    # clear tmp files
    for i in os.listdir( "/" + tempMediaFolderPath ) :
        if (i.find(".tmp") != -1):
            os.remove ("/" + tempMediaFolderPath+i)
            pyotherside.send('tempFilesDeleted', i )
    if "true" in success :
        pyotherside.send('fileIsSaved', "@SavePage" )
        pyotherside.send('finishedSavingRenaming', savePath, newFileName, newFileType)

def createPreviewImage ( inputPathPy, thumbnailPath, thumbnailSec ):
    subprocess.run([ "ffmpeg", "-hide_banner", "-y", "-ss", thumbnailSec, "-i", "/"+inputPathPy, "-frames:v", "1", "/"+thumbnailPath ], shell = False )
    pyotherside.send( 'previewImageCreated', )

def getPlaybackDuration ( inputPathPy, targetName ):
    playbackDuration = subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0:s=x", inputPathPy ])
    pyotherside.send( 'playbackDurationParsed', playbackDuration, targetName)






# TRIM FUNCTIONS
# ##############################################################################################################################################################################

def trimFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, tempMediaFolderPath, fromTimestamp, toTimestamp, fromSec, toSec, trimWhere, trimType, encodeCodec, encodeFramerate, removeInsideCase, endTimestampPy ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "trimFunction"
    if "outside" in trimWhere:
        if "fast_copy_Keyframe" in trimType:
            #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-ss", fromTimestamp, "-i", "/"+inputPathPy, "-to", toTimestamp, "-c:v", "copy", "-c:a", "copy", "/"+outputPathPy ], shell = False)
            for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-ss", fromTimestamp, "-i", "/"+inputPathPy, "-to", toTimestamp, "-c:v", "copy", "-c:a", "copy", "/"+outputPathPy ]):
                pyotherside.send('progressPercentage', progress)
        elif "fast_copy_noKeyframe" in trimType:
            #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-ss", fromTimestamp, "-to", toTimestamp, "-c:v", "copy", "-c:a", "copy", "/"+outputPathPy ], shell = False )
            for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-ss", fromTimestamp, "-to", toTimestamp, "-c:v", "copy", "-c:a", "copy", "/"+outputPathPy ]):
                pyotherside.send('progressPercentage', progress)
        elif "slow_reencode_createKeyframe" in trimType:
            #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-ss", fromTimestamp, "-to", toTimestamp, "-c:v", encodeCodec, "-crf", encodeFramerate, "/"+outputPathPy ], shell = False)
            for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-ss", fromTimestamp, "-to", toTimestamp, "-c:v", encodeCodec, "-crf", encodeFramerate, "-pix_fmt", "yuv420p",  "-c:a", "copy", "/"+outputPathPy ]):
                pyotherside.send('progressPercentage', progress)
        if "true" in success :
            pyotherside.send('loadTempMedia', outputPathPy )
    else: # remove area "inside" markers
        if "remove_start_mid" in removeInsideCase : # remove first part and keep the rest of the file
            if "fast_copy_Keyframe" in trimType:
                for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-ss", toTimestamp, "-i", "/"+inputPathPy, "-c:v", "copy", "-c:a", "copy", "/"+outputPathPy ]):
                    pyotherside.send('progressPercentage', progress)
            elif "fast_copy_noKeyframe" in trimType:
                for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-ss", toTimestamp, "-c:v", "copy", "-c:a", "copy", "/"+outputPathPy ]):
                    pyotherside.send('progressPercentage', progress)
            elif "slow_reencode_createKeyframe" in trimType:
                for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-ss", toTimestamp, "-c:v", encodeCodec, "-crf", encodeFramerate, "-pix_fmt", "yuv420p",  "-c:a", "copy", "/"+outputPathPy ]):
                    pyotherside.send('progressPercentage', progress)
            if "true" in success :
                pyotherside.send('loadTempMedia', outputPathPy )
        if "remove_mid_end" in removeInsideCase : # remove last part and keep the rest of the file
            if "fast_copy_Keyframe" in trimType:
                for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-ss", "00:00:00.000", "-i", "/"+inputPathPy, "-to", fromTimestamp, "-c:v", "copy", "-c:a", "copy", "/"+outputPathPy ]):
                    pyotherside.send('progressPercentage', progress)
            elif "fast_copy_noKeyframe" in trimType:
                for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-ss", "00:00:00.000", "-to", fromTimestamp, "-c:v", "copy", "-c:a", "copy", "/"+outputPathPy ]):
                    pyotherside.send('progressPercentage', progress)
            elif "slow_reencode_createKeyframe" in trimType:
                for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-ss", "00:00:00.000", "-to", fromTimestamp, "-c:v", encodeCodec, "-crf", encodeFramerate, "-pix_fmt", "yuv420p",  "-c:a", "copy", "/"+outputPathPy ]):
                    pyotherside.send('progressPercentage', progress)
            if "true" in success :
                pyotherside.send('loadTempMedia', outputPathPy )
        if "remove_mid_mid" in removeInsideCase :
            if "fast_copy_Keyframe" in trimType:
                for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-ss", "00:00:00.000", "-i", "/"+inputPathPy, "-t", fromTimestamp, "-c:v", "copy", "-c:a", "copy", "/"+tempMediaFolderPath+"1part.mkv" ]):
                    pyotherside.send('progressPercentage', progress/2)
                if "true" in success :
                    for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-ss", toTimestamp, "-i", "/"+inputPathPy, "-to", endTimestampPy, "-c:v", "copy", "-c:a", "copy", "/"+tempMediaFolderPath+"2part.mkv" ]):
                        pyotherside.send('progressPercentage', 50+progress/2)

            elif "fast_copy_noKeyframe" in trimType:
                '''
                subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter_complex", "[0:v]trim=duration="+fromSec+",setpts=PTS-STARTPTS[v0];[0:a]atrim=duration="+fromSec+",asetpts=PTS-STARTPTS[a0];[0:v]trim=start="+toSec+",setpts=PTS-STARTPTS[v1];[0:a]atrim=start="+toSec+",asetpts=PTS-STARTPTS[a1];[v0][a0][v1][a1]concat=n=2:v=1:a=1[out]", "-map", "[out]", "/"+outputPathPy ], shell = False)
                pyotherside.send('loadTempMedia', outputPathPy )
                '''
                for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-ss", "00:00:00.000", "-t", fromTimestamp, "-c:v", "copy", "-c:a", "copy", "/"+tempMediaFolderPath+"1part.mkv" ]):
                    pyotherside.send('progressPercentage', progress/2)
                if "true" in success :
                    for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-ss", toTimestamp, "-c:v", "copy", "-c:a", "copy", "/"+tempMediaFolderPath+"2part.mkv" ]):
                        pyotherside.send('progressPercentage', 50+progress/2)

            elif "slow_reencode_createKeyframe" in trimType:
                for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-ss", "00:00:00.000", "-to", fromTimestamp, "-c:v", encodeCodec, "-crf", encodeFramerate, "-pix_fmt", "yuv420p", "-c:a", "copy", "/"+tempMediaFolderPath+"1part.mkv" ]):
                    pyotherside.send('progressPercentage', progress/2)
                if "true" in success :
                    for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-ss", toTimestamp, "-to", endTimestampPy, "-c:v", encodeCodec, "-crf", encodeFramerate, "-pix_fmt", "yuv420p", "-c:a", "copy", "/"+tempMediaFolderPath+"2part.mkv" ]):
                        pyotherside.send('progressPercentage', 50+progress/2)
            # -> clear list and use those two outer parts
            for i in os.listdir( "/" + tempMediaFolderPath ) :
                if (i.find(".txt") != -1):
                    os.remove ("/" + tempMediaFolderPath+i)
                    pyotherside.send('tempFilesDeleted', i )
            with open("/"+tempMediaFolderPath+"mergeFiles.txt","w+") as txtFile:
                txtFile.write("file '/" + tempMediaFolderPath + "1part.mkv'" + "\n" + "file '/" + tempMediaFolderPath + "2part.mkv'")

            # -> merge together
            if "true" in success :
                #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter_complex", "[0:v]trim=0:"+fromTimestamp+",setpts=PTS-STARTPTS[v0];[0:a]atrim=0:"+fromTimestamp+",asetpts=PTS-STARTPTS[a0];[0:v]trim="+toTimestamp+":"+endTimestampPy+",setpts=PTS-STARTPTS[v1];[0:a]atrim="+toTimestamp+":"+endTimestampPy+",asetpts=PTS-STARTPTS[a1];[v0][a0][v1][a1]concat=n=2:v=1:a=1[out]", "-map", "[out]", "/"+outputPathPy ], shell = False)
                #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-f", "concat", "-safe", "0", "-i", "/"+tempMediaFolderPath+"mergeFiles.txt", "-c", "copy", "/"+outputPathPy ], shell = False)
                for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-f", "concat", "-safe", "0", "-i", "/"+tempMediaFolderPath+"mergeFiles.txt", "-c", "copy", "/"+outputPathPy ]):
                    pyotherside.send('progressPercentage', progress)
                if "true" in success :
                    pyotherside.send('loadTempMedia', outputPathPy )

            # clear all tmp files anyway
            for i in os.listdir( "/"+tempMediaFolderPath ) :
                if (i.find("part.mkv") != -1):
                    os.remove ( "/"+tempMediaFolderPath+i )
                    pyotherside.send('tempFilesDeleted', i )
            for i in os.listdir( "/" + tempMediaFolderPath ) :
                if (i.find(".txt") != -1):
                    os.remove ("/" + tempMediaFolderPath+i)
                    pyotherside.send('tempFilesDeleted', i )


def speedFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, speedVideoFactor, speedAudioFactor ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "speedFunction"
    #subprocess.run([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "setpts="+speedVideoFactor+"*PTS", "-filter:a", "atempo="+speedAudioFactor, "/"+outputPathPy ], shell = False )
    for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "setpts="+speedVideoFactor+"*PTS", "-filter:a", "atempo="+speedAudioFactor, "/"+outputPathPy ]):
        pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )

def cropAreaFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, cropX, cropY, cropWidth, cropHeight, scaleDisplayFactorCrop ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "cropAreaFunction"
    outX = str(int(cropX * scaleDisplayFactorCrop))
    outY = str(int(cropY * scaleDisplayFactorCrop))
    outW = str(int(cropWidth * scaleDisplayFactorCrop))
    outH = str(int(cropHeight * scaleDisplayFactorCrop))
    #subprocess.run([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "crop="+outW+":"+outH+":"+outX+":"+outY, "-c:a", "copy", "/"+outputPathPy ], shell = False )
    for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "crop="+outW+":"+outH+":"+outX+":"+outY, "-c:a", "copy", "/"+outputPathPy ]):
        pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )

def padAreaFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, paddingRatio, padWhere, padColor, outWidth, outHeight ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "padAreaFunction"
    outWidth = str(outWidth)
    outHeight = str (outHeight)
    #subprocess.check_call([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "scale=w="+outWidth+"-1:h="+outHeight+"-1:force_original_aspect_ratio=1,pad="+outWidth+":"+outHeight+":(ow-iw)/2:(oh-ih)/2", "-c:a", "copy", "/"+outputPathPy ], shell = False )
    for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "scale=w="+outWidth+"-1:h="+outHeight+"-1:force_original_aspect_ratio=1,pad="+outWidth+":"+outHeight+":(ow-iw)/2:(oh-ih)/2", "-c:a", "copy", "/"+outputPathPy ]):
        pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )


def addTimeFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, tempMediaFolderPath, whereInVideo, atTimestamp, addLength, addColor, origVideoWidth, origVideoHeight, origFrameRate, origContainer, origCodecVideo, origCodecAudio, origAudioSamplerate, origAudioLayout, origPixelFormat, sourceSampleAspectRatio, addClipType, addVideoPath ):
    # important: this function requires I-frames for success on compressed video files
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "addTimeFunction"
    if "blank_clip" in addClipType:
        #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-f", "lavfi", "-i", "color=c="+addColor+":s="+origVideoWidth+"x"+origVideoHeight+":r="+origFrameRate, "-t", addLength, "-f", "lavfi", "-i", "anullsrc=channel_layout="+origAudioLayout+":sample_rate="+origAudioSamplerate, "-t", addLength, "-c:v", origCodecVideo, "-tune", "stillimage", "-pix_fmt", origPixelFormat, "-c:a", origCodecAudio, "/"+tempMediaFolderPath+"new_part."+origContainer ] )
        subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "color=c="+addColor+":s="+origVideoWidth+"x"+origVideoHeight+":r="+origFrameRate, "-t", addLength, "-i", "anullsrc=channel_layout="+origAudioLayout+":sample_rate="+origAudioSamplerate, "-t", addLength, "-c:v", origCodecVideo, "-tune", "stillimage", "-pix_fmt", origPixelFormat, "-c:a", origCodecAudio, "/"+tempMediaFolderPath+"new_part."+origContainer ] )
        if "start" in whereInVideo:
            first_path = "/"+tempMediaFolderPath+"new_part."+origContainer
            second_path = "/"+inputPathPy
        if "end" in whereInVideo:
            first_path = "/"+inputPathPy
            second_path = "/"+tempMediaFolderPath+"new_part."+origContainer
        if "middle" in whereInVideo:
            subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-ss", "00:00:00.000", "-i", "/"+inputPathPy, "-t", atTimestamp, "-c:v", "copy", "-c:a", "copy", "-avoid_negative_ts", "1", "/"+tempMediaFolderPath+"1part."+origContainer ])
            subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-ss", atTimestamp, "-i", "/"+inputPathPy, "-c:v", "copy", "-c:a", "copy", "-avoid_negative_ts", "1", "/"+tempMediaFolderPath+"2part."+origContainer ])
            first_path = "/"+tempMediaFolderPath+"1part."+origContainer
            second_path = "/"+tempMediaFolderPath+"new_part."+origContainer
            third_path = "/"+tempMediaFolderPath+"2part."+origContainer
    if "video_clip" in addClipType:
        if "start" in whereInVideo:
            first_path = "/"+addVideoPath
            second_path = "/"+inputPathPy
        if "end" in whereInVideo:
            first_path = "/"+inputPathPy
            second_path = "/"+addVideoPath
        if "middle" in whereInVideo:
            subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-ss", "00:00:00.000", "-i", "/"+inputPathPy, "-to", atTimestamp, "-c:v", "copy", "-c:a", "copy", "-avoid_negative_ts", "1", "/"+tempMediaFolderPath+"1part."+origContainer ])
            subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-ss", atTimestamp, "-i", "/"+inputPathPy, "-c:v", "copy", "-c:a", "copy", "-avoid_negative_ts", "1", "/"+tempMediaFolderPath+"2part."+origContainer ])
            first_path = "/"+tempMediaFolderPath+"1part."+origContainer
            second_path = "/"+addVideoPath
            third_path = "/"+tempMediaFolderPath+"2part."+origContainer

    if "freeze_frame" in addClipType:
        subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-ss", atTimestamp, "-frames:v", "1", "/"+tempMediaFolderPath+"freeze_frame.png" ], shell = False ) # at marker
        subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-loop", "1", "-t", addLength, "-framerate", origFrameRate, "-i", "/"+tempMediaFolderPath+"freeze_frame.png", "-i", "anullsrc=channel_layout="+origAudioLayout+":sample_rate="+origAudioSamplerate, "-t", addLength, "-c:v", origCodecVideo, "-tune", "stillimage", "-pix_fmt", origPixelFormat, "-c:a", origCodecAudio, "/"+tempMediaFolderPath+"freeze_part."+origContainer  ], shell = False )
        if "start" in whereInVideo:
            first_path = "/"+tempMediaFolderPath+"freeze_part."+origContainer
            second_path = "/"+inputPathPy
        if "end" in whereInVideo:
            first_path = "/"+inputPathPy
            second_path = "/"+tempMediaFolderPath+"freeze_part."+origContainer
        if "middle" in whereInVideo:
            subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-ss", "00:00:00.000", "-i", "/"+inputPathPy, "-t", atTimestamp, "-c:v", "copy", "-c:a", "copy", "-avoid_negative_ts", "1", "/"+tempMediaFolderPath+"1part."+origContainer ])
            subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-ss", atTimestamp, "-i", "/"+inputPathPy, "-c:v", "copy", "-c:a", "copy", "-avoid_negative_ts", "1", "/"+tempMediaFolderPath+"2part."+origContainer ])
            first_path = "/"+tempMediaFolderPath+"1part."+origContainer
            second_path = "/"+tempMediaFolderPath+"freeze_part."+origContainer
            third_path = "/"+tempMediaFolderPath+"2part."+origContainer

    if "middle" in whereInVideo:
        #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", first_path, "-i", second_path, "-i", third_path, "-filter_complex", "[1:v]scale="+origVideoWidth+":"+origVideoHeight+":force_original_aspect_ratio=decrease,pad="+origVideoWidth+":"+origVideoHeight+":(ow-iw)/2:(oh-ih)/2,setsar="+( sourceSampleAspectRatio.replace(":", "/") )+"[v1];[0:v][0:a][v1][1:a][2:v][2:a]concat=n=3:v=1:a=1[v][a]", "-map", "[v]", "-map", "[a]", "-c:v", origCodecVideo, "-c:a", origCodecAudio, "/"+outputPathPy ] )
        for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", first_path, "-i", second_path, "-i", third_path, "-filter_complex", "[1:v]scale="+origVideoWidth+":"+origVideoHeight+":force_original_aspect_ratio=decrease,pad="+origVideoWidth+":"+origVideoHeight+":(ow-iw)/2:(oh-ih)/2,setsar="+( sourceSampleAspectRatio.replace(":", "/") )+"[v1];[0:v][0:a][v1][1:a][2:v][2:a]concat=n=3:v=1:a=1[v][a]", "-map", "[v]", "-map", "[a]", "-c:v", origCodecVideo, "-c:a", origCodecAudio, "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
    elif "start" in whereInVideo:
        for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", first_path, "-i", second_path, "-filter_complex", "[0:v]scale="+origVideoWidth+":"+origVideoHeight+":force_original_aspect_ratio=decrease,pad="+origVideoWidth+":"+origVideoHeight+":(ow-iw)/2:(oh-ih)/2,setsar="+( sourceSampleAspectRatio.replace(":", "/") )+"[v0];[v0][0:a][1:v][1:a]concat=n=2:v=1:a=1[v][a]", "-map", "[v]", "-map", "[a]", "-c:v", origCodecVideo, "-c:a", origCodecAudio, "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
    else: #end"
        for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", first_path, "-i", second_path, "-filter_complex", "[1:v]scale="+origVideoWidth+":"+origVideoHeight+":force_original_aspect_ratio=decrease,pad="+origVideoWidth+":"+origVideoHeight+":(ow-iw)/2:(oh-ih)/2,setsar="+( sourceSampleAspectRatio.replace(":", "/") )+"[v1];[0:v][0:a][v1][1:a]concat=n=2:v=1:a=1[v][a]", "-map", "[v]", "-map", "[a]", "-c:v", origCodecVideo, "-c:a", origCodecAudio, "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
    for i in os.listdir( "/"+tempMediaFolderPath ) :
        if (i.find("part."+origContainer) != -1):
            os.remove ( "/"+tempMediaFolderPath+i )
            pyotherside.send('tempFilesDeleted', i )
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )





def resizeFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, newWidth, newHeight, autoScale, applyStretch ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "resizeFunction"
    if "fixBoth" in autoScale:
        if "stretch" in applyStretch:
            #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vf", "scale="+newWidth+"x"+newHeight+":flags=lanczos", "-c:a", "copy", "/"+outputPathPy ], shell = False )
            for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vf", "scale="+newWidth+"x"+newHeight+":flags=lanczos", "-c:a", "copy", "/"+outputPathPy ]):
                pyotherside.send('progressPercentage', progress)
        elif "pad" in applyStretch:
            #subprocess.run([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-aspect", newWidth+"/"+newHeight, "-s", newWidth+"x"+newHeight, "-c:a", "copy", "/"+outputPathPy ], shell = False )
            for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "scale=w="+newWidth+"-1:h="+newHeight+"-1:force_original_aspect_ratio=1,pad="+newWidth+":"+newHeight+":(ow-iw)/2:(oh-ih)/2", "-c:a", "copy", "/"+outputPathPy ]):
                pyotherside.send('progressPercentage', progress)
    elif "fixWidth" in autoScale:
        #subprocess.run([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "scale="+newWidth+":trunc(ow/a/2)*2", "-c:a", "copy", "/"+outputPathPy ], shell = False )
        for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "scale="+newWidth+":trunc(ow/a/2)*2", "-c:a", "copy", "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
    elif "fixHeight" in autoScale:
        #subprocess.run([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "scale=trunc(oh*a/2)*2:"+newHeight, "-c:a", "copy", "/"+outputPathPy ], shell = False )
        for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "scale=trunc(oh*a/2)*2:"+newHeight, "-c:a", "copy", "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )


def repairFramesFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "repairFramesFunction"
    for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-force_key_frames", "expr:gte(t,n_forced*3)", "/"+outputPathPy ]):
        pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )


def removeBWframesFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, colorRemove, amountBW, thresholdBW ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "removeBWframesFunction"
    #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "blackframe=1,metadata=select:key=lavfi.blackframe.pblack:value=0:function=less", "vsync", "cfr", "/"+outputPathPy ], shell = False )

    if "black" in colorRemove:
        subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "blackframe="+amountBW+":"+thresholdBW+",metadata=select:key=lavfi.blackframe.pblack:value=0:function=less", "/"+outputPathPy ], shell = False )
        #for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "blackframe=1,metadata=select:key=lavfi.blackframe.pblack:value=0:function=less", "vsync", "cfr", "/"+outputPathPy ]):
        #    pyotherside.send('progressPercentage', progress)
    elif "white" in colorRemove:
        subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "negate,blackframe="+amountBW+":"+thresholdBW+",metadata=select:key=lavfi.blackframe.pblack:value=0:function=less,negate", "/"+outputPathPy ], shell = False )
    #if "true" in success :
    pyotherside.send('loadTempMedia', outputPathPy )




    # IMAGE FUNCTIONS
# IMAGE FUNCTIONS
# ##############################################################################################################################################################################

def imageFadeFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, fadeFrom, fadeLength, fadeDirection, fadeCase, fromSec, toSec ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "imageFadeFunction"
    if ("cursor0" in fadeCase) or ("cursor1" in fadeCase):
        #subprocess.run([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vf", "fade=t="+fadeDirection+":st="+fadeFrom+":d="+fadeLength, "-c:a", "copy", "/"+outputPathPy ], shell = False )
        for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vf", "fade=t="+fadeDirection+":st="+fadeFrom+":d="+fadeLength, "-c:a", "copy", "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
    else: # marker0 or marker1
        #subprocess.run([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter_complex", "[0:v]trim=start="+fromSec+":end="+toSec+",fade=t="+fadeDirection+":st="+fadeFrom+":d="+fadeLength+"[over];[0:v][over]overlay=enable='between(t,"+fromSec+","+toSec+")'[out]", "-map", "[out]", "-map", "0:a", "-c:a", "copy", "/"+outputPathPy ], shell = False )
        for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter_complex", "[0:v]trim=start="+fromSec+":end="+toSec+",fade=t="+fadeDirection+":st="+fadeFrom+":d="+fadeLength+"[over];[0:v][over]overlay=enable='between(t,"+fromSec+","+toSec+")'[out]", "-map", "[out]", "-map", "0:a", "-c:a", "copy", "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )

def imageRotateFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, rotateDirection ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "imageRotateFunction"
    #subprocess.run([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vf", "transpose="+rotateDirection, "-c:a", "copy", "/"+outputPathPy ], shell = False )
    for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vf", "transpose="+rotateDirection, "-c:a", "copy", "/"+outputPathPy ]):
        pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )

def imageMirrorFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, mirrorDirection ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "imageMirrorFunction"
    #subprocess.run([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vf", mirrorDirection, "-c:a", "copy", "/"+outputPathPy ], shell = False )
    for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vf", mirrorDirection, "-c:a", "copy", "/"+outputPathPy ]):
        pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )


def imageGrayscaleFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, fromSec, toSec ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "imageGrayscaleFunction"
    #subprocess.run([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vf", "hue=s=0"+":enable='between(t,"+fromSec+","+toSec+")'", "-c:a", "copy", "/"+outputPathPy ], shell = False )
    for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vf", "hue=s=0"+":enable='between(t,"+fromSec+","+toSec+")'", "-c:a", "copy", "/"+outputPathPy ]):
        pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )

def imageNormalizeFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, fromSec, toSec ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "imageNormalizeFunction"
    #subprocess.run([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vf", "normalize=strength=1"+":enable='between(t,"+fromSec+","+toSec+")'", "-c:a", "copy", "/"+outputPathPy ], shell = False )
    for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vf", "normalize=strength=1"+":enable='between(t,"+fromSec+","+toSec+")'", "-c:a", "copy", "/"+outputPathPy ]):
        pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )

def imageStabilizeFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, fromSec, toSec):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "imageStabilizeFunction"
    for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "deshake", "-c:a", "copy", "/"+outputPathPy ]):
        pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )

def imageReverseFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "imageReverseFunction"
    #subprocess.run([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vf", "reverse", "-filter:a", "areverse", "/"+outputPathPy ], shell = False )
    for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vf", "reverse", "-filter:a", "areverse", "/"+outputPathPy ]):
        pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )

def imageVibranceFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, newValue, fromSec, toSec  ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "imageVibranceFunction"
    #subprocess.run([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter_complex", "vibrance=intensity="+newValue+":enable='between(t,"+fromSec+","+toSec+")'", "-c:a", "copy", "/"+outputPathPy ], shell = False )
    for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter_complex", "vibrance=intensity="+newValue+":enable='between(t,"+fromSec+","+toSec+")'", "-c:a", "copy", "/"+outputPathPy ]):
        pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )

def imageCurveFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, applyCurve, fromSec, toSec  ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "imageCurveFunction"
    #subprocess.run([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vf", "curves="+applyCurve+":enable='between(t,"+fromSec+","+toSec+")'", "-c:a", "copy", "/"+outputPathPy ], shell = False )
    for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vf", "curves="+applyCurve+":enable='between(t,"+fromSec+","+toSec+")'", "-c:a", "copy", "/"+outputPathPy ]):
        pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )

def imageLUT3dFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, cubeFilePath, fromSec, toSec ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "imageLUT3DFunction"
    if ".png" in cubeFilePath[-4:]: # show last 4 letters
        #subprocess.check_call([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-i", "/"+cubeFilePath, "-filter_complex", "haldclut=enable='between(t,"+fromSec+","+toSec+")'", "-c:a", "copy", "/"+outputPathPy ], shell = False )
        for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-i", "/"+cubeFilePath, "-filter_complex", "haldclut=enable='between(t,"+fromSec+","+toSec+")'", "-c:a", "copy", "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
        if "true" in success :
            pyotherside.send('loadTempMedia', outputPathPy )
    else: # must be a .cube file then
        #subprocess.check_call([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vf", "lut3d="+"/"+cubeFilePath+":enable='between(t,"+fromSec+","+toSec+")'", "-c:a", "copy", "/"+outputPathPy ], shell = False )
        for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vf", "lut3d="+"/"+cubeFilePath+":enable='between(t,"+fromSec+","+toSec+")'", "-c:a", "copy", "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
        if "true" in success :
            pyotherside.send('loadTempMedia', outputPathPy )

def imageBlurFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, fromSec, toSec, cropX, cropY, cropWidth, cropHeight, scaleDisplayFactorCrop, blurIntensity, blurWhere ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "imageBlurFunction"
    outX = str(int(cropX * scaleDisplayFactorCrop))
    outY = str(int(cropY * scaleDisplayFactorCrop))
    outW = str(int(cropWidth * scaleDisplayFactorCrop))
    outH = str(int(cropHeight * scaleDisplayFactorCrop))
    if "inside" in blurWhere:
        #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter_complex", "[0:v]crop="+outW+":"+outH+":"+outX+":"+outY+",boxblur="+blurIntensity+":enable='between(t,"+fromSec+","+toSec+")'"+"[fg];[0:v][fg]overlay="+outX+":"+outY+"[v]", "-map", "[v]", "-map", "0:a", "-c:a", "copy", "/"+outputPathPy ], shell = False )
        for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter_complex", "[0:v]crop="+outW+":"+outH+":"+outX+":"+outY+",boxblur="+blurIntensity+":enable='between(t,"+fromSec+","+toSec+")'"+"[fg];[0:v][fg]overlay="+outX+":"+outY+"[v]", "-map", "[v]", "-map", "0:a", "-c:a", "copy", "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
    else: # "outside"
        #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter_complex", "[0:v]boxblur="+blurIntensity+":enable='between(t,"+fromSec+","+toSec+")'"+"[bg];[0:v]crop="+outW+":"+outH+":"+outX+":"+outY+"[fg];[bg][fg]overlay="+outX+":"+outY, "-map", "0:v", "-map", "0:a", "-c:a", "copy", "/"+outputPathPy ], shell = False )
        for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter_complex", "[0:v]boxblur="+blurIntensity+":enable='between(t,"+fromSec+","+toSec+")'"+"[bg];[0:v]crop="+outW+":"+outH+":"+outX+":"+outY+"[fg];[bg][fg]overlay="+outX+":"+outY, "-map", "0:v", "-map", "0:a", "-c:a", "copy", "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )

def imageGeneralEffectFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, effectName, fromSec, toSec, someValue1, someValue2 ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "imageGeneralEffectFunction"
    if "edgedetect" in effectName:
        for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", effectName+"=enable='between(t,"+fromSec+","+toSec+")'", "-c:a", "copy", "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
    elif ("telecine" in effectName) or ("photosensitivity" in effectName) or ("stereo3d" in effectName) :
        for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", effectName, "-c:a", "copy", "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
    elif "unsharp" in effectName: #sharpening someValue > 0
        for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", effectName+"=5:5:"+someValue1+":5:5:"+someValue2+":enable='between(t,"+fromSec+","+toSec+")'", "-c:a", "copy", "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
    elif ("photosensitivity" in effectName) or ("stereo3d" in effectName):
        for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", effectName+"=5:5:"+someValue1+":5:5:"+someValue2+":enable='between(t,"+fromSec+","+toSec+")'", "-c:v", "mpeg4", "-preset", "veryfast", "-pix_fmt", "yuv420p", "-c:a", "aac", "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
    else:
        for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", effectName+"=enable='between(t,"+fromSec+","+toSec+")'", "-c:a", "copy", "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )


def imageDeshakeFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, tempMediaFolderPath, fromSec, toSec ): # deshake does not work in latest git ffmpeg, since there is an internal error with vid.stab as of Jan21 -> use older version or wait for update
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "imageDeshakeFunction"
    #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "vidstabdetect=stepsize=32:shakiness=10:accuracy=10:result=/"+tempMediaFolderPath+"transforms.trf", "-f", "null", "-" ], shell = False )
    #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "vidstabtransform=input=/"+tempMediaFolderPath+"transforms.trf:zoom=0:smoothing=10,unsharp=5:5:0.8:3:3:0.4", "-c:v", "libx264", "-preset", "veryfast", "-tune", "film", "-pix_fmt", "yuv420p", "-c:a", "aac", "/"+outputPathPy ], shell = False)
    #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "vidstabtransform=input=/"+tempMediaFolderPath+"transforms.trf:optzoom=2:smoothing=10,unsharp=5:5:0.8:3:3:0.4", "-c:v", "libx264", "-preset", "veryfast", "-tune", "film", "-pix_fmt", "yuv420p", "-c:a", "aac", "/"+outputPathPy ], shell = False)
    for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "vidstabdetect=stepsize=32:shakiness=10:accuracy=10:result=/"+tempMediaFolderPath+"transforms.trf", "-f", "null", "-" ]):
        pyotherside.send('progressPercentage', (progress / 2) )
        step2finished = "false"
    for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "vidstabtransform=input=/"+tempMediaFolderPath+"transforms.trf:optzoom=2:smoothing=10,unsharp=5:5:0.8:3:3:0.4", "-c:v", "mpeg4", "-preset", "veryfast", "-tune", "film", "-pix_fmt", "yuv420p", "-c:a", "aac", "/"+outputPathPy ]):
        pyotherside.send('progressPercentage', (progress / 2 + 50) )
        step2finished = "true"
    for i in os.listdir( "/"+tempMediaFolderPath ) :
        if (i.find(".trf") != -1):
            os.remove ( "/"+tempMediaFolderPath+i )
            pyotherside.send('tempFilesDeleted', i )
    if ("true" in success) and ("true" in step2finished) :
        pyotherside.send('loadTempMedia', outputPathPy )




def imageColorFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, targetValue, targetAttribute, fromSec, toSec ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "imageColorFunction"
    #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vf", "eq="+targetAttribute+"="+targetValue, "-an", "-c:a", "copy", "/"+outputPathPy ], shell = False )
    for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vf", "eq="+targetAttribute+"="+targetValue+":enable='between(t,"+fromSec+","+toSec+")'", "-c:a", "copy", "/"+outputPathPy ]):
        pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )


def imageFrei0rFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, applyEffect, applyParams, fromSec, toSec, useParams, origCodecVideo  ): # always hang with ffmpeg_static and not supported in ffmpeg_SF
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "imageFrei0rFunction"
    if "true" in useParams:
        #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "frei0r=filter_name="+applyEffect+":filter_params="+applyParams, "-c:v", "libx264", "-preset", "veryfast", "-pix_fmt", "yuv420p", "-c:a", "aac", "/"+outputPathPy ], shell = False )
        for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "frei0r=filter_name="+applyEffect+":"+applyParams, "-c:v", "mpeg4", "-preset", "veryfast", "-pix_fmt", "yuv420p", "-c:a", "aac", "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
    else: # "false"
        for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "frei0r=filter_name="+applyEffect, "-c:v", "mpeg4", "-preset", "veryfast", "-pix_fmt", "yuv420p", "-c:a", "aac", "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )





# COLLAGE FUNCTIONS
# ##############################################################################################################################################################################

def createSlideshowFunction ( ffmpeg_staticPath, outputPathPy, allSelectedPaths, allSelectedDurations, allSelectedTransitions, allSelectedTransitionDurations, targetWidth, targetHeight, newFileName, panZoom ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "createSlideshowFunction"
    allSelectedPathsList = list( allSelectedPaths.split(";;") )
    del allSelectedPathsList[-1] # remove last empty field
    allSelectedDurationsList = list( allSelectedDurations.split(";;") )
    del allSelectedDurationsList[-1] # remove last empty field
    allSelectedTransitionsList = list( allSelectedTransitions.split(";;") )
    del allSelectedTransitionsList[-1] # remove last empty field
    allSelectedTransitionDurationsList = list( allSelectedTransitionDurations.split(";;") )
    del allSelectedTransitionDurationsList[-1] # remove last empty field
    inputFilesList = []
    inputFilesList.clear()
    complexFilter = ""
    xFadeInfos = ""
    durationCounter = 0
    randomPanZoom = 0
    lastRandom = 0

    for i in range (0, len(allSelectedPathsList)) :
        if "still_images" in panZoom:
            if i == 0:
                inputFilesList.extend([ "-loop", "1", "-t", str( float(allSelectedDurationsList[i]) + float(allSelectedTransitionDurationsList[i]) ), "-i", str(allSelectedPathsList[i]) ])
            else: # Patch: length + fade before and fade after are needed, otherwise too short
                inputFilesList.extend([ "-loop", "1", "-t", str( float(allSelectedDurationsList[i]) + float(allSelectedTransitionDurationsList[i]) + float(allSelectedTransitionDurationsList[i-1])  ), "-i", str(allSelectedPathsList[i]) ])
            applyZoomPan = ""
        elif "pan_and_zoom" in panZoom: # Patch: pan/zoom does not work with "loop 1" input, would loop endlessly
            if i  == 0:
                inputFilesList.extend([ "-t", str( float(allSelectedDurationsList[i]) + float(allSelectedTransitionDurationsList[i]) ), "-i", str(allSelectedPathsList[i]) ])
                panZoomDuration = str( (float(allSelectedDurationsList[i]) + float(allSelectedTransitionDurationsList[i])) * 25 ) # fps * sec
            else: # Patch: length + fade before and fade after are needed, otherwise too short
                inputFilesList.extend([ "-t", str( float(allSelectedDurationsList[i]) + float(allSelectedTransitionDurationsList[i]) + float(allSelectedTransitionDurationsList[i-1])  ), "-i", str(allSelectedPathsList[i]) ])
                panZoomDuration = str( (float(allSelectedDurationsList[i]) + float(allSelectedTransitionDurationsList[i]) + float(allSelectedTransitionDurationsList[i-1])) * 25 ) # fps * sec
            randomPanZoom = random.randint(-4,4)
            if randomPanZoom is lastRandom :
                randomPanZoom = random.randint(-4,4)
                if randomPanZoom is lastRandom :
                    randomPanZoom = random.randint(-4,4)
            if randomPanZoom == -4: # IN to up left
                applyZoomPan = ",zoompan=z='min(zoom+0.0015,1.5)':d="+panZoomDuration+":s="+targetWidth+"x"+targetHeight
            elif randomPanZoom == -3: # IN to up right
                applyZoomPan = ",zoompan=z='min(zoom+0.0015,1.5)':d="+panZoomDuration+":x='iw-iw/zoom':s="+targetWidth+"x"+targetHeight
            elif randomPanZoom == -2: # IN to low right
                applyZoomPan = ",zoompan=z='min(zoom+0.0015,1.5)':d="+panZoomDuration+":x='iw-iw/zoom':y='ih-ih/zoom':s="+targetWidth+"x"+targetHeight
            elif randomPanZoom == -1: # IN to low left
                applyZoomPan = ",zoompan=z='min(zoom+0.0015,1.5)':d="+panZoomDuration+":y='ih-ih/zoom':s="+targetWidth+"x"+targetHeight
            elif randomPanZoom == 0:
                applyZoomPan = ",zoompan=z='min(zoom+0.0015,1.5)':d="+panZoomDuration+":x='if(gte(zoom,1.5),x,x+1/a)':y='if(gte(zoom,1.5),y,y+1)':s="+targetWidth+"x"+targetHeight
            elif randomPanZoom == 1: # OUT from up left
                applyZoomPan = ",zoompan=z='if(eq(on,1),1.5,zoom-0.0015)':d="+panZoomDuration+":s="+targetWidth+"x"+targetHeight
            elif randomPanZoom == 2: # OUT from up right
                applyZoomPan = ",zoompan=z='if(eq(on,1),1.5,zoom-0.0015)':d="+panZoomDuration+":x='iw-iw/zoom':s="+targetWidth+"x"+targetHeight
            elif randomPanZoom == 3: # OUT from low right
                applyZoomPan = ",zoompan=z='if(eq(on,1),1.5,zoom-0.0015)':d="+panZoomDuration+":x='iw-iw/zoom':y='ih-ih/zoom':s="+targetWidth+"x"+targetHeight
            elif randomPanZoom == 4: # OUT from low left
                applyZoomPan = ",zoompan=z='if(eq(on,1),1.5,zoom-0.0015)':d="+panZoomDuration+":y='ih-ih/zoom':s="+targetWidth+"x"+targetHeight

        lastRandom = randomPanZoom

        # generic fade
        #-filter_complex \
        #"[1]fade=d=1:t=in:alpha=1,setpts=PTS-STARTPTS+2/TB[f0]; \
        # [2]fade=d=1:t=in:alpha=1,setpts=PTS-STARTPTS+4/TB[f1]; \
        # [3]fade=d=1:t=in:alpha=1,setpts=PTS-STARTPTS+6/TB[f2]; \
        # [4]fade=d=1:t=in:alpha=1,setpts=PTS-STARTPTS+8/TB[f3]; \
        # [0][f0]overlay[bg1];[bg1][f1]overlay[bg2];[bg2][f2]overlay[bg3]; \
        # [bg3][f3]overlay,format=yuv420p[v]" -map "[v]"

        # generic xFade -filter_complex \
        #"[0][1]xfade=transition=slideleft:duration=0.5:offset=2.5[f0]; \
        #[f0][2]xfade=transition=slideleft:duration=0.5:offset=5[f1]; \
        #[f1][3]xfade=transition=slideleft:duration=0.5:offset=7.5[f2]; \
        #[f2][4]xfade=transition=slideleft:duration=0.5:offset=10[f3]" \
        #-map "[f3]"
        #
        currentTransition = allSelectedTransitionsList[i]
        if "none" in currentTransition:
            if i == 0:
                if len(allSelectedPathsList) == 1 : #Patch: if only one file just use it alone
                    xFadeInfos += ( "[v"+str(i)+"]concat=n=1:v=1[vx"+str(i)+"];" )
                    lastOutputVX = str("[vx"+str(i)+"]")
                else:
                    xFadeInfos += ( "[v"+str(i)+"][v"+str(i+1)+"]concat=n=2:v=1[vx"+str(i+1)+"];" )
                    lastOutputVX = str("[vx"+str(i+1)+"]")
            elif i > 0 and i < len(allSelectedPathsList)-1 :
                xFadeInfos += ( "[vx"+str(i)+"][v"+str(i+1)+"]concat=n=2:v=1[vx"+str(i+1)+"];" )
                lastOutputVX = str("[vx"+str(i+1)+"]")
        else:
            transitionDuration = str(allSelectedTransitionDurationsList[i])
            offsetXfadeStart = str( float(durationCounter) + float(allSelectedDurationsList[i]) )
            if i == 0:
                if len(allSelectedPathsList) == 1 : #Patch: if only one file just use it alone, no transition possible
                    xFadeInfos += ( "[v"+str(i)+"]concat=n=1:v=1[vx"+str(i)+"];" )
                    lastOutputVX = str("[vx"+str(i)+"]")
                else:
                    xFadeInfos += ( "[v"+str(i)+"][v"+str(i+1)+"]xfade=transition="+currentTransition+":duration="+transitionDuration+":offset="+offsetXfadeStart+"[vx"+str(i+1)+"];" )
                    lastOutputVX = str("[vx"+str(i+1)+"]")
            elif i > 0 and i < len(allSelectedPathsList)-1 :
                xFadeInfos += ( "[vx"+str(i)+"][v"+str(i+1)+"]xfade=transition="+currentTransition+":duration="+transitionDuration+":offset="+offsetXfadeStart+"[vx"+str(i+1)+"];" )
                lastOutputVX = str("[vx"+str(i+1)+"]")
        if i == len(allSelectedPathsList)-1 :
            xFadeInfos = xFadeInfos[:-1] # remove last simicolon since it is not needed

        #pyotherside.send('xFadeInfos', xFadeInfos)
        complexFilter += ( "["+str(i)+":v]" + "scale="+targetWidth+":"+targetHeight+":force_original_aspect_ratio=decrease,pad="+targetWidth+":"+targetHeight+":(ow-iw)/2:(oh-ih)/2,setsar=1"+applyZoomPan+",settb=AVTB[v"+str(i)+"];" )
        durationCounter += float(allSelectedDurationsList[i]) + float(allSelectedTransitionDurationsList[i])

    # add info on how to chain these videos one after another and add a zero audio input for whole length
    complexFilter += xFadeInfos
    #inputFilesList.extend ([ "-f", "lavfi", "-t", str(durationCounter), "-i", "anullsrc=channel_layout=stereo:sample_rate=48000" ])
    # the last file needs to be added again because of some bug in ffmpeg
    inputFilesList.extend([ "-i", str(allSelectedPathsList[len(allSelectedPathsList)-1]) ])
    inputFilesList.extend ([ "-t", str(durationCounter) ])
    #inputFilesList.extend ([ "-i", "anullsrc=channel_layout=stereo:sample_rate=48000" ])

    #pyotherside.send('complexfilter', complexFilter)
    #pyotherside.send('fileList', inputFilesList)

    #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-framerate", "25" ] + inputFilesList + [ "-filter_complex", str(complexFilter), "-map", lastOutputVX, "-map", str(len(allSelectedPathsList))+":a", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-c:a", "aac", "/"+outputPathPy ])
    for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-framerate", "25" ] + inputFilesList + [ "-filter_complex", str(complexFilter), "-map", lastOutputVX, "-c:v", "mjpeg", "-preset", "veryfast", "-r", "25", "-pix_fmt", "yuv420p", "-c:a", "aac", outputPathPy ]):
        pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('newClipCreated', outputPathPy, newFileName )


def splitscreenFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, origVideoWidth, origVideoHeight, sizeDevider, pathSecondVideo, stackDirection, useAudioFrom ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "splitscreenFunction"
    origVideoWidth = str( int(origVideoWidth/sizeDevider) )
    origVideoHeight = str( int(origVideoHeight/sizeDevider) )
    lengthClip1 = subprocess.check_output([ "ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", "/"+inputPathPy ])
    lengthClip2 = subprocess.check_output([ "ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", "/"+pathSecondVideo ])
    totalDuration = max( float(lengthClip1), float(lengthClip2) )
    inputFilesList = []
    inputFilesList.clear()
    inputFilesList.extend([ "-i", "/"+inputPathPy, "-i", "/"+pathSecondVideo,  "-t", str(totalDuration), "-i", "anullsrc=channel_layout=stereo:sample_rate=48000" ])
    #inputFilesList.extend([ "-i", "/"+inputPathPy, "-i", "/"+pathSecondVideo,  "-t", str(totalDuration) ])

    if "first" in useAudioFrom:
        audioMix = ";[0:a][2:a]amix=inputs=2[outa]" #amerge
    elif "second" in useAudioFrom:
        audioMix = ";[1:a][2:a]amix=inputs=2[outa]"
    elif "none" in useAudioFrom:
        audioMix = ";[2:a]amix=inputs=1[outa]"
    elif "both" in useAudioFrom:
        audioMix = ";[0:a][1:a][2:a]amix=inputs=3[outa]"

    if "above" in stackDirection:
        scaleBy = origVideoWidth+":-2"
        stackOrder = "[new][orig]vstack"
    elif "below" in stackDirection:
        scaleBy = origVideoWidth+":-2"
        stackOrder = "[orig][new]vstack"
    elif "left" in stackDirection:
        scaleBy = "-2:"+origVideoHeight
        stackOrder = "[new][orig]hstack"
    elif "right" in stackDirection:
        scaleBy = "-2:"+origVideoHeight
        stackOrder = "[orig][new]hstack"

    #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y" ] + inputFilesList + [ "-filter_complex", "[0]scale="+scaleBy+",setsar=1:1[orig];[1]scale="+scaleBy+",setsar=1:1[new];"+stackOrder+",format=yuv420p[outv]"+audioMix, "-map", "[outv]", "-map", "[outa]", "-c:v", "libx264", "-c:a", "aac", "/"+outputPathPy ], shell = False)
    for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y" ] + inputFilesList + [ "-filter_complex", "[0]scale="+scaleBy+",setsar=1:1[orig];[1]scale="+scaleBy+",setsar=1:1[new];"+stackOrder+",format=yuv420p[outv]"+audioMix, "-map", "[outv]", "-map", "[outa]", "-c:v", "mpeg4", "-c:a", "aac", "/"+outputPathPy ]):
        pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )


def createStorylineFunction ( ffmpeg_staticPath, outputPathPy, allSelectedPaths, allSelectedTransitions, allSelectedTransitionDurations, targetWidth, targetHeight, newFileName ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "createStorylineFunction"
    allSelectedPathsList = list( allSelectedPaths.split(";;") )
    del allSelectedPathsList[-1] # remove last empty field
    allSelectedTransitionsList = list( allSelectedTransitions.split(";;") )
    del allSelectedTransitionsList[-1] # remove last empty field
    allSelectedTransitionDurationsList = list( allSelectedTransitionDurations.split(";;") )
    del allSelectedTransitionDurationsList[-1] # remove last empty field
    inputFilesList = []
    inputFilesList.clear()
    complexFilter = ""
    xFadeInfos = ""
    previousXfadeOffset = 0
    offsetXfadeStart = 0

    for i in range (0, len(allSelectedPathsList)) :
        currentFileDuration = subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0:s=x", str(allSelectedPathsList[i]) ])
        inputFilesList.extend([ "-i", str(allSelectedPathsList[i]) ])
        currentTransition = allSelectedTransitionsList[i]
        if "none" in currentTransition:
            if i == 0:
                if len(allSelectedPathsList) == 1 : #Patch: if only one file just use it alone
                    xFadeInfos += ( "[v"+str(i)+"]["+str(i)+":a]concat=n=1:v=1:a=1[vx"+str(i)+"][ax"+str(i)+"];" )
                    lastOutputVX = str("[vx"+str(i)+"]")
                    lastOutputAX = str("[ax"+str(i)+"]")
                else:
                    xFadeInfos += ( "[v"+str(i)+"]["+str(i)+":a][v"+str(i+1)+"]["+str(i+1)+":a]concat=n=2:v=1:a=1[vx"+str(i+1)+"][ax"+str(i+1)+"];" )
                    lastOutputVX = str("[vx"+str(i+1)+"]")
                    lastOutputAX = str("[ax"+str(i+1)+"]")
            elif i > 0 and i < len(allSelectedPathsList)-1 :
                xFadeInfos += ( "[vx"+str(i)+"][ax"+str(i)+"][v"+str(i+1)+"]["+str(i+1)+":a]concat=n=2:v=1:a=1[vx"+str(i+1)+"][ax"+str(i+1)+"];" )
                lastOutputVX = str("[vx"+str(i+1)+"]")
                lastOutputAX = str("[ax"+str(i+1)+"]")
        else:
            transitionDuration = str(allSelectedTransitionDurationsList[i])
            offsetXfadeStart = str( float(currentFileDuration) + float(previousXfadeOffset) - float(allSelectedTransitionDurationsList[i])  )
            if i == 0:
                if len(allSelectedPathsList) == 1 : #Patch: if only one file just use it alone
                    xFadeInfos += ( "[v"+str(i)+"]["+str(i)+":a]concat=n=1:v=1:a=1[vx"+str(i)+"][ax"+str(i)+"];" )
                    lastOutputVX = str("[vx"+str(i)+"]")
                    lastOutputAX = str("[ax"+str(i)+"]")
                else:
                    xFadeInfos += ( "[v"+str(i)+"][v"+str(i+1)+"]xfade=transition="+currentTransition+":duration="+transitionDuration+":offset="+offsetXfadeStart+"[vx"+str(i+1)+"];" )
                    xFadeInfos += ( "["+str(i)+":a]["+str(i+1)+":a]acrossfade=d="+transitionDuration+":c1=tri:c2=tri"+"[ax"+str(i+1)+"];" )
                    lastOutputVX = str("[vx"+str(i+1)+"]")
                    lastOutputAX = str("[ax"+str(i+1)+"]")
            elif i > 0 and i < len(allSelectedPathsList)-1 :
                xFadeInfos += ( "[vx"+str(i)+"][v"+str(i+1)+"]xfade=transition="+currentTransition+":duration="+transitionDuration+":offset="+offsetXfadeStart+"[vx"+str(i+1)+"];" )
                xFadeInfos += ( "[ax"+str(i)+"]["+str(i+1)+":a]acrossfade=d="+transitionDuration+":c1=tri:c2=tri"+"[ax"+str(i+1)+"];" )
                lastOutputVX = str("[vx"+str(i+1)+"]")
                lastOutputAX = str("[ax"+str(i+1)+"]")
        if i == len(allSelectedPathsList)-1 :
            xFadeInfos = xFadeInfos[:-1] # remove last simicolon since it is not needed
        #pyotherside.send('debugPythonLogs', xFadeInfos)
        complexFilter += ( "["+str(i)+":v]" + "scale="+targetWidth+":"+targetHeight+":force_original_aspect_ratio=decrease,pad="+targetWidth+":"+targetHeight+":(ow-iw)/2:(oh-ih)/2,setsar=1,settb=AVTB[v"+str(i)+"];" )
        previousXfadeOffset += float(offsetXfadeStart)
    # add info on how to chain these videos one after another
    complexFilter += xFadeInfos
    #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y" ] + inputFilesList + [ "-filter_complex", str(complexFilter), "-map", lastOutputVX, "-map", lastOutputAX, "-threads", "0", "-c:v", "libx264", "-preset", "veryfast", "-pix_fmt", "yuv420p", "-c:a", "aac", "/"+outputPathPy ])
    for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y" ] + inputFilesList + [ "-filter_complex", str(complexFilter), "-map", lastOutputVX, "-map", lastOutputAX, "-threads", "0", "-c:v", "mpeg4", "-preset", "veryfast", "-pix_fmt", "yuv420p", "-c:a", "aac", outputPathPy ]):
        pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('newClipCreated', outputPathPy, newFileName )


def extractImagesFunction ( ffmpeg_staticPath, inputPathPy, modeExtractImg, thumbnailSec, thumbnailSecFileName, imageInterval, origMediaFolderPath ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "extractImagesFunction"
    if "thumbnails" in modeExtractImg:
        for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vf", "fps=1/"+imageInterval, "/"+ origMediaFolderPath + "thumbnail_%04d.jpg" ]):
            pyotherside.send('progressPercentage', progress)
    elif "iFrames" in modeExtractImg:
        for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vf", "select='eq(pict_type,PICT_TYPE_I)'", "-vsync", "vfr", "/"+ origMediaFolderPath + "iframe_%04d.jpg" ]):
            pyotherside.send('progressPercentage', progress)
    elif "singleImage" in modeExtractImg:
        for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-ss", thumbnailSec, "-i", "/"+inputPathPy, "-frames:v", "1", "/"+ origMediaFolderPath + "image_" + thumbnailSecFileName + ".jpg" ]):
            pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('imagesExtracted', )






# AUDIO FUNCTIONS
# ##############################################################################################################################################################################

def audioFadeFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, fadeFrom, fadeLength, fadeDirection ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "audioFadeFunction"
    #subprocess.run([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:a", "afade=t="+fadeDirection+":st="+fadeFrom+":d="+fadeLength, "-c:v", "copy", "/"+outputPathPy ], shell = False )
    for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:a", "afade=t="+fadeDirection+":st="+fadeFrom+":d="+fadeLength, "-c:v", "copy", "/"+outputPathPy ]):
        pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )

def audioVolumeFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, actionDB, addVolumeDB, fromSec, toSec  ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "audioVolumeFunction"
    if "slider" in actionDB:
        #subprocess.run([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:a", "volume="+addVolumeDB+"dB"+":enable='between(t,"+fromSec+","+toSec+")'", "-c:v", "copy", "/"+outputPathPy ], shell = False )
        for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:a", "volume="+addVolumeDB+"dB"+":enable='between(t,"+fromSec+","+toSec+")'", "-c:v", "copy", "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
    elif "mute" in actionDB:
        #subprocess.run([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:a", "volume=enable='between(t,"+fromSec+","+toSec+")':volume=0", "-c:v", "copy", "/"+outputPathPy ], shell = False )
        for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:a", "volume=enable='between(t,"+fromSec+","+toSec+")':volume=0", "-c:v", "copy", "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
    elif "normalize" in actionDB:
        #subprocess.run([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:a", "loudnorm"+"=enable='between(t,"+fromSec+","+toSec+")'", "-c:v", "copy",  "/"+outputPathPy ], shell = False )
        for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:a", "loudnorm"+"=enable='between(t,"+fromSec+","+toSec+")'", "-c:v", "copy",  "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )

def audioExtractFunction ( ffmpeg_staticPath, inputPathPy, targetPath, targetFolderPath, targetCodec, helperPathWav, mp3CompressBitrateType, fromTimestamp, toTimestamp ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "audioExtractFunction"
    if "original" in targetCodec:
        #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vn"+":enable='between(t,"+fromSec+","+toSec+")'", "-acodec", "copy", "/"+targetPath ], shell = False )
        for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vn"+":enable='between(t,"+fromSec+","+toSec+")'", "-acodec", "copy", "/"+targetPath ]):
            pyotherside.send('progressPercentage', progress)
    else:
        #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-ss", fromTimestamp, "-to", toTimestamp, "-q:a", "0", "-map", "a", "/"+targetPath ], shell = False )
        for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-ss", fromTimestamp, "-to", toTimestamp, "-q:a", "0", "-map", "a", "/"+targetPath ]):
            pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('extractedAudio', targetPath )


def audioMixerFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, audioFilePath, origCodecAudio, fromSec, toSec, overlayDuration, volumeFactorBase, volumeFactorOver, audioDelayMS, fadeDurationIn, fadeDurationOut, currentPosition, getLengthFrom, currentFileLength ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "audioMixerFunction"
    if "betweenMarkers" in getLengthFrom:
        fadeOutStart = str(float(overlayDuration)-float(fadeDurationOut))
        #subprocess.check_call([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-stream_loop", "-1", "-i", "/"+audioFilePath, "-filter_complex", "[0:a]volume=enable='between(t,"+fromSec+","+toSec+")':volume="+volumeFactorBase+"[a_base];[1:a]atrim=start=0:end="+overlayDuration+",volume="+volumeFactorOver+",afade=t=in:st=0:d="+fadeDurationIn+",afade=t=out:st="+fadeOutStart+":d="+fadeDurationOut+",adelay="+audioDelayMS+"|"+audioDelayMS+"[a_over];[a_base][a_over]amix=inputs=2:duration=first[a_out]", "-map", "[a_out]", "-map", "0:v", "-c:a", origCodecAudio, "-c:v", "copy", "/"+outputPathPy ], shell = False )
        for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-stream_loop", "-1", "-i", "/"+audioFilePath, "-filter_complex", "[0:a]volume=enable='between(t,"+fromSec+","+toSec+")':volume="+volumeFactorBase+"[a_base];[1:a]atrim=start=0:end="+overlayDuration+",volume="+volumeFactorOver+",afade=t=in:st=0:d="+fadeDurationIn+",afade=t=out:st="+fadeOutStart+":d="+fadeDurationOut+",adelay="+audioDelayMS+"|"+audioDelayMS+"[a_over];[a_base][a_over]amix=inputs=2:duration=first[a_out]", "-map", "[a_out]", "-map", "0:v", "-c:a", origCodecAudio, "-c:v", "copy", "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
    elif "newFile" in getLengthFrom:
        durationTillEnd = float(currentFileLength) - float(currentPosition)
        lengthClip2 = float( subprocess.check_output([ "ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", "/"+audioFilePath ]) )
        insertDuration = min( durationTillEnd, lengthClip2 )
        endBaseVolumeChange = float(currentPosition) + insertDuration
        fadeOutStart = str( insertDuration -float(fadeDurationOut) )
        #subprocess.check_call([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-i", "/"+audioFilePath, "-filter_complex", "[0:a]volume=enable='between(t,"+currentPosition+","+str(endBaseVolumeChange)+")':volume="+volumeFactorBase+"[a_base];[1:a]atrim=start=0:end="+str(insertDuration)+",volume="+volumeFactorOver+",afade=t=in:st=0:d="+fadeDurationIn+",afade=t=out:st="+fadeOutStart+":d="+fadeDurationOut+",adelay="+str( float(currentPosition)*1000 )+"|"+str( float(currentPosition)*1000 )+"[a_over];[a_base][a_over]amix=inputs=2:duration=first[a_out]", "-map", "[a_out]", "-map", "0:v", "-c:a", origCodecAudio, "-c:v", "copy", "/"+outputPathPy ], shell = False )
        for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-i", "/"+audioFilePath, "-filter_complex", "[0:a]volume=enable='between(t,"+currentPosition+","+str(endBaseVolumeChange)+")':volume="+volumeFactorBase+"[a_base];[1:a]atrim=start=0:end="+str(insertDuration)+",volume="+volumeFactorOver+",afade=t=in:st=0:d="+fadeDurationIn+",afade=t=out:st="+fadeOutStart+":d="+fadeDurationOut+",adelay="+str( float(currentPosition)*1000 )+"|"+str( float(currentPosition)*1000 )+"[a_over];[a_base][a_over]amix=inputs=2:duration=first[a_out]", "-map", "[a_out]", "-map", "0:v", "-c:a", origCodecAudio, "-c:v", "copy", "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )


def recordAudioFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, audioFilePath, currentFileLength, currentPosition, origCodecAudio, fadeDurationIn, fadeDurationOut, volumeFactorBase, volumeFactorOver ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "recordAudioFunction"
    durationTillEnd = float(currentFileLength) - float(currentPosition)
    lengthClip2 = float( subprocess.check_output([ "ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", "/"+audioFilePath ]) )
    insertDuration = min( durationTillEnd, lengthClip2 )
    endBaseVolumeChange = float(currentPosition) + insertDuration
    fadeOutStart = str( insertDuration -float(fadeDurationOut) )
    #subprocess.check_call([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-i", "/"+audioFilePath, "-filter_complex", "[0:a]volume=enable='between(t,"+currentPosition+","+str(endBaseVolumeChange)+")':volume="+volumeFactorBase+"[a_base];[1:a]atrim=start=0:end="+str(insertDuration)+",volume="+volumeFactorOver+",afade=t=in:st=0:d="+fadeDurationIn+",afade=t=out:st="+fadeOutStart+":d="+fadeDurationOut+",adelay="+str( float(currentPosition)*1000 )+"|"+str( float(currentPosition)*1000 )+"[a_over];[a_base][a_over]amix=inputs=2:duration=first[a_out]", "-map", "[a_out]", "-map", "0:v", "-c:a", origCodecAudio, "-c:v", "copy", "/"+outputPathPy ], shell = False )
    for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-i", "/"+audioFilePath, "-filter_complex", "[0:a]volume=enable='between(t,"+currentPosition+","+str(endBaseVolumeChange)+")':volume="+volumeFactorBase+"[a_base];[1:a]atrim=start=0:end="+str(insertDuration)+",volume="+volumeFactorOver+",afade=t=in:st=0:d="+fadeDurationIn+",afade=t=out:st="+fadeOutStart+":d="+fadeDurationOut+",adelay="+str( float(currentPosition)*1000 )+"|"+str( float(currentPosition)*1000 )+"[a_over];[a_base][a_over]amix=inputs=2:duration=first[a_out]", "-map", "[a_out]", "-map", "0:v", "-c:a", origCodecAudio, "-c:v", "copy", "/"+outputPathPy ]):
        pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )


def audioEffectsFilters ( ffmpeg_staticPath, inputPathPy, outputPathPy, fromSec, toSec, effectTypeValue, origCodecAudio, filterType ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "audioEffectsFilters"
    if "echo" in filterType: # ffmpeg aecho does not support timeline editing yet as of Feb21
        for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:a", effectTypeValue, "-c:v", "copy", "-c:a", origCodecAudio, "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
    else:
        for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:a", effectTypeValue+":enable='between(t,"+fromSec+","+toSec+")'", "-c:v", "copy", "-c:a", origCodecAudio, "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )




# OVERLAY FUNCTIONS
# ##############################################################################################################################################################################

def addTextFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, fontPath, addText, addTextColor, addTextSize , addBox, addBoxColor, addBoxOpacity, addBoxBorderWidth, placeX, placeY, scaleDisplayFactorCrop, fromSec, toSec ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "addTextFunction"
    placeX = str(int(placeX * scaleDisplayFactorCrop))
    placeY = str(int(placeY * scaleDisplayFactorCrop))
    addBoxBorderWidth = str(int(addBoxBorderWidth * scaleDisplayFactorCrop) )
    addTextSize = str(addTextSize)
    #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vf", "drawtext=fontfile="+"/"+fontPath+":text="+addText+":fontcolor="+addTextColor+":fontsize="+addTextSize+":box="+addBox+":boxcolor="+addBoxColor+"@"+addBoxOpacity+":boxborderw="+addBoxBorderWidth+":x="+placeX+":y="+placeY+":enable='between(t,"+fromSec+","+toSec+")'", "-c:a", "copy", "/"+outputPathPy ], shell = False )
    for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vf", "drawtext=fontfile="+"/"+fontPath+":text="+addText+":fontcolor="+addTextColor+":fontsize="+addTextSize+":box="+addBox+":boxcolor="+addBoxColor+"@"+addBoxOpacity+":boxborderw="+addBoxBorderWidth+":x="+placeX+":y="+placeY+":enable='between(t,"+fromSec+","+toSec+")'", "-c:a", "copy", "/"+outputPathPy ]):
        pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )


def overlayOldMovieFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, tempMediaFolderPath, origVideoWidth, origVideoHeight, origContainer, pathOverlayVideo, fromSec, toSec, overlayDuration ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "overlayOldMovieFunction"
    origVideoWidth = str(origVideoWidth)
    origVideoHeight = str(origVideoHeight)
    for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-stream_loop", "-1", "-i", "/"+pathOverlayVideo, "-i", "/"+inputPathPy, "-filter_complex", "[0]scale="+origVideoWidth+":"+origVideoHeight+",setsar=1:1,trim=duration="+overlayDuration+",setpts=PTS-STARTPTS+"+fromSec+"/TB,format=rgba,colorchannelmixer=aa=0.25[fg];[1][fg]overlay=enable='between(t,"+fromSec+","+toSec+")'[out]", "-map", "[out]", "-map", "1:a", "-c:a", "copy", "/"+outputPathPy ]):
        pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )


def overlayAlphaClipFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, overlayPath, origVideoWidth, origVideoHeight, colorKey, overlayOpacity, fromSec, toSec, overlayDuration, applyStretch, placeX, placeY, overlayWidth, overlayHeight, scaleDisplayFactorCrop, previewAlphaType ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "overlayAlphaClipFunction"
    origVideoWidth = str(origVideoWidth)
    origVideoHeight = str(origVideoHeight)
    outX = str(int(placeX * scaleDisplayFactorCrop))
    outY = str(int(placeY * scaleDisplayFactorCrop))
    outW = str(int(overlayWidth * scaleDisplayFactorCrop))
    outH = str(int(overlayHeight * scaleDisplayFactorCrop))
    if "stretch" in applyStretch:
        if "video" in previewAlphaType:
            #subprocess.run([ "ffmpeg", "-hide_banner", "-y", "-stream_loop", "-1", "-i", "/"+overlayPath, "-i", "/"+inputPathPy, "-filter_complex", "[0]scale="+origVideoWidth+":"+origVideoHeight+",setsar=1:1,trim=duration="+overlayDuration+",setpts=PTS-STARTPTS+"+fromSec+"/TB,format=rgba,colorkey="+colorKey+",colorchannelmixer=aa="+overlayOpacity+"[fg];[1][fg]overlay=enable='between(t,"+fromSec+","+toSec+")'[out]", "-map", "[out]", "-map", "1:a", "-c:a", "copy", "/"+outputPathPy ], shell = False )
            for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-stream_loop", "-1", "-i", "/"+overlayPath, "-i", "/"+inputPathPy, "-filter_complex", "[0]scale="+origVideoWidth+":"+origVideoHeight+",setsar=1:1,trim=duration="+overlayDuration+",setpts=PTS-STARTPTS+"+fromSec+"/TB,format=rgba,colorkey="+colorKey+",colorchannelmixer=aa="+overlayOpacity+"[fg];[1][fg]overlay=enable='between(t,"+fromSec+","+toSec+")'[out]", "-map", "[out]", "-map", "1:a", "-c:a", "copy", "/"+outputPathPy ]):
                pyotherside.send('progressPercentage', (progress * 2) )
        else: # "image"
            for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-loop", "1", "-i", "/"+overlayPath, "-i", "/"+inputPathPy, "-filter_complex", "[0]scale="+origVideoWidth+":"+origVideoHeight+":flags=lanczos,setsar=1:1,trim=duration="+overlayDuration+",setpts=PTS-STARTPTS+"+fromSec+"/TB,format=rgba,colorkey="+colorKey+",colorchannelmixer=aa="+overlayOpacity+"[fg];[1][fg]overlay=enable='between(t,"+fromSec+","+toSec+")'[out]", "-map", "[out]", "-map", "1:a", "-c:a", "copy", "/"+outputPathPy ]):
                pyotherside.send('progressPercentage', (progress * 2) )
    else: # "noStretch"
        if "video" in previewAlphaType:
            for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-stream_loop", "-1", "-i", "/"+overlayPath, "-i", "/"+inputPathPy, "-filter_complex", "[0]scale="+outW+":"+outH+",setsar=1:1,trim=duration="+overlayDuration+",setpts=PTS-STARTPTS+"+fromSec+"/TB,format=rgba,colorkey="+colorKey+",colorchannelmixer=aa="+overlayOpacity+"[fg];[1][fg]overlay="+outX+":"+outY+":enable='between(t,"+fromSec+","+toSec+")'[out]", "-map", "[out]", "-map", "1:a", "-c:a", "copy", "/"+outputPathPy ]):
                pyotherside.send('progressPercentage', (progress * 2) )
        else: # "image"
            for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-loop", "1", "-i", "/"+overlayPath, "-i", "/"+inputPathPy, "-filter_complex", "[0]scale="+outW+":"+outH+":flags=lanczos,setsar=1:1,trim=duration="+overlayDuration+",setpts=PTS-STARTPTS+"+fromSec+"/TB,format=rgba,colorkey="+colorKey+",colorchannelmixer=aa="+overlayOpacity+"[fg];[1][fg]overlay="+outX+":"+outY+":enable='between(t,"+fromSec+","+toSec+")'[out]", "-map", "[out]", "-map", "1:a", "-c:a", "copy", "/"+outputPathPy ]):
                pyotherside.send('progressPercentage', (progress * 2) )
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )
        pyotherside.send('switchToAlphaFullScreen', )


def overlayFileFunction ( ffmpeg_staticPath, inputPathPy, outputPathPy, overlayPath, fromSec, toSec, placeX, placeY, overlayWidth, overlayHeight, scaleDisplayFactorCrop, overlayOpacity, overlayType, overlayDuration, drawRectangleColor, drawRectangleThickness ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "overlayFileFunction"
    outX = str(int(placeX * scaleDisplayFactorCrop))
    outY = str(int(placeY * scaleDisplayFactorCrop))
    outW = str(int(overlayWidth * scaleDisplayFactorCrop))
    outH = str(int(overlayHeight * scaleDisplayFactorCrop))
    if "image" in overlayType:
        for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-i", "/"+inputPathPy, "-i", "/"+overlayPath, "-filter_complex", "[1]scale="+outW+":"+outH+",setsar=1:1,format=rgba,colorchannelmixer=aa="+overlayOpacity+"[fg];[0][fg]overlay="+outX+":"+outY+":enable='between(t,"+fromSec+","+toSec+")'"+"[out]", "-map", "[out]", "-map", "0:a", "-c:a", "copy", "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
        pyotherside.send('clearOverlayFilename', outputPathPy )
    elif "video" in overlayType:
        for progress in run_ffmpeg_command([ "ffmpeg", "-hide_banner", "-y", "-stream_loop", "-1", "-i", "/"+overlayPath, "-i", "/"+inputPathPy, "-filter_complex", "[0]scale="+outW+":"+outH+",setsar=1:1,format=rgba,trim=duration="+overlayDuration+",setpts=PTS-STARTPTS+"+fromSec+"/TB,colorchannelmixer=aa="+overlayOpacity+"[fg];[1][fg]overlay="+outX+":"+outY+":enable='between(t,"+fromSec+","+toSec+")'[out]", "-map", "[out]", "-map", "1:a", "-c:a", "copy", "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
        pyotherside.send('clearOverlayFilename', outputPathPy )
    elif "rectangle" in overlayType:
        for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-vf", "drawbox=enable='between(t,"+fromSec+","+toSec+")'"+":x="+outX+":y="+outY+":w="+outW+":h="+outH+":color="+drawRectangleColor+"@"+overlayOpacity+":t="+drawRectangleThickness, "-c:a", "copy", "/"+outputPathPy ]):
            pyotherside.send('progressPercentage', progress)
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )


def overlaySubtitleFunction ( ffmpeg_staticPath, inputPathPy, tempMediaFolderPath, outputPathPy, subtitlePath, addSubtitleContainer, addMethod, createTextfile, textFileText ):
    global success
    global currentFunctionErrorName
    currentFunctionErrorName = "overlaySubtitleFunction"

    if "true" in createTextfile:
        with open("/"+subtitlePath, "w", encoding="utf8") as srtFile:
            srtFile.writelines(textFileText)
    if "burn" in addMethod:
        if "srt" in addSubtitleContainer:
            #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "subtitles="+"/"+subtitlePath, "/"+outputPathPy ], shell = False )
            for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "subtitles="+"/"+subtitlePath, "/"+outputPathPy ]):
                pyotherside.send('progressPercentage', progress)
        elif "ass" in addSubtitleContainer:
            #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "ass="+"/"+subtitlePath, "/"+outputPathPy ], shell = False )
            for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-filter:v", "ass="+"/"+subtitlePath, "/"+outputPathPy ]):
                pyotherside.send('progressPercentage', progress)
    elif "selectable" in addMethod:
        if "srt" in addSubtitleContainer:
            #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-sub_charenc", "UTF-8", "-f", "srt", "-i", "/"+subtitlePath, "-map", "0:0", "-map", "0:1", "-map", "1:0", "-c:v", "copy", "-c:a", "copy", "-c:s", "srt", "/"+outputPathPy ], shell = False )
            for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-sub_charenc", "UTF-8", "-f", "srt", "-i", "/"+subtitlePath, "-map", "0:0", "-map", "0:1", "-map", "1:0", "-c:v", "copy", "-c:a", "copy", "-c:s", "srt", "/"+outputPathPy ]):
                pyotherside.send('progressPercentage', progress)

        if "ass" in addSubtitleContainer:
            #subprocess.run([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-sub_charenc", "UTF-8", "-f", "ass", "-i", "/"+subtitlePath, "-map", "0:0", "-map", "0:1", "-map", "1:0", "-c:v", "copy", "-c:a", "copy", "-c:s", "ass", "/"+outputPathPy ], shell = False )
            for progress in run_ffmpeg_command([ ffmpeg_staticPath, "-hide_banner", "-y", "-i", "/"+inputPathPy, "-sub_charenc", "UTF-8", "-f", "ass", "-i", "/"+subtitlePath, "-map", "0:0", "-map", "0:1", "-map", "1:0", "-c:v", "copy", "-c:a", "copy", "-c:s", "ass", "/"+outputPathPy ]):
                pyotherside.send('progressPercentage', progress)
    for i in os.listdir( "/"+tempMediaFolderPath ) :
        if (i.find(".srt") != -1):
            os.remove ( "/"+tempMediaFolderPath+i )
            pyotherside.send('tempFilesDeleted', i )
    if "true" in success :
        pyotherside.send('loadTempMedia', outputPathPy )




def parseSubtitleFile ( ffmpeg_staticPath, subtitlePath ):
    '''
    # ToDo: finish how to put text lines together and push it to QML where it creates models
    linesList = []
    linesList.clear()
    # tmp lists
    numberList = []
    numberList.clear()
    timeList = []
    timeList.clear()
    textList = []
    textList.clear()
    tempText = ""
    with open("/"+subtitlePath, "r") as srtFile:
        linesList = srtFile.readlines()
    for i in range(len(linesList)):
        linesList[i] = linesList[i].strip()                                                 # strips newline character
        if linesList[i].isdigit():                                                          # is there a single new scene number?
            tempText = ""
        elif (re.match('\d{2}:\d{2}:\d{2}', linesList[i] )) and ( "-->" in linesList[i] ):  # is there a scene time stamp, pack all following texts together?
            tempText = ""
        elif len(linesList[i]) == 0:                                                        # is there an empty line deviding scenes?
            tempText = ""
        else:                                                                                # must be output text for this scene
            if (len(linesList[i+1]) == 0) or (i = len(linesList)) :
                tempText = linesList[i]
                textList.append(tempText)
            else:
                tempText += linesList[i] + "\n"

        if sameScene is False:

    pyotherside.send('debugPythonLogs', linesList)
    pyotherside.send('debugPythonLogs', textList)
    '''
    with open("/"+subtitlePath, "r") as srtFile:
        subtitleText = srtFile.read()
    pyotherside.send('subtitleFileParsed', subtitleText)


# other useful commands
#pyotherside.send('debugPythonLogs', i)
#subprocess.Popen([ "parec", "-d", inputDevice, "--file-format=wav", "/"+recordAudioPath ], shell = False )
#subprocess.run([ "killall", "-r", "parec" ])


# PARSE FFMPEG OUTPUT FUNCTIONS
# ##############################################################################################################################################################################
DUR_REGEX = re.compile( r"Duration: (?P<hour>\d{2}):(?P<min>\d{2}):(?P<sec>\d{2})\.(?P<ms>\d{2})" )
TIME_REGEX = re.compile( r"out_time=(?P<hour>\d{2}):(?P<min>\d{2}):(?P<sec>\d{2})\.(?P<ms>\d{2})" )
def to_ms(s=None, des=None, **kwargs) -> float:
    if s:
        hour = int(s[0:2])
        minute = int(s[3:5])
        sec = int(s[6:8])
        ms = int(s[10:11])
    else:
        hour = int(kwargs.get("hour", 0))
        minute = int(kwargs.get("min", 0))
        sec = int(kwargs.get("sec", 0))
        ms = int(kwargs.get("ms", 0))
    result = (hour * 60 * 60 * 1000) + (minute * 60 * 1000) + (sec * 1000) + ms
    if des and isinstance(des, int):
        return round(result, des)
    return result

# Run an ffmpeg command, trying to capture the process output and calculate the duration / progress. Yields the progress in percent.
def run_ffmpeg_command(cmd: "list[str]") -> Iterator[int]:
    global currentFunctionErrorName
    global success
    total_dur = None
    cmd_with_progress = [cmd[0]] + ["-progress", "-", "-nostats"] + cmd[1:]

    #pyotherside.send('cmd_wth:', cmd_with_progress)

    stderr = []
    stderr.clear()
    success = "false"
    p = subprocess.Popen( cmd_with_progress, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=False, )
    while True:
        line = p.stdout.readline().decode("utf8", errors="replace").strip()

        #pyotherside.send('runDebug_', line)

        if line == "" and p.poll() is not None:
            break
        stderr.append(line.strip())

        if not total_dur and DUR_REGEX.search(line):
            total_dur = DUR_REGEX.search(line).groupdict()
            total_dur = to_ms(**total_dur)
            continue
        if total_dur:
            result = TIME_REGEX.search(line)
            if result:
                elapsed_time = to_ms(**result.groupdict())
                yield int(elapsed_time / total_dur * 100)
    if p.returncode != 0:
        success = "false"

        # pkill not allowed
        #subprocess.run([ "pkill", "-f", "ffmpeg" ])

        if "imageLUT3DFunction" in currentFunctionErrorName:
            pyotherside.send('errorOccured', "PNG not compatible.\nConversion failed." )
        elif "overlayOldMovieFunction" in currentFunctionErrorName:
            pyotherside.send('errorOccured', "Sorry, this file might be too large." )
        elif "padAreaFunction" in currentFunctionErrorName:
            pyotherside.send('errorOccured', "Sorry, this file might be too large." )
        else:
            pyotherside.send('errorOccured', "An error occured with this function.\n"  + currentFunctionErrorName + "\nKindly report this bug on github." )
    else:
        success = "true"
        # not allowed
        #subprocess.run([ "pkill", "-f", "ffmpeg" ])
    yield 100






