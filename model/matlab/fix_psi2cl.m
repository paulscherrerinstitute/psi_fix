%-----------------------------------------------------------------------------
%  Copyright (c) 2020 by Enclustra, Switzerland
%  All rights reserved.
%  Authors: Oliver Bruendler
%-----------------------------------------------------------------------------
%
% Function to convert a psi_fix fixed point format to en_cl_fix convention.
%
% cl    Fixed point format according to en_cl_fix
% psi   Fixed point format according to psi_fix
%
function cl = fix_psi2cl(psi)
    boolS = false;
    if int64(psi.S) == 1
        boolS = true;
    end
    cl = cl_fix_format(boolS, int64(psi.I), int64(psi.F));
end