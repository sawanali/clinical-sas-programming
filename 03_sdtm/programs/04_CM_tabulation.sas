/* SDTM CM program */

%let rawlib=YOUR_RAW_SAS_PATH;
%let sdtmpath=YOUR_SDTM_PATH;
libname raw "&rawlib";
libname sdtm "&sdtmpath";

/* Empty CM shell */

data empty_cm;
    length
        STUDYID  $20 DOMAIN $2 USUBJID $40 CMSEQ 8 CMSPID $40 CMTRT $200
        CMDECOD $200 CMINDC $200 CMCLAS $200 CMDOSE 8 CMDOSU $40
        CMDOSFRQ $40 CMROUTE $40 VISITNUM 8 VISIT $100 VISITDY 8 CMDTC $30
        CMSTDTC $30 CMENDTC $30 CMSTDY 8 CMENDY 8;

    label
        STUDYID="Study Identifier"
        DOMAIN="Domain Abbreviation"
        USUBJID="Unique Subject Identifier"
        CMSEQ="Sequence Number"
        CMSPID="Sponsor-Defined Identifier"
        CMTRT="Reported Name of Drug, Med, or Therapy"
        CMDECOD="Standardized Medication Name"
        CMINDC="Indication"
        CMCLAS="Medication Class"
        CMDOSE="Dose per Administration"
        CMDOSU="Dose Units"
        CMDOSFRQ="Dosing Frequency per Interval"
        CMROUTE="Route of Administration"
        VISITNUM="Visit Number"
        VISIT="Visit Name"
        VISITDY="Planned Study Day of Visit"
        CMDTC="Date/Time of Collection"
        CMSTDTC="Start Date/Time of Medication"
        CMENDTC="End Date/Time of Medication"
        CMSTDY="Study Day of Start of Medication"
        CMENDY="Study Day of End of Medication";
    stop;
run;


/* DM for RFSTDTC */

proc sort data=sdtm.dm(keep=usubjid rfstdtc) out=dm_rfstdtc;
    by usubjid;
run;


/* Read CM and merge RFSTDTC */

data cm;
    merge raw.cm(in=cm)
          dm_rfstdtc;
    by usubjid;
    if cm;
run;


/* Derive study days */

data cm;
    set cm;
    if length(cmstdtc) >= 10 and length(rfstdtc) >= 10 then do;
        cm_start = input(substr(cmstdtc,1,10),yymmdd10.);
        rf_start = input(substr(rfstdtc,1,10),yymmdd10.);
        if not missing(cm_start) and not missing(rf_start) then
            cmstdy = cm_start - rf_start + (cm_start >= rf_start);
    end;

    if length(cmendtc) >= 10 and length(rfstdtc) >= 10 then do;
        cm_end = input(substr(cmendtc,1,10),yymmdd10.);
        rf_start = input(substr(rfstdtc,1,10),yymmdd10.);
        if not missing(cm_end) and not missing(rf_start) then
            cmendy = cm_end - rf_start + (cm_end >= rf_start);
    end;
    drop cm_start cm_end rf_start;
run;


/* Derive CMSEQ */

proc sort data=cm out=cm_sorted;
    by usubjid cmstdtc cmendtc;
run;

data cm;
    set cm_sorted;
    by usubjid;
    if first.usubjid then cmseq=1;
    else cmseq+1;
run;


/* Final SDTM CM dataset */

proc sort data=cm out=sdtm.cm(label="Concomitant Medications");
    by studyid usubjid cmseq;
run;


/* Validation */

proc contents data=sdtm.cm;
run;

proc print data=sdtm.cm(obs=10);
run;

proc freq data=sdtm.cm;
    tables cmseq / missing;
run;