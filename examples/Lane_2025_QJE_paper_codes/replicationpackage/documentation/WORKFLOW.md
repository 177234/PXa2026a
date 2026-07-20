---

# Replication Workflow – South Korea Industrial Policy Project
This file summarizes *what runs, in what order, and why*.

## 0 . Prerequisites
- R ≥ 4.3  (RStudio recommended)  
- Stata 17 +  
- `config.yml` correctly filled in  
  - `dirs:`  — relative paths used throughout the project  
  - `user_dirs:` — `stata_path`, `stata_version`  
  - `user_settings:` — `skip_stata: true|false`

Launch the workflow by running **`master.R`** from the project root (or
double-clicking the `.Rproj` file).

---

## 1. Main Workflow
The main workflow runs the project using `master.R`.

| Step | File(s) run                                       | Purpose / Key output                                       |
|:-----|:--------------------------------------------------|:-----------------------------------------------------------|
| 0    | `master.R`                                        | Sets root, opens `log/master.log`, reads `config.yml`      |
| 1    | `setup/setup.do`                                  | (Called by `master.R`) Install SSC packages,               |
|      |                                                   | verify Stata environment                                   |
| 2    | `code/0_analysis/0_master_run_analysis.do`        | (Called by `master.R`) Top-level Stata driver.             |
|      |                                                   | Executes all Stata analysis modules below.                 |
|      |                                                   | Creates `log/0_master_run_all_analyses.log`.               |
|      | ↳ `code/0_analysis/1_main_scripts/`               | Runs Main Stata analyses                                   |
|      |   `0_1_master_run_main_analyses.do`               |                                                            |
|      | ↳ `code/0_analysis/2_appendix_scripts/`           | Runs Appendix Stata analyses                               |
|      |   `0_2_master_run_appendix_analyses.do`           |                                                            |
|      | ↳ `code/0_analysis/3_suppappendix_scripts/`       | Runs Supplemental Stata analyses                           |
|      |   `0_3_master_run_supp_appendix_analyses.do`      |                                                            |
| 3    | `setup/setup.R`                                   | (Called by `master.R`) Install/load R pkgs,                |
|      |                                                   | fonts, helper fns                                          |
| 4    | `code/1_figures/0_master_run_figure.R`            | (Called by `master.R`) Generate figures                    |
| 5    | `code/2_tables/0_master_run_table.R`              | (Called by `master.R`) Generate tables                     |
| 6    | `code/3_appendix/0_master_run_appendix.R`         | (Called by `master.R`) Generate appendix                   |
|      |                                                   | tables/figures                                             |
| 7    | `code/4_suppappendix/0_master_run_suppappendix.R` | (Called by `master.R`) Generate supplemental               |
|      |                                                   |  appendix tables/figures                                   |
| 8    | `master.R` (wrap-up)                              | Close sinks, log elapsed time, clean memory                |

All R console output and high-level Stata calls are captured in `log/master.log`.
Detailed Stata execution is captured in `log/0_master_run_all_analyses.log`.

---


## 2. Run Individual Blocks

| Want to rerun workflow          | Do this                                                                                 |
|:--------------------------------|:----------------------------------------------------------------------------------------|
| Only Stata setup                | `RStata::stata("setup/setup.do")` (from R)                                              |
| Entire Stata Analysis Block     | `RStata::stata("code/0_analysis/0_master_run_analysis.do")` (from R)                    |
| Main Stata analyses only        | In Stata (see next)                                                                     |
| Only figures                    | `source("code/1_figures/0_master_run_figure.R")` (from R, ensure `setup.R` has run)     |
| Skip Stata entirely             | Set `skip_stata: true` in `config.yml`                                                  |

---


## 3. Alternative Workflows

The `entrypoints/` directory has files for running workflows in Stata.

| Approach                       | Do this                                     |
|:-------------------------------|:--------------------------------------------|
| Bootstrap `master.R` from Stata| Run `entrypoints/bootstrap_stata.do`         |

---

## 4. Troubleshooting

- Check `README.md`. Make sure project is setup.
- Check `log/master.log` (for R issues) and `log/0_master_run_all_analyses.log` (for Stata issues).  
- Missing project root? Best practice is to open `.Rproj`. Alternatively, 
  set working directory in R: `setwd("/full/path/to/your/project")`.
- Missing Stata? Edit `config.yml → user_dirs → stata_path`.
- Permissions errors on data/ or output/? Ensure the folders exist and
  are writable.  
- Package not found? Re-run `setup/setup.R` alone to (re)install R pkgs.

---
_Last updated: 2025-05-10_