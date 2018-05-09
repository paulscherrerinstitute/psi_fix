#=================================================================
#	Paul Scherrer Institut <PSI> Villigen, Schweiz
# 	Copyright ©, 2018, Benoit STEF, all rights reserved 
#=================================================================
# Purpose   : App using Matrix rotation 2D - generate Stimuli/Obs
# Author    : Benoît STEF - SB82 DSV group 8221 @PSI WBBA/302
# Project   : Psi Fix library elemental 
# Used in   : HIPA Upgrade Inj2 LLRF
# HDL file  : psi_fix_matrix_rotation_2D_tb.vhd
#==================================================================
import sys
import matplotlib.pyplot as plt

# not required since in psi_fix_pkg
from psi_fix_matrix_rotation_2D import psi_fix_matrix_rot
# fetch path for model
sys.path.insert(0, "../../model")
import numpy as np
from psi_fix_pkg import *

# Format definition
inFmt       = PsiFixFmt(1, 1, 15)
coefFmt     = PsiFixFmt(1, 1, 15)
internalFmt = PsiFixFmt(1, 2, 30)
outFmt      = PsiFixFmt(1, 1, 15)

# write into text file
x = np.genfromtxt("stimuli_inphase.txt")/(2**inFmt.F)
y = np.genfromtxt("stimuli_quadrature.txt")/(2**inFmt.F)

# Test with a scalar
#x = np.full((1, 16),  0.5, dtype=float)
#y = np.full((1, 16), -0.3, dtype=float)

# definition rotation matrix - a function would be nicer
angle = 90.
theta = (angle/180.) * np.pi
i1 = np.cos(theta)
i2 = np.sin(theta)
q1 = np.sin(theta)
q2 = np.cos(theta)
#print(i1, i2, q1, q2)

# call Model rotation matrix
MatRot = psi_fix_matrix_rot(inFmt, outFmt, coefFmt, internalFmt, PsiFixRnd.Round, PsiFixSat.Sat)
rotX, rotY = MatRot.Process(x, y, i1, i2, q1, q2)

#print(np.arctan2(y[0], x[0])*180/np.pi)
#print(np.arctan2(rotY[0], rotX[0])*180/np.pi)

# plot complex plane and evidence of rotation
unit_circle = plt.Circle((0,0),1,color='g',fill=False)
sample  = np.arange(0,len(x),1)
fig0    = plt.figure()
ax2     = fig0.add_subplot(111)
ax2.plot(y,x,'b+',label='stimuli data')
ax2.plot(rotY,rotX,'r+',label='rotation data')
ax2.set_ylim([-1.2, 1.2])
ax2.set_xlim([-1.2, 1.2])
ax2.add_artist(unit_circle)
ax2.grid(axis='both')
ax2.set_title('Unit circle complex plane IQ => rotation: %d' %(angle))

# format data prior to write into text file
rotXtxt = PsiFixGetBitsAsInt(rotX,outFmt)
rotYtxt = PsiFixGetBitsAsInt(rotY,outFmt)

# text file used to make VHDL testbench comparison
np.savetxt('model_result_rotX.txt', rotXtxt.astype(int).T, fmt='% 4d', newline='\n') #observable wave
np.savetxt('model_result_rotY.txt', rotYtxt.astype(int).T, fmt='% 4d', newline='\n') #observable wave

plt.show()