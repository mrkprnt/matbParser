Parser for NASA-MATBII
Programmed by: Mark Parent, MuSAE LAB, INRS-EMT, Montreal, Canada
Contact: mark.parent@psy.ulaval.ca

----------

OVERVIEW
This program is used to parse files logged by NASA-MATBII. Each time it is used, MATBII creates 6 txt files (prefixed: COMM, MATB, RATE, RMAN, SYSM and TRCK). The current program allows these files to be imported in MATLAB. It contain 3 classes: matbPerf, matbPerfOrganizer and matbUtils, which are described in this readme.

----------

TODO
- There are currently parsing methods only for RMAN, SYSM and TRCK. Other parser could be added.
- The TRCK task settings (joystick control and target movement speed) can be changed within a trial. The current parser does not log this information.

----------

CLASS: matbPerf
This class contain the parser methods and the parsed data properties. It also contain some function to compute performance and metrics. To parse a MATBII log file, use this syntax:

mydata = matbPerf(filePath) ;

Or:

mydata = matbPerf ;
mydata = matbPerf.parseFile(filePath) ;

Where filePath is the path of a txt file produced by MATBII. Data will then appear in the object. For example, calling matbPerf on a RMAN file called "RMAN_08261322.txt" such as:

mydata = matbPerf('RMAN_08261322.txt') ;

Will make the RMAN data available at:

mydata.rman ;

To parse and add other log files to mydata, use the parseFile method like:

mydata.parseFile('SYSM_08261322.txt') ;

The SYSM data will then be available in mydata at:

mydata.sysm ;

This can be done to all 6 files in order to group the result under the same object.

----------

CLASS: matbPerfOrganizer
The matbPerfOrganizer can be used to ease parsing organisation. This class will parse all MATBII log files contained in a folder and group all trial under the same object. Call it be specifiying the folder path such as:

mydata = matbPerfOrganizer('\myfolder\') ;

Assuming that MATBII was executed N-times (N-trials), mydata will then contain:

folderPath: The folder used during calling.
trialId: An N-sized cell of MATBII trial identifier.
trialDatenumStart: An N-sized array containing the datenum of the trials start.
trialDatenumEnd: An N-sized array containing the datenum of the trials end.
rawFiles: A structure containing the 6 log files (in an N-sized cell format).
parsedFiles: An N-sized array of matbPerf object, each containing parsed data for all 6 files.

Additionnally, another input can be provided to matbPerfOrganizer. This input can be used to only keep trials that happenned in a certain time range. To do so, call matbPerfOrganizer such as:

mydata = matbPerfOrganizer('\myfolder\',timerange) ;

Where timerange is a M-by-2 array of timestamps (start-end; in datenum format). The matbPerfOrganizer will only keep trials if the range is within a trial. When using timerange, the property timerangeTrialsMatch will indicate which parsedFiles are associated with each timerange. Additionnally, the timerangeParsedFiles property will contain parsedFile trimmed to match timerange.

----------

CLASS: matbUtils
This class contain utilities used by matbPerf and matbPerfOrganizer.