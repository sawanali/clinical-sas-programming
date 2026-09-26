
/* Import CDISC Pilot SDTM XPT files into SAS RAW library */

/* Set the paths before running the program */
%let rawpath=YOUR_RAW_DATA_PATH;
%let rawlib=YOUR_RAW_SAS_PATH;

libname raw "&rawlib";


/* DM - Demographics */
libname xpt xport "&rawpath/dm.xpt";
data raw.dm;
    set xpt.dm;
run;
libname xpt clear;


/* EX - Exposure */
libname xpt xport "&rawpath/ex.xpt";
data raw.ex;
    set xpt.ex;
run;
libname xpt clear;


/* AE - Adverse Events */
libname xpt xport "&rawpath/ae.xpt";
data raw.ae;
    set xpt.ae;
run;
libname xpt clear;


/* CM - Concomitant Medications */
libname xpt xport "&rawpath/cm.xpt";
data raw.cm;
    set xpt.cm;
run;
libname xpt clear;


/* DS - Disposition */
libname xpt xport "&rawpath/ds.xpt";
data raw.ds;
    set xpt.ds;
run;
libname xpt clear;


/* LB - Laboratory Test Results */
libname xpt xport "&rawpath/lb.xpt";
data raw.lb;
    set xpt.lb;
run;
libname xpt clear;


/* VS - Vital Signs */
libname xpt xport "&rawpath/vs.xpt";
data raw.vs;
    set xpt.vs;
run;
libname xpt clear;

