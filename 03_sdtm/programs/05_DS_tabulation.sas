/* SDTM DS program */
%let rawlib=YOUR_RAW_SAS_PATH;
%let sdtmpath=YOUR_SDTM_PATH;
libname raw "&rawlib";
libname sdtm "&sdtmpath";

/* Empty DS shell */

data empty_ds;
    length
        STUDYID $20 DOMAIN $2 USUBJID $40 DSSEQ 8 DSSPID $40
        DSTERM $200 DSDECOD $200 DSCAT $40 VISITNUM 8 VISIT $100
        DSDTC $30 DSSTDTC $30 DSSTDY 8;

    label
        STUDYID="Study Identifier"
        DOMAIN="Domain Abbreviation"
        USUBJID="Unique Subject Identifier"
        DSSEQ="Sequence Number"
        DSSPID="Sponsor-Defined Identifier"
        DSTERM="Reported Term for the Disposition Event"
        DSDECOD="Standardized Disposition Term"
        DSCAT="Category for Disposition Event"
        VISITNUM="Visit Number"
        VISIT="Visit Name"
        DSDTC="Date/Time of Collection"
        DSSTDTC="Start Date/Time of Disposition Event"
        DSSTDY="Study Day of Start of Disposition Event";
    stop;
run;


/* DM for RFSTDTC */

proc sort data=sdtm.dm(keep=usubjid rfstdtc) out=dm_rfstdtc;
    by usubjid;
run;


/* Read DS and merge RFSTDTC */

data ds;
    merge raw.ds(in=ds)
          dm_rfstdtc;
    by usubjid;
    if ds;
run;


/* Derive study day */

data ds;
    set ds;

    if length(dsstdtc) >= 10 and length(rfstdtc) >= 10 then do;
        ds_start = input(substr(dsstdtc,1,10),yymmdd10.);
        rf_start = input(substr(rfstdtc,1,10),yymmdd10.);
        if not missing(ds_start) and not missing(rf_start) then
            dsstdy = ds_start - rf_start + (ds_start >= rf_start);
    end;
    drop ds_start rf_start;
run;


/* Derive DSSEQ */

proc sort data=ds out=ds_sorted;
    by usubjid dsstdtc;
run;

data ds;
    set ds_sorted;
    by usubjid;
    if first.usubjid then dsseq=1;
    else dsseq+1;
run;


/* Final DS dataset */

proc sort data=ds out=sdtm.ds(label="Disposition");
    by studyid usubjid dsseq;
run;


/* Validation */

proc contents data=sdtm.ds;
run;

proc print data=sdtm.ds(obs=10);
run;

proc freq data=sdtm.ds;
    tables dsdecod dscat / missing;
run;