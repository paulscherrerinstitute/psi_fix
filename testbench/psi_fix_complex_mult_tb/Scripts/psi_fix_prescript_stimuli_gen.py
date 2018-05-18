#=================================================================
#	Paul Scherrer Institut <PSI> Villigen, Schweiz
# 	Copyright ©, 2018, Benoit STEF, all rights reserved
#=================================================================
# Purpose   : Processing for demodulation of RF signal with
#             added noise - here we want to get stimuli from
#             demodulated IQ and then extract to Txt file
# Author    : Benoît STEF - SB82 DSV group 8221 @PSI WBBA/302
# Project   : Psi Fix library elemental
# Used in   : HIPA Upgrade Inj2 LLRF
#==================================================================
import numpy as np
from matplotlib import rcParams
rcParams['font.family'] = 'sans-serif'
rcParams['font.sans-serif'] = ['Arial']
import sys
sys.path.append("../../../model")
import matplotlib.pyplot as plt
from scipy import signal, misc
import os

STIM_DIR = os.path.dirname(os.path.abspath(__file__)) + "/../Data"
PLOT_ON = False

try:
    os.mkdir(STIM_DIR)
except FileExistsError:
    pass

N = 8192  # N samples
M = 256  #
w0 = 2 / 5 * np.pi
N0 = 0.1
scale = np.full((1, N),(2**(16-1)-1))
sample = np.arange(0, N)

s = np.cos(w0 * np.arange(N))   # source
n = N0 * np.random.rand(N)      # noise
x = s+n


if PLOT_ON:
    # plot Stimuli
    fig = plt.figure()
    ax1 = fig.add_subplot(211)
    ax1.plot(sample, x)
    ax1.set_ylim([-1.2, 1.2])
    ax1.set_title('Sampled data X')
    # plot PSD noise not normalized
    ax2 = fig.add_subplot(212)
    ax2.psd(x, NFFT=1024, Fs=253e6, color="blue")  # original
    ax2.set_title("PSD of 'Sampled data")

np.savetxt(STIM_DIR + '/stimuli.txt', (scale*x).astype(int).T, fmt='% 4d', newline='\n') #stimuli save

coefsin = np.linspace(1,1,5)
coefcos = np.linspace(1,1,5)
#print(coefcos)
for i in range(1,5):
    if i== 5:
        break
    else:
        coefsin[i] = 2/5*np.sin(w0*i)
        coefcos[i] = 2/5*np.cos(w0*i)
        i =+1

inphase     = signal.lfilter(np.linspace(1,1,5),coefsin,x)
quadrature  = signal.lfilter(np.linspace(1,1,5),-coefcos,x)

# plot in-phase after non IQ demod
if PLOT_ON:
    fig1 = plt.figure()
    ax3 = fig1.add_subplot(111)
    ax3.plot(sample,inphase[0:N],'b',sample,quadrature[0:N],'r')
    ax3.grid(axis='both')

np.savetxt(STIM_DIR + '/stimuli_inphase.txt', (scale*inphase).astype(int).T, fmt='% 4d', newline='\n') #stimuli save
np.savetxt(STIM_DIR + '/stimuli_quadrature.txt', (scale*quadrature).astype(int).T, fmt='% 4d', newline='\n') #stimuli save

# plot in-phase after non IQ demod
if PLOT_ON:
    fig2 = plt.figure()
    unit_circle = plt.Circle((0,0),1,color='g',fill=False)
    ax4 = fig2.add_subplot(111)
    ax4.plot(quadrature,inphase,'b+',label='demod data')
    ax4.grid(axis='both')
    ax4.set_ylim([-1.2, 1.2])
    ax4.set_xlim([-1.2, 1.2])
    ax4.add_artist(unit_circle)
    ax4.set_title('Unit circle complex plane IQ')

# definition rotation matrix
angle = 99.
theta = (angle/180.) * np.pi
i1 = np.cos(theta)
i2 = -np.sin(theta)
q1 = np.sin(theta)
q2 = np.cos(theta)

rotInp=np.linspace(1,1,N)
rotQua=np.linspace(1,1,N)
for i in range(1,N):
    if i ==N:
        break
    else:
        rotInp[i]=inphase[i]*i1-quadrature[i]*i2
        rotQua[i]=inphase[i]*q1+quadrature[i]*q2

# plot rotation matrix result
if PLOT_ON:
    ax4.plot(rotQua,rotInp,'r+',label='rotation data')
    ax4.legend(loc=2)

decim10Inp = signal.decimate(rotInp, 2, ftype='fir', zero_phase=True)
decim10Qua = signal.decimate(rotQua, 2, ftype='fir', zero_phase=True)

if PLOT_ON:
    fig3 = plt.figure()
    ax5 = fig3.add_subplot(111)
    ax5.plot(sample[1:len(decim10Inp)+1], decim10Inp, 'b', sample[1:len(decim10Qua)+1], decim10Qua, 'r')
    ax5.grid(axis='both')

absVal=np.linspace(1, 1, len(decim10Inp))
phiVal=np.linspace(1, 1, len(decim10Inp))
for i in range(1, len(absVal)):
    if i == len(absVal):
        break
    else:
        absVal[i] = (decim10Inp[i]**2+decim10Qua[i]**2)**(0.5)
        phiVal[i] = np.arctan2(decim10Qua[i], decim10Inp[i])

if PLOT_ON:
    fig4 = plt.figure()
    ax6 = fig4.add_subplot(211)
    ax6.plot(sample[1:len(absVal)+1], absVal)
    ax7 = fig4.add_subplot(212)
    ax7.plot(sample[1:len(phiVal)+1], phiVal)
    plt.show()