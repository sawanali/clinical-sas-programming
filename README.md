# Clinical SAS Programming

This is a personal project to practice clinical trial programming using SAS and CDISC standards.

The project uses the publicly available CDISC SDTM/ADaM Pilot Project (CDISCPILOT01) as the reference study.

The XPT datasets used as input for this project are the SDTM datasets provided in the CDISC Pilot file.

Because the datasets used here are already in SDTM format, the programming in this project focuses on reproducing the type of raw-to-SDTM derivation logic that would be used in a clinical trial programming process, using the available CRF information, Define metadata, and controlled terminology.

## Current work

### SDTM

The current stage focuses on SDTM dataset programming.

Domains completed:

- DM - Demographics
- AE - Adverse Events
- EX - Exposure
- CM - Concomitant Medications
- DS - Disposition
- LB - Laboratory Test Results
- VS - Vital Signs

The programs include dataset creation, variable derivations, study day calculations, and basic validation.

## Next step

- ADaM and TLF generation
