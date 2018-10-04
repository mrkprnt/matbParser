classdef(Sealed = true) matbUtils < handle
    % Utilities for matbParser
    
    properties(Constant)
    end
    
    methods(Static)
        
        %% textNum2num
        function output = textNum2num(input)
            % Convert text numbers (e.g. ONE, TWO) to double
            % Limited to ONE, TWO, THREE, FOUR
            
            output = find(strcmp(input,{'ONE  ','TWO  ','THREE','FOUR '})) ;
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