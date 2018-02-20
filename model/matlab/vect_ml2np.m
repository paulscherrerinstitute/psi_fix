function np = vect_ml2np(ml)
%
% Function to convert a MATLAB vector into a python vector to be passed
% to python functions and objects.
%
% ml    MATLAB vector
% np    Python vector (np.ndarray)
%
    np = py.numpy.array(ml);
end