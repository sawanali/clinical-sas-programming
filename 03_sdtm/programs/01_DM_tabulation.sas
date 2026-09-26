/* SDTM DM - Demographics  */

%let rawlib=YOUR_RAW_SAS_PATH;
%let sdtmpath=YOUR_SDTM_PATH;
libname raw "&rawlib";
libname sdtm "&sdtmpath";

/* CREATE EMPTY SHELL */
data empty_dm;
	length STUDYID   $20 DOMAIN    $2 USUBJID   $40 SUBJID    $20 RFSTDTC   $20 
		RFENDTC   $20 RFXSTDTC  $20 RFXENDTC  $20 RFICDTC   $20 RFPENDTC  $20 
		DTHDTC    $20 DTHFL     $1 SITEID    $20 AGE 8 AGEU      $10 SEX       $1 
		RACE      $50 ETHNIC    $40 ARMCD     $20 ARM       $40 ACTARMCD  $20 
		ACTARM    $40 COUNTRY   $3 DMDTC     $20 DMDY 8;
	label STUDYID="Study Identifier" DOMAIN="Domain Abbreviation" 
		USUBJID="Unique Subject Identifier" SUBJID="Subject Identifier for the Study" 
		RFSTDTC="Subject Reference Start Date/Time" 
		RFENDTC="Subject Reference End Date/Time" 
		RFXSTDTC="Date/Time of First Study Treatment" 
		RFXENDTC="Date/Time of Last Study Treatment" 
		RFICDTC="Date/Time of Informed Consent" 
		RFPENDTC="Date/Time of End of Participation" DTHDTC="Date/Time of Death" 
		DTHFL="Subject Death Flag" SITEID="Study Site Identifier" AGE="Age" 
		AGEU="Age Units" SEX="Sex" RACE="Race" ETHNIC="Ethnicity" 
		ARMCD="Planned Arm Code" ARM="Description of Planned Arm" 
		ACTARMCD="Actual Arm Code" ACTARM="Description of Actual Arm" 
		COUNTRY="Country" DMDTC="Date/Time of Collection" 
		DMDY="Study Day of Collection";
	stop;
run;

/* REQUIRED DATASETS */
data dm_raw;
	set raw.dm;
run;

data ex;
	set raw.ex;
run;

data ds;
	set raw.ds;
run;

data ae;
	set raw.ae;
run;

/* DERIVE VARIABLES*/
/*Derive RFSTDTC and RFENDTC from EX
RFSTDTC = first study drug treatment date
RFENDTC = last study drug treatment date */
proc sql;
	create table ex_dates as 
	select usubjid, min(exstdtc) as rfstdtc, max(exendtc) as rfendtc 
	from ex 
	group by usubjid;
quit;

/* Derive RFPENDTC from DS
RFPENDTC = DSSTDTC of the last disposition event */
proc sql;
	create table ds_dates as
	select usubjid, max(dsstdtc) as rfpEndtc  
	from ds 
	group by usubjid;
quit;

/* Subjects with a death dsdecod */

data death_subjects;
    set raw.ds;
    if upcase(dsdecod) = "DEATH";
    keep usubjid;
run;

proc sort data=death_subjects nodupkey;
    by usubjid;
run;


/* AE record corresponding to the death */
proc sort data=raw.ae out=ae_sorted;
    by usubjid;
run;

data death_ae;
    merge death_subjects(in=death)
          ae_sorted(in=ae);
    by usubjid;
    if death and ae;
    if index(upcase(aeterm),"DEATH") > 0
       or index(upcase(aedecod),"DEATH") > 0;
run;


/* Derive DTHDTC and DTHFL */
proc sql;
    create table death_dates as
    select usubjid, aeendtc as dthdtc, "Y" as dthfl
    from death_ae;
quit;

/* POPULATE DM DATASET */
data dm;
	merge dm_raw ex_dates ds_dates death_dates;
	by usubjid;

	/* Study Identifier */
	studyid="CDISCPILOT01";

	/* Domain */
	domain="DM";

	/* USUBJID
	Define file:
	Concatenation of STUDYID, DM.SITEID and DM.SUBJID */

	/* RFSTDTC
	date/time of first study drug treatment*/
	/* RFSTDTC comes from EX_DATES */
	/* RFENDTC
	Derived from EX:
	date/time of last study drug treatment*/
	/* RFENDTC comes from EX_DATES */
	
	/* RFXSTDTC
	RFXSTDTC = RFSTDTC */
	rfxstdtc=rfstdtc;

	/* RFXENDTC
	RFXENDTC = RFENDTC */
	rfxendtc=rfendtc;

	/* RFICDTC
	
	Define file:
	Date of informed consent was not entered in database */
	rficdtc="";

	/* RFPENDTC
	Derived from DS:
	DSSTDTC of last disposition event */


	/* DTHFL
	If DSDECOD = DEATH, DTHFL = Y.
	from the death_dates */

	/* DTHDTC
	Define:
	If DS record exists with DSDECOD="DEATH",
	DTHDTC = AEENDTC */
	
	/* AGE
	
	Define:
	Subject's age at start of study drug (RFSTDTC).
	
	The Original birthdate source is not available in the Pilot source datasets */
	
	/* AGEU
	Define:
	AGEU = YEARS */
	ageu="YEARS";

	/* SEX
	
	blankCRF:
	F = Female
	M = Male
	
	SDTM:
	F = Female
	M = Male
	U = Unknown
	
	Existing DM value is retained */
	if sex="F" then
		sex="F";
	else if sex="M" then
		sex="M";

	/* RACE
	
	Source CRF variable = Origin.

	The Origin variable is not present in the
	available SDTM XPT datasets, so the mappings
	cannot be done here */
	
	/* ETHNIC
	
	The variable is not available in the
	published SDTM XPT datasets */
	
	/* ARMCD / ARM
	
	Define:
	According to randomization list.
	The randomization-list source is not available
	in the datasets.
	Existing DM values are retained */
	
	/* ACTARMCD / ACTARM
	
	Define:
	Derived from EX.
	Existing reference DM values are retained*/
	
	/* COUNTRY
	Define:
	Derived from site information.
	Pilot COUNTRY reference terminology contains:
	USA = USA  */
	country="USA";

	/* DMDTC
	DMDTC is collected on CRF Page 7.
	
	Existing reference DM value is retained */
	
	/* DMDY
	Study-day convention:
	
	If DMDTC >= RFSTDTC:
	DMDY = DMDTC - RFSTDTC + 1
	If DMDTC < RFSTDTC:
	DMDY = DMDTC - RFSTDTC
	--------------------------------------------------------*/
	if not missing(dmdtc) and not missing(rfstdtc) then
		do;
			dmdt=input(substr(dmdtc, 1, 10), yymmdd10.);
			rfstdt=input(substr(rfstdtc, 1, 10), yymmdd10.);

			if dmdt >=rfstdt then
				dmdy=dmdt - rfstdt + 1;
			else if dmdt < rfstdt then
				dmdy=dmdt - rfstdt;
		end;
	drop dmdt rfstdt;
run;

proc sort data=DM out=SDTM.DM(label='Demographics');
by studyid usubjid subjid;
run;



/* VALIDATION */

proc contents data=sdtm.dm;
run;

proc print data=sdtm.dm(obs=10);
run;

proc freq data=sdtm.dm;
    tables studyid domain sex race ethnic country / missing;
run;