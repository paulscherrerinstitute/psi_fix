########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Benoit Stef, Radoslaw Rybaniec
########################################################################################################################
import sys
import os
sys.path.append("../../../model")
import matplotlib.pyplot as plt
from psi_fix_mod_cplx2real import psi_fix_mod_cplx2real
from psi_fix_mod_cplx2real import psi_fix_mod_cplx2real
import numpy as np
import scipy.signal as sps
from psi_fix_pkg import *

PLOT_ON = False

### Stimuli location
STIM_DIR = os.path.dirname(os.path.abspath(__file__)) + "/../../psi_fix_mod_cplx2real_tb/Data/"
try:
    os.mkdir(STIM_DIR)
except FileExistsError:
    pass

# Format definition
sample = 8192
inpFmt      = psi_fix_fmt_t(1, 1, 15)
coefFmt     = psi_fix_fmt_t(1, 1, 23)
intFmt      = psi_fix_fmt_t(1, 1, 23)
outFmt      = psi_fix_fmt_t(1, 1, 15)
ratio_nums = [10, 5]
ratio_dens = [1, 3]

for ratio_num in ratio_nums:
    for ratio_den in ratio_dens:
        # write into text file
        # x = np.genfromtxt(STIM_DIR + "stimuli_inphase.txt")/(2**intFmt.f)
        # y = np.genfromtxt(STIM_DIR + "stimuli_quadrature.txt")/(2**intFmt.f)

        #x = np.full((sample), 4/5)
        #y = np.full((sample), -3/5)
        #scale = np.full((sample),(2**(16-1)))

        inpAngle = np.linspace(0, 2*np.pi, sample)
        inpAmp = np.linspace(0.99, 0.99, sample)
        datQua = psi_fix_from_real(inpAmp*np.sin(inpAngle), inpFmt, err_sat=False)
        datInp = psi_fix_from_real(inpAmp*np.cos(inpAngle), inpFmt, err_sat=False)


        packInput = np.column_stack((psi_fix_get_bits_as_int(datInp, inpFmt),
                                     psi_fix_get_bits_as_int(datQua, inpFmt)))
        np.savetxt(STIM_DIR + '/input_{}_{}.txt'.format(ratio_num, ratio_den), packInput, fmt='% 4d', delimiter=' ', newline='\n', header='inp qua')


        mod = psi_fix_mod_cplx2real(inpFmt, coefFmt, intFmt, outFmt, ratio_num, ratio_den)
        results = mod.Process(datInp, datQua)

        if PLOT_ON:
            fig1 = plt.figure()
            ax1 = fig1.add_subplot(221)
            ax1.plot(datInp, datQua)
            ax1.grid()
            ax1.set_title("input")

            ax2 = fig1.add_subplot(222)
            ax2.plot(results)
            ax2.grid()
            ax2.set_title("result")

            resCplx = sps.hilbert(results)

            ax3 = fig1.add_subplot(223)
            ax3.plot(abs(resCplx))
            ax3.grid()
            ax3.set_title("result amplitude")

            ax4 = fig1.add_subplot(224)
            ax4.plot(np.cumsum(np.unwrap(np.diff(np.angle(resCplx))-(2*np.pi)/ratio_num)))
            ax4.grid()
            ax4.set_title("result angle (shout change by 2pi)")

            wndw = np.blackman(results.size)
            pwr = 20 * np.log10(abs(np.fft.fft(results*wndw/np.average(wndw))) / sample)
            frq = np.linspace(0, 1, pwr.size)
            fig3 = plt.figure()
            ax5 = fig3.add_subplot(211)
            ax5.plot(frq[1:4096], pwr.reshape((pwr.size,1))[1:4096])
            ax5.grid()
            ax5.set_xlabel("Frequency [Fs]")
            ax5.set_ylabel("Amplitude [dB]")
            ax5.set_title("Output Spectrum")

        res = psi_fix_get_bits_as_int(results,outFmt)

        # text file used to make VHDL testbench comparison
        np.savetxt(STIM_DIR + 'output_{}_{}.txt'.format(ratio_num, ratio_den), res.astype(int).T, fmt='% 4d', newline='\n') #observable wave

        if PLOT_ON:
            plt.show()
