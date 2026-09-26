/* SDTM AE PROGRAM */

%let rawlib=YOUR_RAW_SAS_PATH;
%let sdtmpath=YOUR_SDTM_PATH;
libname raw "&rawlib";
libname sdtm "&sdtmpath";

/* CREATE EMPTY SHELL */
data empty_ae;
	length STUDYID   $20 DOMAIN    $2 USUBJID   $40 AESEQ 8 AESPID    $20 
		AETERM    $200 AELLT     $200 AELLTCD 8 AEDECOD   $200 AEPTCD 8 
		AEHLT     $200 AEHLTCD 8 AEHLGT    $200 AEHLGTCD 8 AEBODSYS  $200 AEBDSYCD 8 
		AESOC     $200 AESOCCD 8 AESEV     $20 AESER     $1 AEACN     $40 
		AEREL     $20 AEOUT     $40 AESCAN    $1 AESCONG   $1 AESDISAB  $1 
		AESDTH    $1 AESHOSP   $1 AESLIFE   $1 AESOD     $1 AEDTC     $20 
		AESTDTC   $20 AEENDTC   $20 AESTDY 8 AEENDY 8;
	label STUDYID="Study Identifier" DOMAIN="Domain Abbreviation" 
		USUBJID="Unique Subject Identifier" AESEQ="Sequence Number" 
		AESPID="Sponsor-Defined Identifier" 
		AETERM="Reported Term for the Adverse Event" AELLT="Lowest Level Term" 
		AELLTCD="Lowest Level Term Code" AEDECOD="Dictionary-Derived Term" 
		AEPTCD="Preferred Term Code" AEHLT="High Level Term" 
		AEHLTCD="High Level Term Code" AEHLGT="High Level Group Term" 
		AEHLGTCD="High Level Group Term Code" AEBODSYS="Body System or Organ Class" 
		AEBDSYCD="Body System or Organ Class Code" AESOC="Primary System Organ Class" 
		AESOCCD="Primary System Organ Class Code" AESEV="Severity/Intensity" 
		AESER="Serious Event" AEACN="Action Taken with Study Treatment" 
		AEREL="Causality" AEOUT="Outcome of Adverse Event" AESCAN="Involves Cancer" 
		AESCONG="Congenital Anomaly or Birth Defect" 
		AESDISAB="Persist or Signif Disability/Incapacity" AESDTH="Results in Death" 
		AESHOSP="Requires or Prolongs Hospitalization" AESLIFE="Is Life Threatening" 
		AESOD="Occurred with Overdose" AEDTC="Date/Time of Collection" 
		AESTDTC="Start Date/Time of Adverse Event" 
		AEENDTC="End Date/Time of Adverse Event" 
		AESTDY="Study Day of Start of Adverse Event" 
		AEENDY="Study Day of End of Adverse Event";
	stop;
run;

/*
The CDISC Pilot dataset contains the
SDTM AE dataset but not raw/EDC database.

The AE dataset is used for this portfolio. The original
source-to-SDTM mapping is documented below using the CRF
for the Xanomeline TTS study.

The AE CRF contains:
- Code
- COSTART Class Term
- Description of Condition/Event
- Relationship to Study Drug
- Visit Number
- Severity
- Onset Date
- Stop Date
- Serious during trial?
- Serious Codes

CRF severity codes:
1 = Mild
2 = Moderate
3 = Severe

CRF serious codes:
1 = Fatal
2 = Life-threatening
3 = Permanently disabling
4 = Hospitalization
5 = Congenital anomaly
6 = Cancer
7 = Overdose
8 = Other reason

CRF relationship codes:
1 = None
2 = Remote (Unlikely)
3 = Possible
4 = Probable

The coding logic below is for programming demonstration.
*/
data ae_raw;
	set raw.ae;
run;

/* RFSTDTC from DM */
proc sort data=sdtm.dm(keep=usubjid rfstdtc) out=dm_rfstdtc;
	by usubjid;
run;

proc sort data=ae_raw;
	by usubjid;
run;

