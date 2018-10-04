classdef matbPerfOrganizer < handle
    % Data structure for matb performance file
    
    properties
        folderPath
        subjectTrials
        trialId
        trialDatenumStart
        trialDatenumEnd
        rawFiles
        parsedFiles
        
    end   
    
    methods
        
        %% matbPerfOrganizer
        function self = matbPerfOrganizer(folderPath,subjectTimerange)
            % Constructor method
            
            if nargin==1 % If folderPath provided, load all data do everything
                self.loadFolderInfo(folderPath) ;
                self.importRawFiles ;
                self.identifyDatenum ;
                self.parseRawFiles ;
            elseif nargin==2
                if size(subjectTimerange,2)>size(subjectTimerange,1) % If provided a row vector
                    subjectTimerange = subjectTimerange' ; % Rotate vector to have column vector
                end
                self.loadFolderInfo(folderPath) ;
                self.importRawFiles ;
                self.identifyDatenum ;
                self.removeUnusedTrials(subjectTimerange) ;
                self.matchSubjectTrials(subjectTimerange) ;
                self.parseRawFiles ;
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
        function removeUnusedTrials(self,subjectTimerange)
            % Seek trial that belong to subjects given as input.
            % Remove unused trials
            
            % Find trial to keep
            usefulTrials = [] ; % Initialize array
            waitBarFig = waitbar(0,'Removing unused trials.','Name','Removing') ; % Create wait bar
            for subjectIdx = 1:size(subjectTimerange,1)
                waitbar(subjectIdx/size(subjectTimerange,1),waitBarFig) ; % Update waitbar
                currentSubjectTrials = find(self.trialDatenumStart>=subjectTimerange(subjectIdx,1) & self.trialDatenumEnd<=subjectTimerange(subjectIdx,2)) ; % Find trials that match this subject
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
        
        %% matchSubjectTrials
        function matchSubjectTrials(self,subjectTimerange)
            % Now match subjects with trials
            
            waitBarFig = waitbar(0,'Matching subjects with trials.','Name','Matching') ; % Create wait bar
            for subjectIdx = 1:size(subjectTimerange,1)
                waitbar(subjectIdx/size(subjectTimerange,1),waitBarFig) ; % Update waitbar
                currentSubjectTrials = find(self.trialDatenumStart>=subjectTimerange(subjectIdx,1) & self.trialDatenumEnd<=subjectTimerange(subjectIdx,2)) ; % Find trials that match this subject
                self.subjectTrials{subjectIdx} = currentSubjectTrials ; % Save it in cell
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
        
    end
    
end