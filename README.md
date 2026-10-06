# Clinical SAS Programming

This is a personal project to practice clinical trial programming using SAS and CDISC standards.

The project uses the publicly available CDISC SDTM/ADaM Pilot Project (CDISCPILOT01) as the reference study.

The XPT datasets used as input for this project are the SDTM datasets provided in the CDISC Pilot submission package.

Because the datasets used here are already in SDTM format, the SDTM programming in this project focuses on reproducing the type of raw-to-SDTM derivation logic that would be applied in a clinical trial programming process, using the available CRF information, Define metadata, and controlled terminology.

## Current work

### SDTM

The SDTM programming stage includes the following completed domains:

- DM - Demographics
- AE - Adverse Events
- EX - Exposure
- CM - Concomitant Medications
- DS - Disposition
- LB - Laboratory Test Results
- VS - Vital Signs

The programs include dataset creation, variable derivations, study day calculations, sequencing, and basic validation.

### ADaM

The ADaM programming stage includes:

- ADSL - Subject-Level Analysis Dataset

The ADSL program contains treatment assignment and treatment dates, treatment duration, cumulative and average daily dose, demographic variables, analysis population flags, treatment completion flags, discontinuation variables, baseline measurements, BMI derivation, disease duration, disposition information, and other subject-level analysis variables.

The ADSL dataset is derived from the available SDTM domains and supplemental qualifier data, using study metadata and analysis derivation rules from the CDISC Pilot materials.

## Next steps

- ADAE - Adverse Events Analysis Dataset
- ADLB - Laboratory Analysis Dataset
- ADVS - Vital Signs Analysis Dataset
- TLF generation
