function matrix = setZerosToNaN(matrix)
%SETZEROSTONAN sets zeros in the input to NaN and returns the modified input
%   Detailed explanation goes here
    for i=1:numel(matrix)
        if(matrix(i)==0)
            matrix(i)=NaN;
        end
    end
end

