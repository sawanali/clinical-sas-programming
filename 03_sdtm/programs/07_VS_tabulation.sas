/* SDTM VS program */

%let rawlib=YOUR_RAW_SAS_PATH;
%let sdtmpath=YOUR_SDTM_PATH;
libname raw "&rawlib";
libname sdtm "&sdtmpath";

/* Empty VS shell */
data empty_vs;
    length
        STUDYID $20 DOMAIN $2 USUBJID $40 VSSEQ 8 VSTESTCD $20
        VSTEST $200 VSPOS $40 VSORRES $100 VSORRESU $40
        VSSTRESC $100 VSSTRESN 8 VSSTRESU $40 VSSTAT $40
        VSLOC $40 VSBLFL $1 VISITNUM 8 VISIT $100 VISITDY 8
        VSDTC $30 VSDY 8 VSTPT $200 VSTPTNUM 8 VSELTM $30
        VSTPTREF $100;
    label
        STUDYID="Study Identifier"
        DOMAIN="Domain Abbreviation"
        USUBJID="Unique Subject Identifier"
        VSSEQ="Sequence Number"
        VSTESTCD="Vital Signs Test Short Name"
        VSTEST="Vital Signs Test Name"
        VSPOS="Vital Signs Position of Subject"
        VSORRES="Result or Finding in Original Units"
        VSORRESU="Original Units"
        VSSTRESC="Character Result/Finding in Std Format"
        VSSTRESN="Numeric Result/Finding in Standard Units"
        VSSTRESU="Standard Units"
        VSSTAT="Completion Status"
        VSLOC="Location of Vital Signs Measurement"
        VSBLFL="Baseline Flag"
        VISITNUM="Visit Number"
        VISIT="Visit Name"
        VISITDY="Planned Study Day of Visit"
        VSDTC="Date/Time of Measurements"
        VSDY="Study Day of Vital Signs"
        VSTPT="Planned Time Point Name"
        VSTPTNUM="Planned Time Point Number"
        VSELTM="Planned Elapsed Time from Time Point Ref"
        VSTPTREF="Time Point Reference";
    stop;
run;


/* DM for RFSTDTC */
proc sort data=sdtm.dm(keep=usubjid rfstdtc) out=dm_rfstdtc;
    by usubjid;
run;

/* Read VS and merge RFSTDTC */
data vs;
    merge raw.vs(in=vs)
          dm_rfstdtc;
    by usubjid;
    if vs;
run;


/* Derivations */
data vs;
    set vs;
    if length(vsdtc) >= 10 and length(rfstdtc) >= 10 then do;
        vs_date = input(substr(vsdtc,1,10),yymmdd10.);
        rf_start = input(substr(rfstdtc,1,10),yymmdd10.);
        if not missing(vs_date) and not missing(rf_start) then
            vsdy = vs_date - rf_start + (vs_date >= rf_start);
    end;
    drop vs_date rf_start;
run;


/* Derive VSSEQ */
proc sort data=vs out=vs_sorted;
    by usubjid vsdtc vstestcd;
run;

data vs;
    set vs_sorted;
    by usubjid;
    if first.usubjid then vsseq=1;
    else vsseq+1;
run;


/* Final VS */
proc sort data=vs out=sdtm.vs(label="Vital Signs");
    by studyid usubjid vsseq;
run;


/* Validation */
proc contents data=sdtm.vs;
run;

proc print data=sdtm.vs(obs=10);
run;

proc freq data=sdtm.vs;
    tables vstestcd vsblfl vspos / missing;
run;