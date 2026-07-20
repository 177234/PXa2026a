# /code/ Directory - Analysis Workflow

This directory contains all code for the South Korean industrial policy replication package, organized in a two-stage workflow:

1. **Stata Analysis (0_analysis/)**: Executes statistical analyses and generates intermediate datasets
2. **R Output Generation (1_figures/, 2_tables/, etc.)**: Creates publication-ready figures and tables

These scripts are executed by the `master.R` driver script.

## Directory Structure

```
📁code/
├── 📁 0_analysis/                        # Stata analysis scripts
│   └── 📄 0_master_run_analysis.do       # Ⓜ️ Top-level Stata driver
│   ├── 📁 1_main_scripts/                # Main paper results
│   ├── 📁 2_appendix_scripts/            # Appendix results
│   ├── 📁 3_suppappendix_scripts/        # Supplemental appendix results
│   └── 📁 subdofiles/                    # Utility do-files
├── 📁 1_figures/                         # R scripts for main paper figures
│   └── Ⓜ️ 0_master_run_figure.R
├── 📁 2_tables/                          # R scripts for main paper tables
│   └── Ⓜ️ 0_master_run_table.R
├── 📁 3_appendix/                        # R scripts for appendix outputs
│   └── Ⓜ️ 0_master_run_appendix.R
└── 📁 4_suppappendix/                    # R scripts for supplemental appendix outputs
    └── Ⓜ️ 0_master_run_suppappendix.R
```


## Workflow Summary

1. **Stata Workflow** (`0_analysis/`):
   - Entry point: `0_master_run_analysis.do` 
   - Calls three subordinate masters to analyze main paper, appendix, and supplemental appendix
   - Outputs intermediate datasets to `intermediate_datasets/`
   - Dependencies: Stata 17+ with packages `reghdfe`, `ppmlhdfe`, `regsave`, `estout`, etc.

2. **R Output Generation**:
   - Each section has its own master R script (e.g., `0_master_run_figure.R`)
   - Processes intermediate data into publication-ready outputs
   - Saves outputs to `output/` directory

## Execution

The entire workflow is orchestrated by `master.R` in the project root.

For detailed Stata workflow information, see `0_analysis/README.md`.

---
