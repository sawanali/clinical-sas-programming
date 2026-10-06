/* Create ADaM ADSL */
/* Libraries */
libname sdtm "YOUR_SDTM_PATH";
libname adam "YOUR_ADAM_PATH";

/* Create empty ADSL */
proc sql;
	create table empty_adsl
		(STUDYID char(12) label="Study Identifier", USUBJID char(11) 
		label="Unique Subject Identifier", SUBJID char(4) 
		label="Subject Identifier for the Study", SITEID char(3) 
		label="Study Site Identifier", SITEGR1 char(3) label="Pooled Site Group 1", 
		ARM char(20) label="Description of Planned Arm", TRT01P char(20) 
		label="Planned Treatment for Period 01", TRT01PN num 
		label="Planned Treatment for Period 01 (N)", TRT01A char(20) 
		label="Actual Treatment for Period 01", TRT01AN num 
		label="Actual Treatment for Period 01 (N)", TRTSDT num 
		label="Date of First Exposure to Treatment", TRTEDT num 
		label="Date of Last Exposure to Treatment", TRTDUR num 
		label="Duration of Treatment (days)", CUMDOSE num label="Cumulative Dose", 
		AVGDD num label="Average Daily Dose", AGE num label="Age", AGEGR1 char(5) 
		label="Pooled Age Group 1", AGEGR1N num label="Pooled Age Group 1 (N)", AGEU 
		char(6) label="Age Units", RACE char(78) label="Race", RACEN num 
		label="Race (N)", SEX char(1) label="Sex", ETHNIC char(25) label="Ethnicity", 
		SAFFL char(1) label="Safety Population Flag", ITTFL char(1) 
		label="Intent-to-Treat Population Flag", EFFFL char(1) 
		label="Efficacy Population Flag", COMP8FL char(1) 
		label="Completers of Week 8 Population Flag", COMP16FL char(1) 
		label="Completers of Week 16 Population Flag", COMP24FL char(1) 
		label="Completers of Week 24 Population Flag", DISCONFL char(1) 
		label="Did the Subject Discontinue the Study?", DSRAEFL char(1) 
		label="Discontinued due to AE?", DTHFL char(1) label="Subject Died?", BMIBL 
		num label="Baseline BMI", BMIBLGR1 char(20) label="Baseline BMI Category", 
		HEIGHTBL num label="Baseline Height", WEIGHTBL num label="Baseline Weight", 
		EDUCLVL num label="Education Level", DISONSDT num 
		label="Date of Disease Onset", DURDIS num label="Duration of Disease", 
		DURDSGR1 char(20) label="Duration of Disease Group", VISIT1DT num 
		label="Visit 1 Date", RFSTDTC char(20) 
		label="Subject Reference Start Date/Time", RFENDTC char(20) 
		label="Subject Reference End Date/Time", RFENDT num 
		label="Subject Reference End Date", VISNUMEN num label="Final Visit Number", 
		DCDECOD char(40) label="Disposition Reason", DCREASCD char(40) 
		label="Disposition Reason Category", MMSETOT num label="MMSE Total Score");
quit;

/* Import SUPPDM */

%let rawpath=YOUR_RAW_DATA_PATH;
libname xpt xport "&rawpath/suppdm.xpt";

data sdtm.suppdm;
	set xpt.suppdm;
run;

libname xpt clear;

/* Transpose SUPPDM */
proc transpose data=sdtm.suppdm out=suppdm_trans(drop=_:);
	by usubjid;
	var qval;
	id qnam;
	idlabel qlabel;
run;

/* Import QS */

%let rawpath=YOUR_RAW_DATA_PATH;
libname xpt xport "&rawpath/qs.xpt";

data sdtm.qs;
	set xpt.qs;
run;

libname xpt clear;

/* Efficacy records */
proc sql;
	create table qs_eff as select usubjid, max(case when qstestcd='ADASCOG' and 
		visitnum > 3 then 1 else 0 end) as adascog_post, max(case when 
		qstestcd='CIBIC' and visitnum > 3 then 1 else 0 end) as cibic_post from 
		sdtm.qs group by usubjid;
quit;

/* MMSE total */
proc sql;
	create table mmse_total as select usubjid, sum(input(qsorres, best32.)) as 
		mmsetot from sdtm.qs where qstestcd in ('MMITM01', 'MMITM02', 'MMITM03', 
		'MMITM04', 'MMITM05', 'MMITM06') group by usubjid;
quit;

/* Import SV */

