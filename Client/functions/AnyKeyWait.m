function [] = AnyKeyWait(allkeys)
% Script for pressing any key
% for Fiber Optic Responce Pad we need more precise press check, than KbCheck() or KbWait() allows:
KbQueueCreate([],allkeys);
KbQueueStart;
KbQueueWait;
KbQueueRelease;
WaitSecs(0.2);