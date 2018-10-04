classdef(Sealed = true) matbUtils < handle
    % Utilities for matbParser
    
    properties(Constant)
    end
    
    methods(Static)
        
        %% textNum2num
        function output = textNum2num(input)
            % Convert text numbers (e.g. ONE, TWO) to double
            % Limited to ONE, TWO, THREE, FOUR
            
            output = find(matbUtils.strcmpExt({input},{'ONE  ','TWO  ','THREE','FOUR '})) ;
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
        
        %% strcmpExt
        function output = strcmpExt(s1,s2)
            % Perform multiple strcmp in inputString
            % s1 and s2 are cell vector of string
            % output is logic matrix of size (s1,s2)
            
            output = nan(length(s1),length(s2)) ; % Initialize output
            for s1Idx = 1:length(s1)
                for s2Idx = 1:length(s2)
                    output(s1Idx,s2Idx) = strcmp(s1{s1Idx},s2{s2Idx}) ;
                end
            end
            
        end
        
    end
end