########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Benoit Stef
########################################################################################################################
import sys
sys.path.append("../../../model")
from pylab import *
import scipy.signal as signal
from psi_fix_lut import *

#Plot frequency and phase response
def mfreqz(b,a=1):
    w,h = signal.freqz(b,a)
    h_dB = 20 * log10 (abs(h))
    ax = subplot(211)
    plot(w/max(w),h_dB)
    ylim(-150, 5)
    ylabel('Magnitude (db)')
    xlabel(r'Normalized Frequency (x$\pi$rad/sample)')
    title(r'Frequency response')
    ax.grid(True)
    bx = subplot(212)
    h_Phase = unwrap(arctan2(imag(h),real(h)))
    plot(w/max(w),h_Phase)
    ylabel('Phase (radians)')
    xlabel(r'Normalized Frequency (x$\pi$rad/sample)')
    title(r'Phase response')
    bx.grid(True)
    subplots_adjust(hspace=0.5)

# Plot step and impulse response
def impz(b, a=1):
    l = len(b)
    impulse = repeat(0., l);
    impulse[0] = 1.
    x = arange(0, l)
    response = signal.lfilter(b, a, impulse)
    ax = subplot(211)
    stem(x, response)
    ylabel('Amplitude')
    xlabel(r'n (samples)')
    title(r'Impulse response')
    ax.grid(True)
    bx = subplot(212)
    step = cumsum(response)
    stem(x, step)
    ylabel('Amplitude')
    xlabel(r'n (samples)')
    title(r'Step response')
    bx.grid(True)
    subplots_adjust(hspace=0.5)


PLOT_ON = False

### Stimuli location
STIM_DIR = os.path.dirname(os.path.abspath(__file__)) + "/../../psi_fix_lut_gen_tb/Data/"
try:
    os.mkdir(STIM_DIR)
except FileExistsError:
    pass


n = 61
a = signal.firwin(n, cutoff = 0.3, window = "hamming")
print(a)

#Frequency and phase response
if PLOT_ON:
    figure(1)
    mfreqz(a)
    figure(2)
    impz(a)

#generate VHDL file coefficient with cfg setting
coefFmt  = PsiFixFmt(1,0,15)
fileName = "psi_fix_lut_test1"
path     = "../"

cfg = psi_fix_lut(a,coefFmt)
c = psi_fix_lut.Process(cfg,np.arange(np.size(a)))
np.savetxt(STIM_DIR + 'model.txt', PsiFixGetBitsAsInt(c,coefFmt), fmt='% i', newline='\n', header='model')
print(c)

psi_fix_lut.Generate(cfg,path,fileName)

#show()
