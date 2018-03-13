## Statistical Analysis as a Tool for Marching Band Drum Core Practice Improvement  

**Objective**  
I have been recording my snare practice sessions for the past 6 months.  I am attempting to do statistical analysis of the digital signals of the recordings looking at attributes such as amplitude pitch, phase, and tempo.  The goal is to be able to identify improvements using statistical tools like "R".  This is a great presentation for students.

**Prerequisites** 
 
* Python 2.7.10
* pip 9.0.1
* Aubio 0.4.6
* git version 2.11.0 (for Apple Git-81)
* RStudio 1.1.423


#### Installation Prep

Install Aubio:  

```

sudo easy_install pip

sudo pip install aubio

python -c "import aubio; print(aubio.version)”

```

####git clone the Aubio project (Python demos are in python/demos)  

Use this comand to download the aubio project.  With Github you can contrute your changes to the project. However, you will have to take a "learning Git" basics course. However, if you just want to make your own copy for now use the git clone command

`git clone https://github.com/aubio/aubio.git`

#### Refference Sites

https://github.com/aubio/aubio

http://whatis.techtarget.com/definition/Nyquist-Theorem)

https://www.sweetwater.com/insync/7-things-about-sample-rate/

https://manual.audacityteam.org/man/glossary.html

#### Getting Started  

Get source information from the audio file (dlw_source.py).  This Python program imports the aubio libraru and uses the source opject to read the samplerate and hop_size and calculates the total_frames in the AIFF or MP# file. 

```
#! /usr/bin/env python

import sys
from aubio import source

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('usage: %s <inputfile> [samplerate] [hop_size]' % sys.argv[0])
        sys.exit(1)
    samplerate = 0
    hop_size = 256
    if len(sys.argv) > 2: samplerate = int(sys.argv[2])
    if len(sys.argv) > 3: hop_size = int(sys.argv[3])

    f = source(sys.argv[1], samplerate, hop_size)
    samplerate = f.samplerate

    total_frames, read = 0, f.hop_size
    while read:
        vec, read = f()
        total_frames += read
        if read < f.hop_size: break
    outstr = "%.2fs" % (total_frames / float(samplerate))
    outstr += ",%d" % total_frames
    outstr += ",%d" % (total_frames // f.hop_size)
    outstr += ",%dHz" % f.samplerate
    outstr += "," + f.uri
    print(outstr)
```
This is a simple shell script to loop through all the Audion files and get source information into a csv file.

```
cd audio_files

echo "read,frames,blocks,samplerate,file" >../reports/source.csv ;

for i in `ls | sort -n`
do
  ../python/dlw_source.py $i >>../reports/source.csv
done  
```

In RStudio import in the source.csv file

```
source <- read.csv("~/Documents/SCALE-2018-Daniel/reports/source.csv")

View(source)  

```

In RStudio code to anaylze the source.csv data

```
plot(source$read)
plot(source$frames)
summary(source$frames)
```

#### Analyzing Tempo and Beats

Get tempo information from the audio file (dlw_tempo.py)

```
#! /usr/bin/env python

import sys
from aubio import tempo, source
from numpy import mean, median, diff

win_s = 512                 # fft size
hop_s = win_s // 2          # hop size

if len(sys.argv) < 2:
    print("Usage: %s <filename> [samplerate]" % sys.argv[0])
    sys.exit(1)

filename = sys.argv[1]

samplerate = 0
if len( sys.argv ) > 2: samplerate = int(sys.argv[2])

s = source(filename, samplerate, hop_s)
samplerate = s.samplerate
o = tempo("default", win_s, hop_s, samplerate)

# tempo detection delay, in samples
# default to 4 blocks delay to catch up with
delay = 4. * hop_s

# list of beats, in samples
beats = []

# total number of frames read
total_frames = 0
while True:
    samples, read = s()
    print("samples=",samples)
    is_beat = o(samples)
    if is_beat:
        print("is_beat = ",is_beat)
        this_beat = int(total_frames - delay + is_beat[0] * hop_s)
        print("%f" % (this_beat / float(samplerate)))
        beats.append(this_beat)
    total_frames += read
    if read < hop_s: break
# Troubleshoting
#bpms = 60./ diff(beats)
#print(bpms)
#print len(beats)
```

