classdef(Sealed = true) matbUtils < handle
    % Utilities for matbParser
    
    properties(Constant)
    end
    
    methods(Static)
        
        %% textNum2num
        function output = strfindExt(input,str2find)
            % Find more than one string
            
            for strIdx = 1:length(str2find)
                if ~isempty(strfind(input,str2find{strIdx}))
                    output = strIdx ;
                    break
                end
            end
        end
        
        %% loadTxtFile
        function rawFile = loadTxtFile(filePath)
            % Read a text file and convert it to 1 cell per line
            
            fileId = fopen(filePath,'r') ; % Open file
            try
                rawFile = strsplit(fscanf(fileId,'%c'),'\n')' ; % Organize it as 1 cell per line
                fclose(fileId) ; % Close file
            catch
                fclose(fileId) ; % Close file
                error('Unable to load txt file.') ;
            end
        end
        
    end
end