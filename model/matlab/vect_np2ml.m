%-----------------------------------------------------------------------------
%  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
%  All rights reserved.
%  Authors: Oliver Bruendler
%-----------------------------------------------------------------------------
%
% Function to convert a python vector into a MATLAB vector.
%
% np    Python vector (np.ndarray)
% ml    MATLAB vector
% 
function ml = vect_np2ml(np)
    ml = double(py.array.array('d',py.numpy.nditer(np)));
end