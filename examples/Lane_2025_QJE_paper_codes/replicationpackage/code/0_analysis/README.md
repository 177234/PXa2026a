_This README for the `/code` directory was last updated: 2025-05-10__

# Stata Analysis Workflow (`code/0_analysis/`)
---

This directory contains main Stata scripts for the "Manufacturing Revolutions" project. The Stata scripts are executed `0_master_run_analysis.do`.

## Workflow

`0_master_run_analysis.do` sequentially executes three subordinate master scripts:
1. `1_main_scripts/0_1_master_run_main_analyses.do` (Main paper analyses)
2. `2_appendix_scripts/0_2_master_run_appendix_analyses.do` (Appendix analyses)
3. `3_suppappendix_scripts/0_3_master_run_supp_appendix_analyses.do` (Supplemental Appendix analyses)

Each subordinate master then calls individual `.do` files within its respective subdirectory.

## Usage

- **Error Handling:** The main driver (`0_master_run_analysis.do`) stops execution immediately if any script fails, propagating the error.
- **Logging:** All Stata output is directed to `log/0_master_run_all_analyses.log` in the project root when run via `0_master_run_analysis.do`.
- **Primary Input:** `data/input/`
- **Primary Output (Intermediate):** `intermediate_datasets/`

## Structure Overview

```
📁0_analysis/
├── 📄 0_master_run_analysis.do                     # Top-level Stata driver
├── 📁 1_main_scripts/                              # Main paper do files.
│   └── 📄 0_1_master_run_main_analyses.do          # Master for main
├── 📁 2_appendix_scripts/                          # Appendix  do files.
│   └── 📄 0_2_master_run_appendix_analyses.do      # Master for appendix
├── 📁 3_suppappendix_scripts/                      # Supplemental appendix do files.
│   └── 📄 0_3_master_run_supp_appendix_analyses.do # Master for supplemental
└── 📁 subdofiles/                                  # Utility/shared do-files
```

## Standalone Execution

Refer to the main project `README.md` and `/code/README.md` for complete replication instructions and context.


## Dependencies
- Stata 17 MP+
- Packages (installed by `setup/setup.do`): `reghdfe`, `ppmlhdfe`, `regsave`, `estout`, `ftools`, `csdid`, `drdid`, `erepost`, `binscatter`, `gph2xl`.

---
