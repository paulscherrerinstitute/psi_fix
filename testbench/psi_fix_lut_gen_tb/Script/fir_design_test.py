# =================================================================
#	Paul Scherrer Institut <PSI> Villigen, Schweiz
# 	Copyright ©, 2018, Benoit STEF, all rights reserved
# =================================================================
# Purpose   :
# Author    : Benoît STEF - SB82 DSV group 8221 @PSI WBBA/302
# Project   :
# Used in   : HIPA Upgrade Inj2 LLRF
# HDL file  :
# ==================================================================
from psi_fix_pkg import *
import numpy as np
from psi_fix_pkg import *
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

#Dsign filter coeffcient

n = 61
a = signal.firwin(n, cutoff = 0.3, window = "hamming")
print(a)

#Frequency and phase response
figure(1)
mfreqz(a)
figure(2)
impz(a)

#generate VHDL file coefficient with cfg setting
coefFmt  = PsiFixFmt(1,0,15)
rstPol   = 1
fileName = "psi_fix_lut_test1"
romStyle = "block"

cfgLut = psi_fix_lut_cfg_settings(coefFmt,rstPol,fileName,romStyle)
psi_fix_lut(cfgLut,a,"../")

show()