%let rawpath=YOUR_RAW_DATA_PATH;
libname xpt xport "&rawpath/sv.xpt";

data sdtm.sv;
	set xpt.sv;
run;

libname xpt clear;

/* SV visit dates */
/* Visit 1 */
proc sql;
	create table sv_visit1 as select usubjid, svstdtc from sdtm.sv where 
		visitnum=1;
quit;

/* Visit 8 */
proc sql;
	create table sv_visit8 as select usubjid, svstdtc from sdtm.sv where 
		visitnum=8;
quit;

/* Visit 10 */
proc sql;
	create table sv_visit10 as select usubjid, svstdtc from sdtm.sv where 
		visitnum=10;
quit;

/* Visit 12 */
proc sql;
	create table sv_visit12 as select usubjid, svstdtc from sdtm.sv where 
		visitnum=12;
quit;

proc sql;
	create table sv_dose_intervals as select usubjid, max(case when visitnum=4 
		then input(substr(svstdtc, 1, 10), yymmdd10.) end) as visit4dt, max(case when 
		visitnum=12 then input(substr(svstdtc, 1, 10), yymmdd10.) end) as visit12dt 
		from sdtm.sv where visitnum in (4, 12) group by usubjid;
quit;

/* Import SC */

%let rawpath=YOUR_RAW_DATA_PATH;
libname xpt xport "&rawpath/sc.xpt";

data sdtm.sc;
	set xpt.sc;
run;

libname xpt clear;

/* Import MH */

%let rawpath=YOUR_RAW_DATA_PATH;
libname xpt xport "&rawpath/mh.xpt";

data sdtm.mh;
	set xpt.mh;
run;

libname xpt clear;

/* Combine DM, SUPPDM, and efficacy information */
proc sql;
	create table dm_suppdm as select a.*, b.COMPLT8, b.COMPLT16, b.COMPLT24, 
		b.EFFICACY, b.ITT, b.SAFETY, c.adascog_post, c.cibic_post, d.mmsetot from 
		sdtm.dm as a left join suppdm_trans as b on a.usubjid=b.usubjid left join 
		qs_eff as c on a.usubjid=c.usubjid left join mmse_total as d on 
		a.usubjid=d.usubjid;
quit;

/* Disposition event records */
proc sql;
	create table ds_disposition as select usubjid, dsstdtc, visitnum, dsterm, 
		dsdecod from sdtm.ds where dscat='DISPOSITION EVENT' order by usubjid, 
		dsstdtc;
quit;

/* Baseline height */
proc sql;
	create table vs_heightbl as select usubjid, vsstresn as heightbl from sdtm.vs 
		where vstestcd='HEIGHT' and visitnum=1;
quit;

/* Baseline weight */
proc sql;
	create table vs_weightbl as select usubjid, vsstresn as weightbl from sdtm.vs 
		where vstestcd='WEIGHT' and visitnum=3;
quit;

/* Combine DM, SUPPDM, disposition, visit dates, baseline measurements,
education level, and primary diagnosis date */
proc sql;
	create table dm_suppdm_ds as select a.*, b.dsstdtc, b.visitnum, b.dsterm, 
		b.dsdecod, c.svstdtc as svstdtc8, d.svstdtc as svstdtc10, e.svstdtc as 
		svstdtc12, j.svstdtc as svstdtc1, f.heightbl, g.weightbl, h.scstresn as 
		educlvl, i.mhstdtc, k.visit4dt, k.visit12dt from dm_suppdm as a left join 
		ds_disposition as b on a.usubjid=b.usubjid left join sv_visit8 as c on 
		a.usubjid=c.usubjid left join sv_visit10 as d on a.usubjid=d.usubjid left 
		join sv_visit12 as e on a.usubjid=e.usubjid left join vs_heightbl as f on 
		a.usubjid=f.usubjid left join vs_weightbl as g on a.usubjid=g.usubjid left 
		join sdtm.sc as h on a.usubjid=h.usubjid and h.sctestcd='EDLEVEL' left join 
		sdtm.mh as i on a.usubjid=i.usubjid and i.mhcat='PRIMARY DIAGNOSIS' left join 
		sv_visit1 as j on a.usubjid=j.usubjid left join sv_dose_intervals as k on 
		a.usubjid=k.usubjid;
quit;

