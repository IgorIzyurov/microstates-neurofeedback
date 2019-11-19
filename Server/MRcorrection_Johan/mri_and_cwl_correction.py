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
sys.path.append("./mushu")
sys.path.append("C:/Users/EEG-Neurofeedback/Desktop/EEG-NF_clientserver/Server/MRcorrection_Johan/mushu")
sys.path.append('C:/Users/EEG-Neurofeedback/Desktop/EEG-NF_clientserver/Server/MRcorrection_Johan/mushu/libmushu/driver/')
import libmushu
from labstreaminglayer import LSLAmp


import pylsl
from pylsl import StreamInfo, StreamOutlet

import ipdb










# import scipy
# from scipy imposrt signal

# from collections import deque  # a FILO list useful for plotting!

# the real-time signal filters:
from rtfilters import HPF, LPF, BPF, MR, CWL, RESAMPLESAFE

nbchan=72  # you need to adjust to what your amp is producing!!
fs=5000
TR=1.800
trsamples=int(TR*fs)

EEG_channels = [0 + i for i in range(64)]
CWL_channels = [68 + i for i in range(4)]
fs_resampled = 500
# you need to change the # of channels here, most likely
hpf=HPF(f=1, fs=fs, order=3, nbchan=nbchan)
lpf=LPF(f=125, fs=fs, order=3, nbchan=nbchan)
resample=RESAMPLESAFE(fs_source=fs, fs_target=fs_resampled)
bpf=BPF(f=[2.0, 20.0], fs=fs, order=3, nbchan=nbchan)

cwl=CWL(seconds_in_window=6.0, tdelay=0.050, ichs=EEG_channels, icws=CWL_channels, fs=fs_resampled, highpass=[], saveglms=False)

mr=MR(trsamples=trsamples, N_thr=5, corr_thr = 0.995, forget=5, highpass=[]);
#mr=MR(trsamples=10000, N_thr=5, corr_thr = 0.995, forget=6)
#mr=MR(trsamples=trsamples, N_thr=5, corr_thr = 0.995, forget=5, highpass=[3, 1.0, fs]);



# make an 'amp' that reads in the data stream (LSL)
#amp = libmushu.get_amp('lslamp')
#amp = libmushu.get_amp('bpamp')

amp=LSLAmp()

amp.configure()


# ipdb.set_trace()
# amp.configure() # this sets up the LSL making us able to use it
# if you wish to change settings - look in mushu/libmushu/drivers/labstreaminglayer.py
# you can use the python API of labstreaminglayer to fix things there
# https://github.com/labstreaminglayer/liblsl-Python/tree/b158b57f66bc82230ff5ad0433fbd4480766a849


# make a new LSL stream to send data away:
# first create a new stream info (here we set the name to BioSemi,
# the content-type to EEG, 8 channels, 100 Hz, and float-valued data) The
# last value would be the serial number of the device or some other more or
# less locally unique identifier for the stream as far as available (you
# could also omit it but interrupted connections wouldn't auto-recover)
infoCWL = StreamInfo('EEG-MR-CWL', 'EEG-MR-CWL', nbchan, fs_resampled, 'double64', 'corrected')
infoMR = StreamInfo('EEG-MR', 'EEG-MR', nbchan, fs_resampled, 'double64', 'uncorrected')


outletCWL = StreamOutlet(infoCWL)
outletMR = StreamOutlet(infoMR)

# ipdb.set_trace()
amp.start()
amp.get_sampling_frequency()
print(amp.get_sampling_frequency())
print('acquisition started. MR and CWL correction. Resampling to 500 Hz, bandpassing to 1-125 Hz.')
while True:
    data, marker = amp.get_data()
    # it doesn't make sense to do stuff, if theere is no data
    if data.shape[0] > 0:
        data2=hpf.handle(data)
        data3=mr.handle(data2)
        data4=lpf.handle(data3)
        data5=resample.handle(data4)
        data6=cwl.handle(data5)
                
    
    
        # send it away - you'd need to figure out whether to seond data
        # or transposed data (i.e. data.T)
        # pdb.set_trace()
        outletCWL.push_chunk(data6.tolist())
        outletMR.push_chunk(data5.tolist())
    
        

