# -*- coding: utf-8 -*-

import time
import os
import subprocess, signal
import random
import ffmpeg
from pathlib import Path

# other for progressbar
import re
#from collections.abc import Iterator
from typing import Iterator


# global variables
currentFunctionErrorName = ""
success = "false"

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

# Run ffmpeg command with ffmpeg-python
def runFF(video,audio,outputpath):
    total_dur = None
    stderr = []
    stderr.clear()
    success = "false"
    out = ffmpeg.output( video, audio, outputpath)
#   out.global_args('-progress - -nostats -hide_banner')
    proc = out.run_async()

    while True:
        line = proc.stdout.readline().decode("utf8", errors="replace").strip()
        if line == "" and proc.poll() is not None:
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

    if proc.returncode != 0:
        success = "false"
    else:
        success = "true"
    yield 100

'''
    output_kwargs.update ({"c:v": "libx264",
                           "b:v": "%dM" %(bitrate),
                           "pix_fmt": "yuv420p",
                          })

if include_audio and ref_in_a is not None:
    output_kwargs.update ({"c:a": "aac",
                           "b:a": "192k",
                           "ar" : "48000",
                           "strict": "experimental"
                           })
ffmpeg-python example
'''

in1 = ffmpeg.input('one.mp4')

probe = ffmpeg.probe('one.mp4')
time =  float(probe['format']['duration'])
in2 = ffmpeg.input('two.mp4')
in3 = ffmpeg.input('three.mp4')
#v1 = in1.video.hflip()
#v1 = in1.video
#a1 = in1.audio
#v2 = in2.video
#a2 = in2.audio
#v2 = in2.video.filter('reverse').filter('hue', s=0)
#a2 = in2.audio.filter('areverse').filter('aphaser')
#joined = ffmpeg.concat(v1, a1, v2, a2, v=1, a=1).node
#v3 = joined[0]
#a3 = joined[1]
#.filter('volume', 0.8)
#out = ffmpeg.output(v3, a3, outputPathPy)

#filter audio and video
video1 = ffmpeg.filter([in1, in2], 'xfade', transition='dissolve', duration=1, offset=time-1)
audio1 = ffmpeg.filter([in1, in2], 'acrossfade', d=1)

#out = ffmpeg.concat(video, audio, v=1, a=1).output('out.mp4')
#out = ffmpeg.output( video, audio, 'out.mp4')
#proc = out.run_async()

#for progress in runFF(video,audio,'out.mp4'):
#    print(progress)