/* Create final ADSL */
data adsl
	(keep=STUDYID USUBJID SUBJID SITEID SITEGR1 ARM TRT01P TRT01PN TRT01A TRT01AN 
		TRTSDT TRTEDT TRTDUR CUMDOSE AVGDD AGE AGEGR1 AGEGR1N AGEU RACE RACEN SEX 
		ETHNIC SAFFL ITTFL EFFFL COMP8FL COMP16FL COMP24FL DISCONFL DSRAEFL DTHFL 
		BMIBL BMIBLGR1 HEIGHTBL WEIGHTBL EDUCLVL DISONSDT DURDIS DURDSGR1 VISIT1DT 
		RFSTDTC RFENDTC RFENDT VISNUMEN DCDECOD DCREASCD MMSETOT);
	set empty_adsl dm_suppdm_ds;

	/* Date formats */
	format TRTSDT TRTEDT RFENDT DISONSDT VISIT1DT date9.;

	/* Treatment variables */
	TRT01P=strip(ARM);
	TRT01A=strip(ARM);

	/* Treatment codes */
	TRT01PN=.;
	TRT01AN=.;

	if ARMCD='Pbo' then
		do;
			TRT01PN=0;
			TRT01AN=0;
		end;
	else if ARMCD='Xan_Lo' then
		do;
			TRT01PN=1;
			TRT01AN=1;
		end;
	else if ARMCD='Xan_Hi' then
		do;
			TRT01PN=2;
			TRT01AN=2;
		end;

	/* Analysis site group */
	if SITEID in ('702', '706', '707', '711', '714', '715', '717') then
		SITEGR1='900';
	else
		SITEGR1=SITEID;

	/* Numeric race code */
	RACEN=.;

	if upcase(strip(RACE))='WHITE' then
		RACEN=1;
	else if upcase(strip(RACE))='BLACK OR AFRICAN AMERICAN' then
		RACEN=2;
	else if upcase(strip(RACE))='AMERICAN INDIAN OR ALASKA NATIVE' then
		RACEN=6;
	else if upcase(strip(RACE))='ASIAN' then
		RACEN=7;

	/* Age group */
	if AGE < 65 then
		do;
			AGEGR1='<65';
			AGEGR1N=1;
		end;
	else if 65 <=AGE <=80 then
		do;
			AGEGR1='65-80';
			AGEGR1N=2;
		end;
	else if AGE > 80 then
		do;
			AGEGR1='>80';
			AGEGR1N=3;
		end;

	/* Treatment start date */
	if ARMCD in ('Pbo', 'Xan_Lo', 'Xan_Hi') then
		do;

			if not missing(RFXSTDTC) then
				do;

					if length(RFXSTDTC) >=10 then
						TRTSDT=input(substr(RFXSTDTC, 1, 10), yymmdd10.);
					else
						do;
							TRTSDT=input(substr(RFSTDTC, 1, 10), yymmdd10.);
							TRTSDTF='M';
						end;
				end;
		end;

	/* Treatment end date */
	if ARMCD in ('Pbo', 'Xan_Lo', 'Xan_Hi') then
		do;

			if not missing(RFXENDTC) then
				do;

					if length(RFXENDTC) >=10 then
						TRTEDT=input(substr(RFXENDTC, 1, 10), yymmdd10.);
					else
						do;
							TRTEDT=input(substr(RFPENDTC, 1, 10), yymmdd10.);
							TRTEDTF='D';
						end;
				end;
			else
				do;
					TRTEDT=input(substr(RFPENDTC, 1, 10), yymmdd10.);
					TRTEDTF='D';
				end;
		end;

	/* Treatment duration */
	TRTDUR=.;

	if not missing(TRTSDT) and not missing(TRTEDT) then
		TRTDUR=TRTEDT - TRTSDT + 1;

	/* Cumulative dose */
	CUMDOSE=.;

	if TRT01PN in (0, 1) and not missing(TRTDUR) then
		CUMDOSE=TRT01PN*TRTDUR;
	else if TRT01PN=2 and not missing(TRTSDT) and not missing(TRTEDT) then
		do;

			/* First dosing interval */
			if not missing(VISIT4DT) and TRTEDT >=VISIT4DT then
				CUMDOSE=54*(VISIT4DT-TRTSDT+1);
			else
				CUMDOSE=54*(TRTEDT-TRTSDT+1);

			/* Second dosing interval */
			if not missing(VISIT4DT) and TRTEDT > VISIT4DT then
				do;

					if not missing(VISIT12DT) and TRTEDT >=VISIT12DT then
						CUMDOSE=CUMDOSE+81*(VISIT12DT-VISIT4DT);
					else
						CUMDOSE=CUMDOSE+81*(TRTEDT-VISIT4DT);
				end;

			/* Third dosing interval */
			if not missing(VISIT12DT) and TRTEDT > VISIT12DT then
				CUMDOSE=CUMDOSE+54*(TRTEDT-VISIT12DT);
		end;

	/* Average daily dose */
	AVGDD=.;

	if not missing(CUMDOSE) and not missing(TRTDUR) and TRTDUR > 0 then
		AVGDD=CUMDOSE/TRTDUR;

	/* Population flags */
	if ARMCD in ('Pbo', 'Xan_Lo', 'Xan_Hi') then
		ITTFL='Y';
	else
		ITTFL='N';

	if not missing(TRTSDT) then
		SAFFL='Y';
	else
		SAFFL='N';

	/* Efficacy population */
	if SAFFL='Y' and ADASCOG_POST=1 and CIBIC_POST=1 then
		EFFFL='Y';
	else
		EFFFL='N';

	/* Completers of Week 8 */
	COMP8FL='N';

	if not missing(SVSTDTC8) and not missing(ENDDT) then
		do;

			if ENDDT >=input(substr(SVSTDTC8, 1, 10), yymmdd10.) then
				COMP8FL='Y';
		end;

	/* Completers of Week 16 */
	COMP16FL='N';

	if not missing(SVSTDTC10) and not missing(ENDDT) then
		do;

			if ENDDT >=input(substr(SVSTDTC10, 1, 10), yymmdd10.) then
				COMP16FL='Y';
		end;

	/* Completers of Week 24 */
	COMP24FL='N';

	if not missing(SVSTDTC12) and not missing(ENDDT) then
		do;

			if ENDDT >=input(substr(SVSTDTC12, 1, 10), yymmdd10.) then
				COMP24FL='Y';
		end;

	/* Discontinuation flags */
	if not missing(DCREASCD) then
		do;

			if DCREASCD ne 'Completed' then
				DISCONFL='Y';
			else
				DISCONFL='N';
		end;

	/* Discontinued due to AE */
	if DCREASCD='Adverse Event' then
		DSRAEFL='Y';
	else
		DSRAEFL='N';

	/* Death flag */
	if DTHFL='Y' then
		DTHFL='Y';
	else
		DTHFL='N';

	/* Baseline BMI */
	if not missing(HEIGHTBL) and not missing(WEIGHTBL) and HEIGHTBL > 0 then
		BMIBL=WEIGHTBL / ((HEIGHTBL / 100)**2);

	/* BMI category */
	if not missing(BMIBL) then
		do;

			if BMIBL < 25 then
				BMIBLGR1='Normal';
			else if BMIBL < 30 then
				BMIBLGR1='Overweight';
			else
				BMIBLGR1='Obese';
		end;

	/* Disease onset date */
	if not missing(MHSTDTC) then
		DISONSDT=input(substr(MHSTDTC, 1, 10), yymmdd10.);

	/* Duration of disease */
	if not missing(VISIT1DT) and not missing(DISONSDT) then
		DURDIS=INTCK('MONTH', DISONSDT, VISIT1DT);

	/* Duration of disease group */
	if not missing(DURDIS) then
		do;

			if DURDIS < 12 then
				DURDSGR1='<12 Months';
			else
				DURDSGR1='>=12 Months';
		end;

	/* Visit 1 date */
	if not missing(SVSTDTC1) then
		VISIT1DT=input(substr(SVSTDTC1, 1, 10), yymmdd10.);

	/* Reference dates */
	RFENDT=.;

	if not missing(RFENDTC) then
		RFENDT=input(substr(RFENDTC, 1, 10), yymmdd10.);

	/* Final visit number */
	VISNUMEN=.;

	if VISITNUM=13 and upcase(strip(DSTERM))='PROTCOL COMPLETED' then
		VISNUMEN=12;
	else if upcase(strip(DSTERM))='PROTCOL COMPLETED' then
		VISNUMEN=VISITNUM;

	/* Disposition reason */
	DCDECOD=strip(DSDECOD);

	/* Disposition reason category */
	if upcase(strip(DCDECOD))='COMPLETED' then
		DCREASCD='Completed';
	else if upcase(strip(DCDECOD))='ADVERSE EVENT' then
		DCREASCD='Adverse Event';
	else if not missing(DCDECOD) then
		DCREASCD='Other';
run;

/* Save final ADSL */
data adam.adsl;
	set adsl;
run;

/* Validate ADSL */
proc contents data=adsl;
run;

proc print data=adsl(obs=20);
run;
