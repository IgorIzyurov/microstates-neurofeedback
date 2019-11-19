# -*- coding: utf-8 -*-
"""
Created on Fri Nov 30 11:39:19 2018

@author: Igor
"""

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Nov 29 10:25:54 2018

@author: nfcontrol
"""



# import statements - all of these are packages within the rt environment
import time
from random import random as rand

import sys
import numpy as np 
import matplotlib
import matplotlib.pyplot as plt


import re  # regular expressions
import pickle  # to save/load data
import dynarray  # a growing numpy array
import mne  # EEGLAB for python


# amplifier driver
#sys.path.append("./mushu")
sys.path.append("C:/Users/Igor/Documents/WERK/Neurofeedback/EEG_Neurofeedback_dev/EEG-NF/MRcorrection_Johan/mushu")
import libmushu

import pylsl
from pylsl import StreamInfo, StreamOutlet,StreamInlet, resolve_stream


import pdb

# import scipy
# from scipy imposrt signal

# from collections import deque  # a FILO list useful for plotting!

# the real-time signal filters:
from rtfilters import HPF, LPF, BPF, MR, CWL

print('line 45 reached')
nbchan=72  # you need to adjust to what your amp is producing!!
fs=5000
TR=1.800
trsamples=int(TR*fs);
# you need to change the # of channels here, most likely
hpf=HPF(f=1.0, fs=fs, order=3, nbchan=nbchan);
lpf=LPF(f=1.0, fs=fs, order=3, nbchan=nbchan);
bpf=BPF(f=[12.0, 15.0], fs=fs, order=3, nbchan=nbchan);
#mr=MR(trsamples=10000, N_thr=5, corr_thr = 0.995, forget=6)
#mr=MR(trsamples=trsamples, N_thr=5, corr_thr = 0.995, forget=5, highpass=[3, 1.0, fs]);
mr=MR(trsamples=trsamples, N_thr=5, corr_thr = 0.995, forget=5, highpass=[]);


# first resolve an EEG stream on the lab network
print("looking for an EEG stream...")
streams = resolve_stream('type', 'EEG')

# create a new inlet to read from the stream
inlet = StreamInlet(streams[0])

# if you wish to change settings - look in mushu/libmushu/drivers/labstreaminglayer.py
# you can use the python API of labstreaminglayer to fix things there
# https://github.com/labstreaminglayer/liblsl-Python/tree/b158b57f66bc82230ff5ad0433fbd4480766a849


# make a new LSL stream to send data away:
# first create a new stream info (here we set the name to BioSemi,
# the content-type to EEG, 8 channels, 100 Hz, and float-valued data) The
# last value would be the serial number of the device or some other more or
# less locally unique identifier for the stream as far as available (you
# could also omit it but interrupted connections wouldn't auto-recover)
infoNoise = StreamInfo('EEG-MR-noise', 'EEG-MR-noise', nbchan, fs, 'double64', 'uncorrected')
outletNoise = StreamOutlet(infoNoise)
infoClean = StreamInfo('EEG-MR-clean', 'EEG-MR-clean', nbchan, fs, 'double64', 'corrected')
outletClean = StreamOutlet(infoClean)




print("looking for a marker stream...")
streamsMarkers = resolve_stream('type', 'Markers')

# create a new inlet to read from the stream
inletMarkers = StreamInlet(streamsMarkers[0])


#        print(timestamps, chunk)


print('start receiving')
while True:
#    marker, marker_timestamp = inletMarkers.pull_sample()
#    print("got %s at time %s" % (marker[0], marker_timestamp))
    data, timestamps = inlet.pull_chunk()
    # it doesn't make sense to do stuff, if theere is no data
    if len(data) > 0:
#        data, marker = amp.get_data()
#        data2=hpf.handle(data)
        data3=mr.handle(data)
        outletClean.push_chunk(data3.tolist())
#        outletClean.push_chunk(data3)
        outletNoise.push_chunk(data)
    

    
        

