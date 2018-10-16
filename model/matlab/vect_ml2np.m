%-----------------------------------------------------------------------------
%  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
%  All rights reserved.
%  Authors: Oliver Bruendler
%-----------------------------------------------------------------------------
%
% Function to convert a MATLAB vector into a python vector to be passed
% to python functions and objects.
%
% ml    MATLAB vector
% np    Python vector (np.ndarray)
%
function np = vect_ml2np(ml)
    np = py.numpy.array(ml);
end