Get Tempo information from an audio files to compare (day1,day54 and baseline) 

```
../python/dlw_tempo.py 2.aiff 

../python/dlw_tempo.py 54.aiff

../python/dlw_tempo.py ../baseline-120.aiff

```

#### Analyzing Tempo and Beats

Plotting tempo information from the audio file (dlw_tempo_plot.py)

```
#! /usr/bin/env python

import sys
from aubio import tempo, source

win_s = 512                 # fft size
hop_s = win_s // 2          # hop size

if len(sys.argv) < 2:
    print("Usage: %s <filename> [samplerate]" % sys.argv[0])
    sys.exit(1)

filename = sys.argv[1]

samplerate = 0
if len( sys.argv ) > 2: samplerate = int(sys.argv[2])

s = source(filename, samplerate, hop_s)
samplerate = s.samplerate
o = tempo("default", win_s, hop_s, samplerate)

# tempo detection delay, in samples
# default to 4 blocks delay to catch up with
delay = 4. * hop_s

# list of beats, in samples
beats = []

# total number of frames read
total_frames = 0
while True:
    samples, read = s()
    is_beat = o(samples)
    if is_beat:
        this_beat = o.get_last_s()
        beats.append(this_beat)
    total_frames += read
    if read < hop_s: break

if len(beats) > 1:
    # do plotting
    from numpy import mean, median, diff
    import matplotlib.pyplot as plt
    bpms = 60./ diff(beats)
    print(bpms)
    print('mean period: %.2fbpm, median: %.2fbpm' % (mean(bpms), median(bpms)))
    print('plotting %s' % filename)
    plt1 = plt.axes([0.1, 0.75, 0.8, 0.19])
    plt2 = plt.axes([0.1, 0.1, 0.8, 0.65], sharex = plt1)
    plt.rc('lines',linewidth='.8')
    for stamp in beats: plt1.plot([stamp, stamp], [-1., 1.], '-r')
    plt1.axis(xmin = 0., xmax = total_frames / float(samplerate) )
    plt1.xaxis.set_visible(False)
    plt1.yaxis.set_visible(False)

    # plot actual periods
    plt2.plot(beats[1:], bpms, '-', label = 'raw')

    # plot moving median of 5 last periods
    median_win_s = 5
    bpms_median = [ median(bpms[i:i + median_win_s:1]) for i in range(len(bpms) - median_win_s ) ]
    plt2.plot(beats[median_win_s+1:], bpms_median, '-', label = 'median of %d' % median_win_s)
    # plot moving median of 10 last periods
    median_win_s = 20
    bpms_median = [ median(bpms[i:i + median_win_s:1]) for i in range(len(bpms) - median_win_s ) ]
    plt2.plot(beats[median_win_s+1:], bpms_median, '-', label = 'median of %d' % median_win_s)

    plt2.axis(ymin = min(bpms), ymax = max(bpms))
    #plt2.axis(ymin = 40, ymax = 240)
    plt.xlabel('time (mm:ss)')
    plt.ylabel('beats per minute (bpm)')
    plt2.set_xticklabels([ "%02d:%02d" % (t/60, t%60) for t in plt2.get_xticks()[:-1]], rotation = 50)

    #plt.savefig('/tmp/t.png', dpi=200)
    plt2.legend()
    plt.show()

else:
    print('mean period: %.2fbpm, median: %.2fbpm' % (0, 0))
    print('plotting %s' % filename)
    
```
 
 Plot Tempo information from an audio files to compare  

```
../python/dlw_tempo_plot.py 2.aiff 

../python/dlw_tempo_plot.py 54.aiff

../python/dlw_tempo_plot.py ../baseline-120.aiff

```

