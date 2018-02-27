function map = getMapFromBuffer(mapBuffer, rows, cols)
% getMapFromBuffer - This function extracts the map from the array and 
% reshapes it according to the specified sizes.
%
% Inputs:
%   mapBuffer - the buffer containing the map data
%   rows - number of rows
%   cols - number of cols
% Outputs:
%   map - rows x cols sized map
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
% Toolboxes required: none

% Created: October 2014;
% Author: Uwe Hahne
% SICK AG, Waldkirch
% email: techsupport0905@sick.de
% Last commit: $Date: 2016-04-06 15:14:08 +0200 (Wed, 06 Apr 2016) $
% Last editor: $Author: hahneuw $ 

% Version "$Revision: 8513 $"



%------------- BEGIN CODE --------------

map = [];
if (~isempty(mapBuffer))
    bufferAsArray = mapBuffer.array();
    targetArray = typecast(int8(bufferAsArray), 'uint16');
    map = reshape(targetArray, cols, rows)';
end
end