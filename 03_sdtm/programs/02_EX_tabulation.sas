/* SDTM EX TABULATION */

%let rawlib=YOUR_RAW_SAS_PATH;
%let sdtmpath=YOUR_SDTM_PATH;
libname raw "&rawlib";
libname sdtm "&sdtmpath";

/* CREATE EMPTY SHELL */
data empty_ex;
	length STUDYID   $20 DOMAIN    $2 USUBJID   $40 EXSEQ 8 EXTRT     $20 EXDOSE 8 
		EXDOSU    $10 EXDOSFRM  $20 EXDOSFRQ  $10 EXROUTE   $30 VISITNUM 8 
		VISIT     $40 VISITDY 8 EXSTDTC   $20 EXENDTC   $20 EXSTDY 8 EXENDY 8;
	label STUDYID="Study Identifier" DOMAIN="Domain Abbreviation" 
		USUBJID="Unique Subject Identifier" EXSEQ="Sequence Number" 
		EXTRT="Name of Actual Treatment" EXDOSE="Dose per Administration" 
		EXDOSU="Dose Units" EXDOSFRM="Dose Form" 
		EXDOSFRQ="Dosing Frequency per Interval" EXROUTE="Route of Administration" 
		VISITNUM="Visit Number" VISIT="Visit Name" 
		VISITDY="Planned Study Day of Visit" EXSTDTC="Start Date/Time of Treatment" 
		EXENDTC="End Date/Time of Treatment" EXSTDY="Study Day of Start of Treatment" 
		EXENDY="Study Day of End of Treatment";
	stop;
run;

/* REQUIRED DATASET */
/*
The publicly available CDISC Pilot dataset contains
the SDTM EX dataset but not raw/EDC data.
*/
data ex_raw;
	set raw.ex;
run;

/* EXSEQ DERIVATION */
proc sort data=ex out=ex_sorted;
	by usubjid exstdtc;
run;

data ex;
	set ex_sorted;
	by usubjid;

	if first.usubjid then
		exseq=1;
	else
		exseq+1;
run;

/* POPULATE EX DATASET
Most of the variables are retained from the published EX
but the codes are shown as comments for demonstration */
*/

data ex;
set ex_raw;

/* STUDYID

Define:
Study Identifier

Origin:
CRF Page 7

The published Pilot reference value is retained. */
studyid="CDISCPILOT01";

/* DOMAIN

Define:
Domain Abbreviation

Origin:
Assigned
*/
domain="EX";

/* USUBJID

Define:
Unique Subject Identifier

Derivation:
Concatenation of STUDYID, DM.SITEID and DM.SUBJID
usubjid = cats(studyid, siteid, subjid);
*/
/* EXSEQ

Define:
Sequential number identifying records within each USUBJID

proc sort data=ex_raw;
by usubjid exstdtc;
run;

data ex;
set ex_raw;
by usubjid;

if first.usubjid then
exseq=1;
else
exseq+1;
run;
*/
/* EXTRT

Define:
Name of Actual Treatment

Controlled Terminology:
PLACEBO
XANOMELINE

extrt = upcase(raw_treatment);
*/
/* EXDOSE

Define:
Dose per Administration

If the original raw dose were character:

exdose = raw_dose;
*/
/* EXDOSU

Define:
Dose Units

Controlled Terminology:
EXDOSEU

Code value:
mg
*/
/* EXDOSFRM

Define:
Dose Form

Controlled Terminology:
EXDOSFRM

Code value:
PATCH
*/
/* EXDOSFRQ

Define:
Dosing Frequency per Interval

Controlled Terminology:
EXFREQ

Code value:
QD
*/
/* EXROUTE

Define:
Route of Administration

Controlled Terminology:
EXROUTE

Code value:
TRANSDERMAL
*/
/* VISITNUM

Define:
Visit Number

If original raw visit data were available,
VISITNUM would be assigned according to the
study-specific visit mapping.

Examples from the Define:

SCREENING 1        -> 1
SCREENING 2        -> 2
BASELINE           -> 3
WEEK 2             -> 4
WEEK 4             -> 5
WEEK 6             -> 7
WEEK 8             -> 8
WEEK 24            -> 12
WEEK 26            -> 13

Example SAS logic:

if visit="SCREENING 1" then visitnum=1;
else if visit="SCREENING 2" then visitnum=2;
else if visit="BASELINE" then visitnum=3;
else if visit="WEEK 2" then visitnum=4;
else if visit="WEEK 4" then visitnum=5;
else if visit="WEEK 6" then visitnum=7;
else if visit="WEEK 8" then visitnum=8;
else if visit="WEEK 24" then visitnum=12;
else if visit="WEEK 26" then visitnum=13;
*/
/* VISITDY

Define:
Planned Study Day of Visit

Derivation:
TV.VISITDY

proc sort data=tv;
by visitnum;
run;

proc sort data=ex_raw;
by visitnum;
run;

data ex;
merge ex_raw(in=a) tv(keep=visitnum visitdy);
by visitnum;
if a;
run;
*/
/* EXSTDTC

Define:
Start Date/Time of Treatment

Origin:
CRF Pages 25, 36, 42, 49, 52, 58, 67, 73,
82, 90, 99, 108, 116, 128

If the original raw treatment-start date were available:

exstdtc = put(raw_ex_start_date,yymmdd10.);
*/
/* EXENDTC

Define:
End Date of Treatment

Origin:
CRF Pages 105 and 138

If the original raw treatment-end date were available:

exendtc = put(raw_ex_end_date,yymmdd10.);
*/
/* EXSTDY

Define:
Study Day of Start of Treatment

Computational Method:
COMPMETHOD.STUDY_DAY

exstd = input(substr(exstdtc,1,10),yymmdd10.);
rfstd = input(substr(rfstdtc,1,10),yymmdd10.);

if exstd >= rfstd then
exstdy = exstd - rfstd + 1;
else if exstd < rfstd then
exstdy = exstd - rfstd;
*/
/* EXENDY

Define:
Study Day of End of Treatment

Computational Method:
COMPMETHOD.STUDY_DAY

exend = input(substr(exendtc,1,10),yymmdd10.);
rfstd = input(substr(rfstdtc,1,10),yymmdd10.);

if exend >= rfstd then
exendy = exend - rfstd + 1;
else if exend < rfstd then
exendy = exend - rfstd;
*/
run;

/* Final EX */
proc sort data=ex out=sdtm.ex(label="Exposure");
	by studyid usubjid exseq;
run;

/* VALIDATION */
proc contents data=sdtm.ex;
run;

proc print data=sdtm.ex(obs=10);
run;

proc freq data=sdtm.ex;
	tables studyid domain extrt exdosu exdosfrm exdosfrq exroute / missing;
run;