/* CREATE AE DATASET */
data ae;
	merge ae_raw(in=ae) dm_rfstdtc;
	by usubjid;

	if ae;

	/* STUDYID
	Source: CRF
	studyid = "CDISCPILOT01";
	*/
	/* DOMAIN
	Assigned as "AE".
	*/
	/* USUBJID
	Derived from STUDYID, DM.SITEID and DM.SUBJID
	usubjid = cats(studyid, siteid, subjid);
	*/
	/* AESEQ
	Sequential number for AE records by USUBJID.
	Derived below.
	*/
	/* AESPID
	The CRF identifies each event with an event code
	such as E08, E09, E10, etc.
	
	aespid = "Code" of CRF
	*/
	/* AETERM
	aeterm = "Description of Condition/Event" of CRF
	*/
	/* AELLT, AELLTCD, AEDECOD, AEPTCD, AEHLT, AEHLTCD,
	AEHLGT, AEHLGTCD, AEBODSYS, AEBDSYCD, AESOC and AESOCCD
	
	MedDRA-derived variables.
	
	These are retained from the published AE dataset.
	*/
	/* AESEV
	CRF field: "Severity"
	
	Codes:
	1 = Mild
	2 = Moderate
	3 = Severe
	
	Coding:
	if Severity = 1 then aesev = "MILD";
	else if Severity = 2 then aesev = "MODERATE";
	else if Severity = 3 then aesev = "SEVERE";
	*/
	/* AESER
	CRF field: "Serious during trial?"
	Response: Y/N.
	*/
	/* Serious-event flags
	
	Code 1 = Fatal              -> AESDTH
	Code 2 = Life-threatening   -> AESLIFE
	Code 3 = Permanently disabling -> AESDISAB
	Code 4 = Hospitalization    -> AESHOSP
	Code 5 = Congenital anomaly -> AESCONG
	Code 6 = Cancer             -> AESCAN
	Code 7 = Overdose           -> AESOD
	Code 8 = Other reason
	
	Example coding:
	
	if index(serious_codes,"1") then aesdth  = "Y";
	if index(serious_codes,"2") then aeslife = "Y";
	if index(serious_codes,"3") then aesdisab = "Y";
	if index(serious_codes,"4") then aeshosp = "Y";
	if index(serious_codes,"5") then aescong = "Y";
	if index(serious_codes,"6") then aescan  = "Y";
	if index(serious_codes,"7") then aesod   = "Y";
	*/
	/* AEACN
	AEACN = null because data was not collected.
	*/
	aeacn="";

	/* AEREL
	CRF: "Relationship to Study Drug"
	
	Codes:
	1 = None
	2 = Remote (Unlikely)
	3 = Possible
	4 = Probable
	
	Coding:
	
	if relationship = 1 then aerel = "NONE";
	else if relationship = 2 then aerel = "REMOTE";
	else if relationship = 3 then aerel = "POSSIBLE";
	else if relationship = 4 then aerel = "PROBABLE";
	*/
	/* AEOUT
	Outcome of the adverse event.
	Retained from the AE dataset.
	*/
	/* AEDTC
	Date of final visit.
	Retained from the AE dataset.
	*/
	/* AESTDTC
	CRF field: "Onset Date"
	Source date is recorded as MM DD YY on the CRF.
	Published SDTM value retained as provided.
	
	Some dates may be partial, such as YYYY-MM or YYYY.
	If raw data were available, the available date
	components could be preserved without inventing
	missing month/day values.
	*/
	/* AEENDTC
	CRF field: "Stop Date"
	Source date is recorded as MM DD YY on the CRF.
	Published SDTM value retained as provided.
	*/
	/* STUDY DAY DERIVATION
	
	Study day is calculated only when a complete
	YYYY-MM-DD date is available.
	*/
	if length(aestdtc)=10 and length(rfstdtc)=10 then
		do;
			aestd=input(aestdtc, yymmdd10.);
			rfstd=input(rfstdtc, yymmdd10.);

			if not missing(aestd) and not missing(rfstd) then
				do;

					if aestd >=rfstd then
						aestdy=aestd-rfstd+1;
					else if aestd < rfstd then
						aestdy=aestd-rfstd;
				end;
		end;

	if length(aeendtc)=10 and length(rfstdtc)=10 then
		do;
			aeend=input(aeendtc, yymmdd10.);
			rfstd=input(rfstdtc, yymmdd10.);

			if not missing(aeend) and not missing(rfstd) then
				do;

					if aeend >=rfstd then
						aeendy=aeend-rfstd+1;
					else if aeend < rfstd then
						aeendy=aeend-rfstd;
				end;
		end;
	drop aestd aeend rfstd;
run;

/* AESEQ DERIVATION */
proc sort data=ae out=ae_sorted;
	by usubjid aestdtc aeendtc;
run;

data ae;
	set ae_sorted;
	by usubjid;

	if first.usubjid then
		aeseq=1;
	else
		aeseq+1;
run;

/* FINAL SDTM AE DATASET */
proc sort data=ae out=sdtm.ae(label="Adverse Events");
	by studyid usubjid aeseq;
run;

/* VALIDATION */
proc contents data=sdtm.ae;
run;

proc print data=sdtm.ae(obs=10);
run;

proc freq data=sdtm.ae;
	tables studyid domain aesev aeser aerel aeout / missing;
run;