# phenominer-qc-pipeline

QC and auto-correction pipeline for the PhenoMiner curated experimental-record dataset.
Reports integrity problems and, where the inference is safe, fills in missing values
directly in the database.

## What it does

The pipeline runs a fixed sequence of checks against the PhenoMiner tables
(`EXPERIMENT_RECORD`, `SAMPLE`, `CLINICAL_MEASUREMENT`, `EXPERIMENT_CONDITION`,
`PHENOMINER_STANDARD_UNITS`, `PHENOMINER_TERM_UNIT_SCALES`, `PHENOMINER_UNIT_SCALES`).
Each step writes its details to a dedicated log file; the status log summarizes counts.

### Read-only audits

| Check | Description | Audit log |
| --- | --- | --- |
| **XCO:0000022 short durations** | Reports experiment records using the "controlled sodium diet" condition (`XCO:0000022`) with a duration under 1 minute — these are almost certainly data-entry errors and are linked back via PhenoMiner edit URLs. | `xco22_duration` |
| **Null unit conversions** | Flags rows in `PHENOMINER_TERM_UNIT_SCALES` where `TERM_SPECIFIC_SCALE` or `ZERO_OFFSET` is null. | `null_unit_conversion` |
| **Invalid RSO usage** | Lists active rat-strain ontology terms (`RS:*`) referenced by curated samples but lacking the canonical "RGD ID" synonym — usually deprecated strain identifiers. | `invalid_rso_usage` |
| **CMO terms missing standard units** | Lists CMO terms used in curated records (`CURATION_STATUS=40`) that do not yet appear in `PHENOMINER_STANDARD_UNITS`, ordered by record count. | `cmo_missing_standard_units` |
| **Undefined unit conversions** | Lists `(CMO term, measurement_units, standard_unit)` combinations for which no row exists in `PHENOMINER_TERM_UNIT_SCALES`, ordered by affected-record count. | `undefined_conversions` |

### Mutations

| Step | Action | Audit log |
| --- | --- | --- |
| **Auto-register standard units** | For each CMO term that has exactly one distinct `MEASUREMENT_UNITS` value across its curated records, insert that value into `PHENOMINER_STANDARD_UNITS` and a 1:1 conversion row into `PHENOMINER_TERM_UNIT_SCALES`. | `new_standard_units` |
| **Backfill PHENOMINER_TERM_UNIT_SCALES** | Update existing rows' `UNIT_TO` to match the registered standard unit, and insert any missing `(unit_from, unit_to)` pairs derivable from `PHENOMINER_UNIT_SCALES`. | (status log) |
| **Derive MEASUREMENT_SEM / SD / NUMBER_OF_ANIMALS** | For curated records with two of the three values present, derive the third: `SEM = SD / sqrt(NOA)`, `SD = SEM × sqrt(NOA)`, `NOA = (SD / SEM)²`. | `sem_sd_noa` |

## Run

```
./run.sh
```

Connects via Spring config in `properties/AppConfigure.xml`; logging output is configured
in `properties/log4j2.xml`.

## Build

Requires Java 17.

```
./gradlew clean assembleDist
```
