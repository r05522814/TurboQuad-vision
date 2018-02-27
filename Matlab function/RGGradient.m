function [ map ] = RGGradient(numEntries, scale )
%RGGRADIENT Computes a colormap from red to green
%   This colormap is used for the visualization of confidence values. Red
%   means a low confidence, while green indicates a high confidence value.
%
% Inputs:
%   numEntries - number of entries of the colormap
%   scale - the maximum value 
% Other m-files required: none
% MAT-files required: none
% Toolboxes required: none

% Created: March 2016;
% Author: Uwe Hahne
% SICK AG, Waldkirch
% email: techsupport0905@sick.de
% Last commit: $Date: 2016-05-19 10:37:41 +0200 (Thu, 19 May 2016) $
% Last editor: $Author: hahneuw $ 

% Version "$Revision: 8900 $"

% Copyright note: Redistribution and use in source, with or without modification, are permitted.

%------------- BEGIN CODE --------------

    map = zeros(numEntries,3);
    for index=1:numEntries
        value = ((index-1)/(numEntries-1)) * scale;
        vmin = 0.0;
        vmax = scale;

        if (value < vmin)
           value = vmin;
        end
        if (value > vmax)
            value = vmax;
        end

        dv = vmax - vmin;

        if (value < (vmin + 0.5 * dv))
            cr = 1.0;
            cg = 2.0 * ((value - vmin) / dv);
        else
            cr = 2.0 * (vmin + dv - value) / dv;
            cg = 1.0;
        end
        cb = 0.0;

        map(index,1) = cr;
        map(index,2) = cg;
        map(index,3) = cb;
    end

end

