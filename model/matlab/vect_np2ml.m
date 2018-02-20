function ml = vect_np2ml(np)
%
% Function to convert a python vector into a MATLAB vector.
%
% np    Python vector (np.ndarray)
% ml    MATLAB vector
% 
    ml = double(py.array.array('d',py.numpy.nditer(np)));
end