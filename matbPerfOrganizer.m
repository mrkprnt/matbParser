classdef matbPerfOrganizer < handle
    % Data structure for matb performance file
    
    properties
        folderPath
        trialId
        trialDatenumStart
        trialDatenumEnd
        rawFiles
        parsedFiles = {}
        timerange
        timerangeTrialsMatch = {} 
        timerangeParsedFiles = {} ;
        
    end   
    
    methods
        
        %% matbPerfOrganizer
        function self = matbPerfOrganizer(folderPath,timerange)
            % Constructor method
            
            if nargin==1 % If folderPath provided, load all data do everything
                self.loadFolderInfo(folderPath) ;
                self.importRawFiles ;
                self.identifyDatenum ;
                self.parseRawFiles ;
            elseif nargin==2
                if size(timerange,2)>size(timerange,1) % If provided a row vector
                    timerange = timerange' ; % Rotate vector to have column vector
                end
                self.timerange = timerange ;
                self.loadFolderInfo(folderPath) ;
                self.importRawFiles ;
                self.identifyDatenum ;
                self.removeUnusedTrials ;
                self.matchTimerangeTrials ;
                self.parseRawFiles ;
                self.getTimerangeParsedFiles ;
            else
                error('Too many inputs.') ;
            end
        end
        
        %% loadFolderInfo
        function loadFolderInfo(self,folderPath)
            % Provide a list (cell of string) of all trialId
            
            self.folderPath = folderPath ; % Save folderPath
            fileList = dir(self.folderPath) ; % Get dirList
            fileList([fileList.isdir]) = [] ; % Delete folders from this list
            self.trialId = cellfun(@(x){x(6:end-4)},{fileList.name}) ; % Extract id from file name
            self.trialId = unique(self.trialId) ; % Remove duplicate
        end
        
        %% importRawFiles
        function importRawFiles(self)
            % Load all rawFiles
            
            waitBarFig = waitbar(0,'Importing rawFiles.','Name','Importing') ; % Create wait bar
            for trialIdx = 1:length(self.trialId) % For all trials
                waitbar(trialIdx/length(self.trialId),waitBarFig) ; % Update waitbar
                for fileTypeIdx = 1:length(matbPerf.matbFileTypes)
                    filePath = strcat(self.folderPath,'\',matbPerf.matbFileTypes{fileTypeIdx},'_',self.trialId{trialIdx},'.txt') ; % Get filePath
                    self.rawFiles.(matbPerf.matbFileTypes{fileTypeIdx}){trialIdx} = matbUtils.loadTxtFile(filePath) ; % Load rawFile
                end
            end
            close(waitBarFig) ;
        end
        
        %% identifyDatenum
        function identifyDatenum(self)
            % Parse all datenum from files
            
            waitBarFig = waitbar(0,'Identifying datenum of rawFiles.','Name','Identifying') ; % Create wait bar
            for trialIdx = 1:length(self.trialId) % For all trials
                waitbar(trialIdx/length(self.trialId),waitBarFig) ; % Update waitbar
                self.trialDatenumStart(trialIdx) = datenum(self.rawFiles.MATB{trialIdx}{1}(3:25)) ; % Identify datenumStart from MATB rawFile
                self.trialDatenumEnd(trialIdx) = self.trialDatenumStart(trialIdx)+datenum(self.rawFiles.MATB{trialIdx}{end-1}(1:10))-matbPerf.time0 ; % Indentify datenumEnd from MATB rawFile
            end
            close(waitBarFig) ;
        end
        
        %% removeUnusedTrials
        function removeUnusedTrials(self)
            % Seek trial that belong to timerange given as input.
            % Remove unused trials
            
            % Find trial to keep
            usefulTrials = [] ; % Initialize array
            waitBarFig = waitbar(0,'Removing unused trials.','Name','Removing') ; % Create wait bar
            for timerangeIdx = 1:size(self.timerange,1)
                waitbar(timerangeIdx/size(self.timerange,1),waitBarFig) ; % Update waitbar
                currentSubjectTrials = find(~(self.timerange(timerangeIdx,2)<self.trialDatenumStart|self.timerange(timerangeIdx,1)>self.trialDatenumEnd)) ; % Check if timerange overlap with trial
                usefulTrials = [usefulTrials,currentSubjectTrials] ; % Append it to list of useful trials
            end
            usefulTrials = unique(usefulTrials) ; % Remove duplicates
            close(waitBarFig) ;
            
            % Prune other trials
            self.trialId = self.trialId(usefulTrials) ;
            self.trialDatenumStart = self.trialDatenumStart(usefulTrials) ;
            self.trialDatenumEnd = self.trialDatenumEnd(usefulTrials) ;
            for fileTypeIdx = 1:length(matbPerf.matbFileTypes)
                self.rawFiles.(matbPerf.matbFileTypes{fileTypeIdx}) = self.rawFiles.(matbPerf.matbFileTypes{fileTypeIdx})(usefulTrials) ;
            end
        end
        
        %% matchTimerangeTrials
        function matchTimerangeTrials(self)
            % Now match timeranges with trials
            
            waitBarFig = waitbar(0,'Matching timerange with trials.','Name','Matching') ; % Create wait bar
            for timerangeIdx = 1:size(self.timerange,1)
                waitbar(timerangeIdx/size(self.timerange,1),waitBarFig) ; % Update waitbar
                currentTimerangeTrials = find(~(self.timerange(timerangeIdx,2)<self.trialDatenumStart|self.timerange(timerangeIdx,1)>self.trialDatenumEnd)) ; % Check if timerange overlap with trial
                self.timerangeTrialsMatch{timerangeIdx} = currentTimerangeTrials ; % Save it in cell
            end
            close(waitBarFig) ;
        end
        
        %% parseRawFiles
        function parseRawFiles(self)
            % Parse all rawFiles to convert them to matbPerf
            
            waitBarFig = waitbar(0,'Parsing rawFiles.','Name','Parsing') ; % Create wait bar
            for trialIdx = 1:length(self.trialId)
                waitbar(trialIdx/length(self.trialId),waitBarFig) ; % Update waitbar
                self.parsedFiles{trialIdx} = matbPerf ; % Instance matbPerf class
                for fileTypeIdx = 1:length(matbPerf.matbFileTypes)
                    self.parsedFiles{trialIdx}.parseFile(self.rawFiles.(matbPerf.matbFileTypes{fileTypeIdx}){trialIdx}) ; % Parse all rawFile for this trial
                end
            end
            close(waitBarFig) ;
        end
        
        %% getTimerangeParsedFiles
        function getTimerangeParsedFiles(self)
            % For all timerange, get keep only the part of the parsedFile
            % that matches the timerange
            
            waitBarFig = waitbar(0,'Trimming parsed files to timerange.','Name','Trimming') ; % Create wait bar
            for timerangeIdx = 1:length(self.timerangeTrialsMatch) % For all timerange
                waitbar(timerangeIdx/length(self.timerangeTrialsMatch),waitBarFig) ; % Update waitbar
                if length(self.timerangeTrialsMatch{timerangeIdx})~=1 % If more that one parsed file (or none) matches
                    self.timerangeParsedFiles{timerangeIdx} = matbPerf ; % Initialize empty object
                    continue % Skip
                end
                parsedId = self.timerangeTrialsMatch{timerangeIdx} ;
                self.timerangeParsedFiles{timerangeIdx} = self.parsedFiles{parsedId}.copy ; % Copy matching parsedFile
                for fieldIdx = 1:length(matbPerf.existingParsers) % For all fields with existing parser
                    logFields = fieldnames(self.timerangeParsedFiles{timerangeIdx}.(matbPerf.existingParsers{fieldIdx}).log) ; % List all fields in log
                    time_vct_inDays = self.timerangeParsedFiles{timerangeIdx}.(matbPerf.existingParsers{fieldIdx}).log.time_vct/(24*3600) ; % Convert time_vct to days
                    relevantLines = ...
                        time_vct_inDays+self.trialDatenumStart(parsedId)>=self.timerange(timerangeIdx,1) &...
                        time_vct_inDays+self.trialDatenumStart(parsedId)<=self.timerange(timerangeIdx,2) ;
                    for logFieldIx = 1:length(logFields) % For all the fields in log
                        self.timerangeParsedFiles{timerangeIdx}.(matbPerf.existingParsers{fieldIdx}).log.(logFields{logFieldIx}) = ...
                            self.timerangeParsedFiles{timerangeIdx}.(matbPerf.existingParsers{fieldIdx}).log.(logFields{logFieldIx})(relevantLines) ; % Keep only relevant lines
                    end
                end
            end
            close(waitBarFig) ;
        end
        
    end
end