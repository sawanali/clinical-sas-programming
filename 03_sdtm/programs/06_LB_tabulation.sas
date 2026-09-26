/* SDTM LB program */

%let rawlib=YOUR_RAW_SAS_PATH;
%let sdtmpath=YOUR_SDTM_PATH;
libname raw "&rawlib";
libname sdtm "&sdtmpath";

/* Empty LB shell */

data empty_lb;
    length
        STUDYID $20 DOMAIN $2 USUBJID $40 LBSEQ 8 LBTESTCD $20
        LBTEST $200 LBCAT $40 LBORRES $100 LBORRESU $40
        LBORNRLO $100 LBORNRHI $100 LBSTRESC $100 LBSTRESN 8
        LBSTRESU $40 LBSTNRLO 8 LBSTNRHI 8 LBNRIND $20 LBBLFL $1
        VISITNUM 8 VISIT $100 VISITDY 8 LBDTC $30 LBDY 8;

    label
        STUDYID="Study Identifier"
        DOMAIN="Domain Abbreviation"
        USUBJID="Unique Subject Identifier"
        LBSEQ="Sequence Number"
        LBTESTCD="Lab Test or Examination Short Name"
        LBTEST="Lab Test or Examination Name"
        LBCAT="Category for Lab Test"
        LBORRES="Result or Finding in Original Units"
        LBORRESU="Original Units"
        LBORNRLO="Reference Range Lower Limit in Orig Unit"
        LBORNRHI="Reference Range Upper Limit in Orig Unit"
        LBSTRESC="Character Result/Finding in Std Format"
        LBSTRESN="Numeric Result/Finding in Standard Units"
        LBSTRESU="Standard Units"
        LBSTNRLO="Reference Range Lower Limit-Std Units"
        LBSTNRHI="Reference Range Upper Limit-Std Units"
        LBNRIND="Reference Range Indicator"
        LBBLFL="Baseline Flag"
        VISITNUM="Visit Number"
        VISIT="Visit Name"
        VISITDY="Planned Study Day of Visit"
        LBDTC="Date/Time of Specimen Collection"
        LBDY="Study Day of Specimen Collection";
    stop;
run;


/* DM for RFSTDTC */

proc sort data=sdtm.dm(keep=usubjid rfstdtc) out=dm_rfstdtc;
    by usubjid;
run;


/* Read LB and merge RFSTDTC */

data lb;
    merge raw.lb(in=lb)
          dm_rfstdtc;
    by usubjid;
    if lb;
run;


/* derivations */

data lb;
    set lb;

    if length(lbdtc) >= 10 and length(rfstdtc) >= 10 then do;
        lb_date = input(substr(lbdtc,1,10),yymmdd10.);
        rf_start = input(substr(rfstdtc,1,10),yymmdd10.);
        if not missing(lb_date) and not missing(rf_start) then
            lbdy = lb_date - rf_start + (lb_date >= rf_start);
    end;
    drop lb_date rf_start;
run;


/* Derive LBSEQ */

proc sort data=lb out=lb_sorted;
    by usubjid lbdtc lbtestcd;
run;

data lb;
    set lb_sorted;
    by usubjid;
    if first.usubjid then lbseq=1;
    else lbseq+1;
run;


/* Final LB dataset */

proc sort data=lb out=sdtm.lb(label="Laboratory Test Results");
    by studyid usubjid lbseq;
run;


/* Validation */

proc contents data=sdtm.lb;
run;

proc print data=sdtm.lb(obs=10);
run;

proc freq data=sdtm.lb;
    tables lbtestcd lbnrind lbblfl / missing;
run;