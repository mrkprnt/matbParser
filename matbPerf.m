classdef matbPerf < matlab.mixin.Copyable
    % Performance data from matb
    
    properties
        comm
        matb
        rate
        rman = struct(...
            'info',struct('eventsFilename',[],'pumpFlowRates',[],'tankACons',[],'tankBCons',[]),...
            'log',struct('time_vct',[],'pumpId',[],'pumpFail',[],'pumpFix',[],'pumpOn',[],'pumpOff',[],'tankA',[],'tankB',[],'tankC',[],'tankD',[])...
            );
        sysm = struct(...
            'info',struct('eventsFilename',[],'scaleTimeout',[]),...
            'log',struct('time_vct',[],'respTime',[],'scaleId',[],'correct',[])...
            );
        trck = struct(...
            'info',struct('eventsFilename',[]),...
            'log',struct('time_vct',[],'rmsd',[])...
            );
        errorFlag = false
        
    end
    
    properties(Hidden = true , Constant = true)
        matbFileTypes = {'COMM','MATB','RATE','RMAN','SYSM','TRCK'} ;
        existingParsers = {'rman','sysm','trck'} ;
        time0 = datenum('00:00:00.0') ;
        tankTarget = 2500 ;
        featureList = {...
            'rmanAvgTargetTankDeviation',...
            'rmanRTargetTankDeviation',...
            'rmanTargetTankDelta',...
            'rmanAvgBackupTankLevel',...
            'sysmAvgRespTime',...
            'sysmRRespTime',...
            'sysmAccuracy',...
            'sysmFalseHitRatio',...
            'sysmMissRatio',...
            'trckAvgRmsd'} ; % List of all methods that are features
        
    end
    
    methods
        
        %% matbPerf
        function self = matbPerf(dataPath)
            % Constructor method
            
            if nargin==1 % If given input, parse file
                self.parseFile(dataPath) ;
            end
        end
        
        %% parseFile
        function parseFile(self,source)
            % Parse a matb file
            % Expect source to be rawFile, as provided by loadTxtFile
            % If source is path, will convert to rawfile first
            
            if ischar(source)
                source = matbUtils.loadTxtFile(source) ; % Conver to rawFile type
            end
            fileType = matbPerf.identifyFileType(source) ; % Identify fileType
            switch fileType % Parse according to fileType
                case 'COMM'
                    self.comm = 'No parser for this fileType' ;
                case 'MATB'
                    self.matb = 'No parser for this fileType' ;
                case 'RATE'
                    self.rate = 'No parser for this fileType' ;
                case 'RMAN'
                    self.parseRman(source,19) ;
                    self.sortRman ;
                case 'SYSM'
                    self.parseSysm(source,12) ;
                case 'TRCK'
                    self.parseTrck(source,19) ;
            end
        end
        
        %% parseRman
        function parseRman(self,rawFile,lineStart)
            % Parse an Rman rawFile
            % lineStart is line at which logging start

            try
                % eventsFilename
                self.rman.info.eventsFilename = rawFile{3}(20:end) ;
                
                % pumpFlowRates
                self.rman.info.pumpFlowRates(1) = str2double(rawFile{6}(12:14)) ; % WARNING: Most likely won't work if flow is not 3 digits.
                self.rman.info.pumpFlowRates(2) = str2double(rawFile{6}(27:29)) ;
                self.rman.info.pumpFlowRates(3) = str2double(rawFile{6}(42:44)) ;
                self.rman.info.pumpFlowRates(4) = str2double(rawFile{6}(57:59)) ;
                self.rman.info.pumpFlowRates(5) = str2double(rawFile{7}(12:14)) ;
                self.rman.info.pumpFlowRates(6) = str2double(rawFile{7}(27:29)) ;
                self.rman.info.pumpFlowRates(7) = str2double(rawFile{7}(42:44)) ;
                self.rman.info.pumpFlowRates(8) = str2double(rawFile{7}(57:59)) ;
                
                % tankCons
                self.rman.info.tankACons = str2double(rawFile{10}(12:14)) ; % WARNING: Most likely won't work if flow is not 3 digits.
                self.rman.info.tankBCons = str2double(rawFile{10}(27:29)) ;
                
                % time_vct
                self.rman.log.time_vct = matbPerf.parseTime(rawFile,lineStart) ;
                
                % pumpId
                self.rman.log.pumpId = cellfun(@(x)str2double(x(19)),rawFile(lineStart:end-1)) ;
                
                % pumpStatus
                self.rman.log.pumpFail = cellfun(@(x)strcmp(x(27:30),'Fail'),rawFile(lineStart:end-1)) ;
                self.rman.log.pumpFix = cellfun(@(x)strcmp(x(27:30),'Fix '),rawFile(lineStart:end-1)) ;
                self.rman.log.pumpOn = cellfun(@(x)strcmp(x(27:30),'On  '),rawFile(lineStart:end-1)) ;
                self.rman.log.pumpOff = cellfun(@(x)strcmp(x(27:30),'Off '),rawFile(lineStart:end-1)) ;
                
                % tankStatus
                self.rman.log.tankA = cellfun(@(x)str2double(x(54:57)),rawFile(lineStart:end-1)) ;
                self.rman.log.tankB = cellfun(@(x)str2double(x(63:66)),rawFile(lineStart:end-1)) ;
                self.rman.log.tankC = cellfun(@(x)str2double(x(72:75)),rawFile(lineStart:end-1)) ;
                self.rman.log.tankD = cellfun(@(x)str2double(x(81:84)),rawFile(lineStart:end-1)) ;
                
            catch
                warning('Could not parse file correctly.') ;
                self.errorFlag = true ;
            end
        end
        
        %% sortRman
        function sortRman(self)
            % Rman event are not always sorted, this will do it
            
            [~,sortIdx] = sort(self.rman.log.time_vct) ; % Determine sort index
            fieldList = fieldnames(self.rman.log) ; % List of fields to sort
            for fieldIdx = 1:length(fieldList) % For all fields of fieldList
                self.rman.log.(fieldList{fieldIdx}) = self.rman.log.(fieldList{fieldIdx})(sortIdx) ; % Sort field according to new index
            end
        end
        
        %% parseSysm
        function parseSysm(self,rawFile,lineStart)
            % Parse a Sysm rawFile
            % lineStart is line at which logging start
            
            try
                % eventsFilename
                self.sysm.info.eventsFilename = rawFile{3}(20:end) ;
                
                % scaleTimeout
                self.sysm.info.scaleTimeout = str2double(rawFile{5}(49:50)) ;
                
                % time_vct
                self.sysm.log.time_vct = matbPerf.parseTime(rawFile,lineStart) ;
                
                % respTime
                self.sysm.log.respTime = cellfun(@(x)str2double(x(15:18)),rawFile(lineStart:end-1)) ;
                
                % scaleId
                self.sysm.log.scaleId = cellfun(@(x)matbUtils.strfindExt(x,{'ONE','TWO','THREE','FOUR'}),rawFile(lineStart:end-1)) ;
                
                % tankStatus
                self.sysm.log.correct = cellfun(@(x)strcmp(x(47:50),'TRUE'),rawFile(lineStart:end-1)) ;
            catch
                warning('Could not parse file correctly.') ;
                self.errorFlag = true ;
            end
        end
        
        %% parseTrck
        function parseTrck(self,rawFile,lineStart)
            % Parse a Trck rawFile
            % lineStart is line at which logging start
            
            try
                % eventsFilename
                self.trck.info.eventsFilename = rawFile{3}(20:end) ;
                
                % time_vct
                self.trck.log.time_vct = matbPerf.parseTime(rawFile,lineStart) ;
                
                % respTime
                self.trck.log.rmsd = cellfun(@(x)str2double(matbPerf.strsplitReturn(x,'   ',5)),rawFile(lineStart:end-1)) ;
                
            catch
                warning('Could not parse file correctly.') ;
                self.errorFlag = true ;
            end
        end
        
        %% rmanAvgTargetTankDeviation
        function output = rmanAvgTargetTankDeviation(self)
            % Provides the average deviation of A and B tanks (from 2500)
            
            a = mean(abs(self.rman.log.tankA-self.tankTarget)) ;
            b = mean(abs(self.rman.log.tankB-self.tankTarget)) ;
            output = mean([a,b]) ;
        end
        
        %% rmanRTargetTankDeviation
        function output = rmanRTargetTankDeviation(self)
            % Provide the correlation coef. "r" between time and deviation
            
            if isempty(self.rman.log.tankA)||isempty(self.rman.log.tankB)
                output = nan ;
            else
                a = abs(self.rman.log.tankA-self.tankTarget) ;
                b = abs(self.rman.log.tankB-self.tankTarget) ;
                if range(mean([a,b],2))==0
                    output = 0 ; % If level doesn't change, set to 0 (corr output nan otherwise)
                else
                    output = corr(self.rman.log.time_vct,mean([a,b],2),'rows','pairwise') ;
                end
            end
        end
        
        %% rmanTargetTankDelta
        function output = rmanTargetTankDelta(self)
            % Return variation of output level
            
            if isempty(self.rman.log.tankA)||isempty(self.rman.log.tankB)
                output = nan ;
            else
                a = abs(self.rman.log.tankA-self.tankTarget) ;
                b = abs(self.rman.log.tankB-self.tankTarget) ;
                avgAB = mean([a,b],2) ;
                output = avgAB(end)-avgAB(1) ;
            end
        end
        
        %% rmanAvgBackupTankLevel
        function output = rmanAvgBackupTankLevel(self)
            % Provide the average level of backup tanks (C and D)
            
            output = mean([self.rman.log.tankC;self.rman.log.tankD]) ;
        end
        
        %% sysmAvgRespTime
        function output = sysmAvgRespTime(self)
            % Provides the average response time on sysm
            
            output = nanmean(self.sysm.log.respTime) ; % nanmean is used since false hit result in nan in respTime
        end
        
        %% sysmRRespTime
        function output = sysmRRespTime(self)
            % Provides the correlation coef. "r" between time and respTime
            
            nanLines = isnan(self.sysm.log.respTime) ;
            if isempty((self.sysm.log.time_vct(~nanLines)))
                output = nan ;
            else
                output = corr(self.sysm.log.time_vct(~nanLines),self.sysm.log.respTime(~nanLines)) ;
            end
        end
        
        %% sysmAccuracy
        function output = sysmAccuracy(self)
            % Compute the overall accuracy on sysm
            
            output = sum(self.sysm.log.correct)./length(self.sysm.log.correct) ;
        end
        
        %% sysmFalseHitRatio
        function output = sysmFalseHitRatio(self)
            % Compute the false hit ratio on sysm
            
            output = sum(isnan(self.sysm.log.respTime))./length(self.sysm.log.respTime) ;
        end
        
        %% sysmMissRatio
        function output = sysmMissRatio(self)
            % Compute the miss ratio on sysm
            
            output = sum(self.sysm.log.respTime==self.sysm.info.scaleTimeout)./length(self.sysm.log.respTime) ;
        end
        
        %% trckAvgRmsd
        function output = trckAvgRmsd(self)
            % Compute the average rmsd on trck
            
            output = mean(self.trck.log.rmsd) ;
        end
        
    end
    
    methods(Static)
        
        %% identifyFileType
        function fileType = identifyFileType(rawFile)
            % Identify matb fileType
            
            % Check for fileTypes
            fileCheck = false(1,6) ; % Initialize
            for fileTypeIdx = 1:length(matbPerf.matbFileTypes)
                fileCheck(fileTypeIdx) = ~isempty(strfind(rawFile{1},matbPerf.matbFileTypes{fileTypeIdx})) ; % Check first line to see if it contain fileType marker
            end
            
            % Error handling
            if sum(fileCheck)==0
                error('fileType not identified.') ;
            elseif sum(fileCheck)>1
                error('More than one fileType identified.') ;
            end
            
            % Return output
            fileType = matbPerf.matbFileTypes{fileCheck} ;
        end

        %% parseTime
        function time = parseTime(rawFile,lineStart)
            % Parse time given a rawFile
            % lineStart is line at which timestamps starts
            
            time = cellfun(@(x)datenum(x(2:11)),rawFile(lineStart:end-1)) ; % Get date from string
            time = time-matbPerf.time0 ; % Substract so it starts a 0
            time = time*24*3600 ; % Convert from day to seconds
        end
        
        %% strsplitReturn
        function output = strsplitReturn(x,delimiter,idx)
            % Return idx of strsplit
            
            output = strsplit(x,delimiter) ; % Split
            output = output{idx} ; % Return one value
        end
        
    end
end