# fluffy-adventure
Automated version of MTXQCvX2

## Description
This current state includes fully automated Rmd-reports for Metabolomics projects.


## Technical details

### Input formats

Currenty supported input formats:
* Maui
* Metmax
* Spreadsheet (under dev)


## Implemented modules
### MTXQCinit

### MTXQC Experimental setup

Parameter of the report: 
* subfolder: text
* input: [metmax, maui]
* file annotation: e.g., annotation.csv
* sample extracts definition: e.g., Sample_extracts.csv
* kind of experiment: [qMTX, pSIRM, pSIRM timeseries]
* stable isotope: [none, glc, gln, pyr, other]
* InternalStandard: [none, cinnamicacid, other]
* origin: [blood, cell extracts, tissue, mixed]
* additional calibration: [no, yes]
* Quant-Mix: [Quant1_v3, Quant1_v4, Quant1_indv]
* Technical replicates: text

### MTXQC part1 - QC

Parameter of the report: 
* subfolder: 
* input: [metmax, maui]
* Manual Validation: [none, all, PeakAreas, Incorporation]
    
    
### MTXQC part2 - Post-Processing

Parameter of the report:
* subfolder:
* analysis: [stringent, less_stringent]
* InternalStandard: [True, False]
* Value of your choice: 
* Parameter 1: 
* Parameter 2: 
* Parameter 3:
* Parameter 4:
* Manual Validation: [none, all, PeakAreas, Incorporation]
    
### MTXQC part3 - Manual Validation

Parameter of the report: 



### MTXQC part4 - Metmax integration

Parameter of the report: 
* subfolder: text
* PeakAreaMatrix: file-definition
* m73-data: file-defintion
* MIDs: file-definition
* InternalStandard: [True, False]
* Generate Alkane: [True, False]
* Generate SumOfArea-normalisation: [True, False]
* Generate ManualQuantTable and samples peakareamatrix: [True, False]
* Calculate incorporation: [True, False]

