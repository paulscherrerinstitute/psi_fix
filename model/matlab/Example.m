%-----------------------------------------------------------------------------
%  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
%  All rights reserved.
%  Authors: Oliver Bruendler
%-----------------------------------------------------------------------------

% Note that this example only shows how to call the python models from 
% MATLAB. Details on how the pythons model work need to be checked in the
% python code.

% Important note: After changing python models, MATLAB must be restarted
% to reload the new python models. Therefore it is suggested to develop
% the models in python and use MATLAB only as additional interface.

%Python call syntax: py.<file>.<class>.<Method>([parameters])

%%%%%%%%%%%%%%%%%%%%%%%
%%%% Initialization %%%
%%%%%%%%%%%%%%%%%%%%%%%

%Add path to python models to the python sys.path
insert(py.sys.path, int32(0), '..')

%%%%%%%%%%%%%%%%%%%%%%%
%%%% Filter example %%%
%%%%%%%%%%%%%%%%%%%%%%%

%Define number formats (literals can be passed directly)
fmtIo = py.psi_fix_pkg.PsiFixFmt(1,0,15);
fmtCoef = py.psi_fix_pkg.PsiFixFmt(1,0,17);

%Create filter object
fir = py.psi_fix_fir.psi_fix_fir(fmtIo, fmtIo, fmtCoef);

%Execute filtering (convert parameters to np-vectors)
coefs = [0.2 0.5 0.25];
inp = [0 0.1 0.0 0.0 0.0 0.4];
filtoutNp = fir.Filter(vect_ml2np(inp), 1, vect_ml2np(coefs));

%Print output (convert np-vector to MATLAB vector)
disp('filter output:')
filtOutDbl = vect_np2ml(filtoutNp)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Linear Approximation example %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Get configuration for 18-bit sine wave 
%--> Use MATLAB compatibility function since nested python classes
%    are not supported by the MATLAB-Python interface
lincfg = py.psi_fix_lin_approx.psi_fix_lin_approx.ConfigSin18Bit();

%Create approximation object
apprx = py.psi_fix_lin_approx.psi_fix_lin_approx(lincfg);

%Execute approximation (conversions from and to python vectors included)
in = 0:0.01:0.99;
data = vect_np2ml(apprx.Approximate(vect_ml2np(in)));

%Plot results
plot(data)
