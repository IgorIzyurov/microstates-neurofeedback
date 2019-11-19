BergenToolboxModified
=====================

So this is the Bergen EEG MRI-correction toolbox, with several modifications

1) It now works, or at least, the thing Moosman published (using motion params to more cleverly select your volume templates)

2) It annotates the data with a separate boolean data matrix; bad template correlation, outside-of-measurement data points, templates that were NOT selected, etc.

3) It tries to reduce effect for clipping a little bit, and also annotates the data where clipping occurred. Detection is automatic.
