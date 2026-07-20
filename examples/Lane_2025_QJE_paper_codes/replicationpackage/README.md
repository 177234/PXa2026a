---

# Project Title: Manufacturing Revolutions: Industrial Policy and Industrialization in South Korea

---


----    
## Replication: "Manufacturing Revolutions: Industrial Policy and Industrialization in South Korea"

**Author(s):** Nathan Lane
**Date of this README:** 2025-05-11
**Version of Replication Package:** 1.0
**Manuscript Reference (if available):** QJE Accepted
**Corresponding Author Contact:** nathaniel.lane@economics.ox.ac.uk

This replication package contains the data (where permissible) and code necessary to reproduce the findings, tables, and figures presented in the manuscript titled "Manufacturing Revolutions: Industrial Policy and Industrialization in South Korea".

----    
## Table of Contents

- [Replication: "Manufacturing Revolutions: Industrial Policy and Industrialization in South Korea"](#replication-manufacturing-revolutions-industrial-policy-and-industrialization-in-south-korea)
- [Table of Contents](#table-of-contents)
- [Overview](#overview)
  - [Quick Start Guide](#quick-start-guide)
    - [Prerequisites](#prerequisites)
    - [Steps](#steps)
- [Data Availability and Provenance](#data-availability-and-provenance)
  - [Statement about Rights](#statement-about-rights)
  - [License for Data (if applicable)](#license-for-data-if-applicable)
  - [Summary of Data Availability](#summary-of-data-availability)
  - [Details on Each Data Source](#details-on-each-data-source)
  - [Dataset List and Description](#dataset-list-and-description)
    - [Input Data](#input-data)
    - [Input Data (derivatives of core data)](#input-data-derivatives-of-core-data)
    - [Input Data Supplemental (derivatives of core data)](#input-data-supplemental-derivatives-of-core-data)
    - [Intermediate Data (produced in replication)](#intermediate-data-produced-in-replication)
    - [Intermediate Data (non-public)](#intermediate-data-non-public)
  - [Output: Final Data Produced by Replication](#output-final-data-produced-by-replication)
    - [Output: Main Figures](#output-main-figures)
    - [Output: Main Tables](#output-main-tables)
    - [Output: Appendix Figures and Tables](#output-appendix-figures-and-tables)
    - [Output: Supplemental Appendix Figures and Tables](#output-supplemental-appendix-figures-and-tables)
- [Computational Requirements](#computational-requirements)
  - [Software Requirements](#software-requirements)
  - [Package Installation and Environment Setup](#package-installation-and-environment-setup)
    - [Stata Packages](#stata-packages)
    - [R Packages](#r-packages)
  - [Controlled Randomness](#controlled-randomness)
  - [Hardware Requirements](#hardware-requirements)
  - [Memory, Estimated Runtime, and Storage Requirements](#memory-estimated-runtime-and-storage-requirements)
- [Summary of Replication Workflow](#summary-of-replication-workflow)
  - [Directory Structure](#directory-structure)
  - [Key Code](#key-code)
- [Instructions to Replicators](#instructions-to-replicators)
  - [Prerequisites](#prerequisites-1)
  - [Step-by-Step Replication Workflow](#step-by-step-replication-workflow)
  - [Expected Output and Verification](#expected-output-and-verification)
  - [Configuring Project (config.yml)](#configuring-project-configyml)
- [Code Details](#code-details)
  - [Stata Analysis](#stata-analysis)
    - [1. The Main Stata Analysis](#1-the-main-stata-analysis)
    - [2. The Appendix Stata Analysis](#2-the-appendix-stata-analysis)
    - [3. The Supplemental Appendix Stata Analysis](#3-the-supplemental-appendix-stata-analysis)
  - [R Output Generation](#r-output-generation)
    - [Main Figures and Tables Generation](#main-figures-and-tables-generation)
    - [Appendix Figures and Tables Generation](#appendix-figures-and-tables-generation)
    - [Supplemental Appendix Figures and Tables Generation](#supplemental-appendix-figures-and-tables-generation)
- [Data Citations](#data-citations)

---
## Overview

This is the replication package for the paper "Manufacturing Revolutions: Industrial Policy and Industrialization in South Korea" by Nathan Lane. Code for analysis and export of results is provided as part of this package. We provide details of the project in this `README.md.`

The workflow involves running `master.R`, which is the main script that runs the entire analysis and generates the tables and figures for each section of the paper (main, appendix, and supplementary appendix). The workflow performed by `master.R` : 1) sets up the project environment, 2) runs the analysis in Stata, and 3) creates tables and figures in R. 


### Quick Start Guide
This guide outlines the simplest way to open and run the replication using RStudio.

#### Prerequisites
 - R >= 4.3  (RStudio recommended)  
 - Stata 17+


#### Steps

1. **Download and Unzip:**  
    Download the replication package .zip file and unzip it into a folder on your computer.

2. **Set up config.yml:**  
    - Navigate to the unzipped project folder.
    - Open `config.yml` in any text editor
    - Set the path to your Stata installation (e.g. `stata_path: /Applications/StataMP.app/Contents/MacOS/stata-mp`)
    - Set the version of Stata you are using (e.g. `stata_version: 17`)
    - Save the `config.yml`.

3. **Open the Project in RStudio:**  
    - Open the `replicationpackage.Rproj` file in RStudio. 
    - This will automatically set the project's working directory correctly.  
    
4.  **Run the master.R Script:**  
    - From the RStudio interface, open `master.R` (if it's not already open) and execute the entire script. 
    - You can typically do this by clicking "Source" or by selecting all code (Ctrl/Cmd+A) and running it (Ctrl/Cmd+Enter).
  
The replication of this package will usually take **at least an hour** on a current Apple M3 Macbook Pro. Please allow time for the Stata analysis to complete.


## Data Availability and Provenance

This section details the origin (provenance), location, and accessibility (data availability) of all data used in the article. Sources for all data is provided below. 

- [x] This paper does not involve analysis of external data (i.e., no data are used, or the only data are generated by the authors via simulation in their code).


### Statement about Rights

- [x] I certify that the author(s) of the manuscript have legitimate access to and permission to use all data used in this manuscript.
- [x] I certify that the author(s) of the manuscript have documented permission to redistribute/publish the data contained within this replication package, where applicable. 

### License for Data (if applicable)

> Describe the license(s) under which any provided data are distributed. If multiple licenses apply to different datasets, specify them. Refer to a `LICENSE.txt` file for full license texts.
*Example:* Data provided in this package are licensed under [e.g., Creative Commons CC-BY 4.0, MIT License for specific derived datasets, or refer to original source licenses]. See `LICENSE.txt` for details. Some data are subject to the original provider's terms of use, as detailed below.

### Summary of Data Availability

- [ ] All data **are** publicly available and included in this package or directly downloadable from public repositories.
- [X] Some data **cannot be made** publicly available due to [e.g., confidentiality, proprietary restrictions, IRB protocols]. Instructions for accessing these data are provided below.
- [ ] **No data can be made** publicly available. Instructions for accessing these data (if possible) are provided below.

*If some or no data can be made publicly available:*
- [X] Confidential/restricted data used in this paper and not provided as part of the public replication package will be preserved for [Number] years after publication at [Location/Institution, e.g., ICPSR, author's institution under a data management plan], in accordance with journal policies and data use agreements. Access may be requested via [Contact Person/Office and Procedure].

### Details on Each Data Source

**Core Datasets and Sources**

Below is a list of input datasets, their source, and their inclusion in project for main inputs in `data/input/`.

| Data Source                  | File(s) in Package                                            | Format | Location    | Here? | Citation                 |
|:-----------------------------|:--------------------------------------------------------------|:-------|:------------|:------|:-------------------------|
| UN COMTRADE                  | `comtrade_worldsitc_panel_cleaned4reg_4digit.dta`             | .dta   | input/      | ✓     | United Nations*          |
| UN COMTRADE                  | `comtrade_worldsitc_panel_cleaned4reg_4digit_prob_HCIonly.dta`| .dta   | input/      | ✓     | ...                      |
| UN COMTRADE & MMS            | `comtrade_merged_harmonized_panel_cleaned4reg_4digit.dta`     | .dta   | input/      | ✓     | ...                      |
| MMS Digitized                | `mms_merged_harmonized_panel_cleaned4reg_4digit.dta`          | .dta   | input/      | ✓     | Economic Planning Board* |
| MMS Digitized                | `mms_merged_harmonized_panel_cleaned4reg_5digit.dta`          | .dta   | input/      | ✓     | ...                      |
| MMS Microdata                | `mms_TFP_micro.dta`                                           | .dta   |             |       | Statistics Korea*        |


| Data Source                  | File(s) in Package                                            | Format | Location    | Here? | Citation                 |
|:-----------------------------|:--------------------------------------------------------------|:-------|:------------|:------|:-------------------------|
| Economic Statistics Yearbook | `policy_commercialbanking_yearbook_loans.csv`                 | .csv   | input/      | ✓     | Bank of Korea*           |
| Economic Statistics Yearbook | `policy_kdbbanking_yearbook_loans.csv`                        | .csv   | input/      | ✓     | ...                      |
| Luedde-Neurath (1982)        | `tariffs.csv`                                                 | .csv   | policydata/ | ✓     | Luedde-Neurath (1982)    |
| Korean Development Institute | `policy_taxes.csv`                                            | .csv   | input/      | ✓     | Kwack (1984,1985)        |
| Gov. Law Information Center  | `acts_table_simple_combined_all.csv`                          | .csv   | policydata/ | ✓     | Republic of Korea*       |
| NYTimes "Chronicle"          | `ngram_political_troop.csv`                                   | .csv   | ngrams/     | ✓     | NYTimes R&D Lab (2012)   |
| Choi-Lee (1989)              | `defense.xlsx`                                                | .xlsx  | defensedata/| ✓     | Choi & Lee (1989)        |
| Okazaki & Yoshioka-Hirofumi  | `japan_legalact_table.csv`                                    | .csv   | policydata/ | ✓     | Okazaki (1998), Yoshioka |
|                              |                                                               |        |             |       | & Hirofumi (2016)        |

**Derivatives**
The following are datasets derived from aggregates, calculations, or estimates from source data above.

| Data Source                    | File(s) in Package      | Format | Location    | Here? | Citation      |
|:-------------------------------|:------------------------|:-------|:------------|:------|:--------------|
| MMS (Calculations)             | `mms_TFP_5digit.dta`    | .dta   | input/      | ✓     | From above.   |
| MMS (Calculations)             | `pre1973_4digit.csv`    | .csv   | input/      | ✓     |               |
| MMS (Calculations)             | `pre1973_5digit.csv`    | .csv   | input/      | ✓     |               |
| UN COMTRADE (Calculations)     | `pre1973_trade.csv`     | .csv   | input/      | ✓     |               |
| MMS (Calculations)             | `agg_policyinput.dta`   | .dta   | input/      | ✓     |               |
| MMS (Calculations)             | `agg_policytrade.dta`   | .dta   | input/      | ✓     |               |
| MMS (Calculations)             | `mms_MRPK_5digit.dta`   | .dta   | input/supp/ | ✓     |               |
| Luedde-Neurath (1982) / MMS    | `tradepolicy_panel.dta` | .dta   | input/      | ✓     |               |
| Naver News Library             | `article_info.csv`      | .csv   | naverdata/  | ✓     | Naver (2018)* |

[**Asterisks**: Data build from Naver (2018) API and author's calculations. See Online Supplementary Appendix for Paper.]

The following are sub-files used in Appendix and Supplemental Appendix analyses. Data sets are derivatives of main sources above.

| Data Source                    | File(s) in Package                | Format | Location      | Here? | Citation      |
|:-------------------------------|:----------------------------------|:-------|:--------------|:------|:--------------|
| MMS (Derivative)               | `mms_supp_inv.dta`                | .dta   | input/supp/   | ✓     | From above.   |
| MMS (Derivative)               | `mms_linkage_more_5digit.dta`     | .dta   | input/supp/   | ✓     |               |
| MMS (Derivative)               | `mms_linkage_more_4digit.dta`     | .dta   | input/supp/   | ✓     |               |
| MMS (Derivative)               | `mms_linkage_mech_5digit.dta`     | .dta   | input/supp/   | ✓     |               |
| MMS (Derivative)               | `mms_linkage_mech_4digit.dta`     | .dta   | input/supp/   | ✓     |               |
| MMS (Derivative)               | `mms_crowding_out.dta`            | .dta   | input/supp/   | ✓     |               |
| MMS (Derivative)               | `mms_continuous_analysis.dta`     | .dta   | input/supp/   | ✓     |               |
| INDSTAT2 Rev.3                 | `unido_robustness_dataset.dta`    | .dta   | input/supp/   |       | UNIDO         |

All derivative datasets are generated aggregates from the main datasets. With the exception of `article_info.csv` which is generated from tokenized n-grams of the Naver News Library (Naver 2018) API and the author's calculations.


**Remarks on Dataset Sources**

**Mining and Manufacturing Census/Survey** - The main data source is scanned and digitized from the official Mining and Manufacturing Census & Survey (MMS). These data come from multiple annual volumes from 1968-1989, published by the Economic Planning Board (Economic Planning Board).

**Mining and Manufacturing Census/Survey [microdata]** - Microdata ("MMS Microdata") are official Statics Korea data and is proprietary and not available for public dissemination. 

**Statistical Yearbook of Korea** - Policy loan data comes from digitized volumes from the Economic Statistics Yearbook (Korean Yearbook) published by the Bank of Korea (Bank of Korea 1971, 1973, 1976, 1978, 1981, 1983).

**Legislation** - Korean legislation data from Republic of Korea from the Ministry of Government Legislation's legal act library (Korea L). The list is constructed from annexes of official South Korean legislation available from the Korean Law Information Center. Various acts cited (Republic of Korea).

**Naver News Library** - Article information is generated from tokenized n-grams of the Naver News Library (Naver 2018) API and the author's calculations.

**Other Not Included** - INDSTAT 2 Rev.3 data from UNIDO was purchased by the university library (Harvard). Recent versions are readily accessible and available under new (open) UNIDO licensing and supersede this version of the data/license. 

### Dataset List and Description

This section lists and describes the key datasets used or generated at various stages of the replication process.


#### Input Data

**Input Data Included: Main Datasets**
These datasets are the original core datasets used in the replication process.

- `data/input/comtrade_worldsitc_panel_cleaned4reg_4digit.dta`: UN COMTRADE world trade data at (4-digit SITC) level, accessed through the UN COMTRADE API (United Nations).
- `data/input/comtrade_worldsitc_panel_cleaned4reg_4digit_prob_HCIonly.dta`: Simplified version of `comtrade_worldsitc_panel_cleaned4reg_4digit` combined with common 2010 GDP aggregates and restricted to HCI industries (United Nations).
- `data/input/comtrade_merged_harmonized_panel_cleaned4reg_4digit.dta`: UN COMTRADE data for Korea only, matched with industry controls from the Mining and Manufacturing Survey (MMS) (United Nations; Economic Planning Board; author's calculations).
- `data/input/mms_merged_harmonized_panel_cleaned4reg_4digit.dta`: Digitized and harmonized Mining and Manufacturing Survey (MMS), harmonized panel. The aggregated 4-digit (KSIC) series spans 1968-1986. Data was digitized using public volumes of the Mining and Manufacturing Survey (Economic Planning Board, various years).
- `data/input/mms_merged_harmonized_panel_cleaned4reg_5digit.dta`: Digitized and harmonized Mining and Manufacturing Survey (MMS), harmonized panel data at 5-digit (KSIC) level. The disaggregated 5-digit series spans 1970-1986. Data was digitized using public volumes of the Mining and Manufacturing Survey (Economic Planning Board, various years).
- `data/input/policy_commercialbanking_yearbook_loans.csv`: Commercial banking loan data for 1968-1982. digitized from the Economic Statistics Yearbook, Bank of Korea (Bank of Korea, various years).
- `data/input/policy_kdbbanking_yearbook_loans.csv`: Korean Development Bank loan data for 1968-1982, digitized from the Economic Statistics Yearbook, Bank of Korea (Bank of Korea, various years).
- `data/input/policy_taxes.csv`: Tax policy data from Kwack's 1984 and 1985 reports published by the Korean Development Institute. Datasets were digitized and translated by the author (Kwack 1984, 1985)
- `data/policydata/acts_table_simple_combined_all.csv`: Korean legislation data from Republic of Korea. The list if constructed from annexes of official South Korean legislation available from the Ministry of Government Legislation. Acts are extracted and translated by the author (Republic of Korea).
- `data/policydata/japan_legalact_table.csv`: Comparisons between South Korean and Japanese sectoral targeting from Okazaki (1998) and Yoshioka & Hirofumi (2016).
- `data/policydata/tariffs.csv`: Tariff data and quantitative restriction indicators digitized from Luedde-Neurath's (1982) thesis collecting Korean government data on trade policy. 
- `data/naverdata/article_info.csv`: Data extracted from the Naver News Library API and processed by the author into a time series dataset (Naver 2018).
- `data/ngrams/ngram_political_troop.csv`: N-gram data from NYTimes "Chronicle" of simple uni-grams and bi-grams from historical New York Times coverage of U.S. troop withdrawals (NYTimes R&D Lab 2012).
- `data/defensedata/defense.xlsx`: Defense data from Choi and Lee (1989) [Naval Academy researchers] recording acts of aggression and violations of the armistice (Choi and Lee 1989).

The following datasets are not included in this repository, but their analyses and outputs are provided. See below.

**Not included in this repository:**
- `data/input/mms_TFP_micro.dta`: Mining and Manufacturing Survey (MMS) plant-level microdata series. This plant-level series spans 1980-1986. This internal government data not available for public dissemination.
- `data/input/unido_robustness_dataset.dta`: INDSTAT2 Rev.3 data from UNIDO for robustness checks (United Nations Industrial Development Organization 2014). Before new licences.

The associated analyses are provided and commented out from the workflow. The output for graphs are still generated.

#### Input Data (derivatives of core data)
These datasets are derivatives of core original datasets.

- `data/input/pre1973_4digit.csv`: Aggregate pre-1973 industry averages at 4-digit from MMS.
- `data/input/pre1973_5digit.csv`: Aggregate pre-1973 industry averages at 5-digit from MMS.
- `data/input/pre1973_trade.csv`: Aggregate pre-1973 industry averages from SITC UN COMTRADE data.
- `data/input/agg_policyinput.dta`: Aggregate industrial policy input data for inputs and intermediates from the MMS.
- `data/input/agg_policytrade.dta`: Aggregate industrial policy trade data from Luedde-Neurath (1982).
- `data/input/tradepolicy_panel.dta`: Panel dataset of trade policy variables (Luedde-Neurath 1982; author's calculations).
- `data/input/mms_TFP_5digit.dta`: Mining and Manufacturing Survey (MMS) data with Total Factor Productivity (TFP) at 5-digit level (Economic Planning Board; author's calculations).

#### Input Data Supplemental (derivatives of core data)
These datasets are supplemental derivatives used in appendix and supplemental appendix analyses.

- `data/input/supp/mms_supp_inv.dta`: Mining and Manufacturing Survey (MMS) supplemental investment data by asset class (Economic Planning Board; author's calculations).
- `data/input/supp/mms_linkage_more_5digit.dta`: Additional linkage outcomes at 5-digit KSIC level from MMS (Economic Planning Board; author's calculations).
- `data/input/supp/mms_linkage_more_4digit.dta`: Additional linkage outcomes at 4-digit KSIC level from MMS (Economic Planning Board; author's calculations).
- `data/input/supp/mms_linkage_mech_5digit.dta`: Linkage mechanism variables at 5-digit KSIC level from MMS (Economic Planning Board; author's calculations).
- `data/input/supp/mms_linkage_mech_4digit.dta`: Linkage mechanism variables at 4-digit KSIC level from MMS (Economic Planning Board; author's calculations).
- `data/input/supp/mms_crowding_out.dta`: Crowding-out analysis dataset from MMS (Economic Planning Board; author's calculations).
- `data/input/supp/mms_MRPK_5digit.dta`: Mining and Manufacturing Survey (MMS) data with Marginal Revenue Product of Capital (MRPK) at 5-digit level (Economic Planning Board; author's calculations).
- `data/input/supp/mms_continuous_analysis.dta`: Continuous analysis dataset of the Mining and Manufacturing Survey (MMS) (Economic Planning Board). This dataset is combines a cross-section of product-level exposure digitized calculated at the 4-digit level [see appendix] (Economic Planning Board).

#### Intermediate Data (produced in replication)
These datasets are produced by the `code/` analyses and populate in *`data/intermediate_data`*:

- `costs_binscatter.csv`: Material costs data from the Mining and Manufacturing Survey (MMS) aggregated policy input data, showing costs over time split by HCI (Heavy and Chemical Industries) status.
- `costs_binscatter.do`: Stata script for generating the costs binscatter plot.
- `invest_binscatter.csv`: Investment data from the MMS aggregated policy input data, showing total investment over time split by HCI status.
- `invest_binscatter.do`: Stata script for generating the investment binscatter plot.
- `investment_binscatter.csv`: Combined dataset containing investment, costs, QR, and tariff data over time split by HCI status.
- `mechanism_prod_interactions_alt_results_estout.csv`: Alternative industry-level Learning by Doing (LBD) interaction regression results.
- `mechanism_prod_interactions_results_estout.csv`: Industry-level Learning by Doing (LBD) interaction regression results.
- `qr_binscatter.csv`: Quantitative Restrictions (QR) data from trade policy data, showing QR coverage over time split by HCI status.
- `qr_binscatter.do`: Stata script generated by the QR binscatter plot.
- `readme.md`: Documentation for intermediate datasets.
- `tariff_binscatter.csv`: Tariff data from trade policy data, showing average tariff rates over time split by HCI status.
- `tariff_binscatter.do`: Stata script generated by the tariff binscatter plot.


#### Intermediate Data (non-public)
These datasets comes from the analysis where public data is not available (e.g., microdata analyses). The output from the do files (included) are included in *`data/included_data`*:

- `mechanism_prod_micro_results_estout.csv`: Plant-level Learning by Doing (LBD) mechanism regression results.
- `mechanism_prod_micro_robustness_results_estout.csv`: Robustness checks for plant-level Learning by Doing (LBD) mechanism regression results.

Although the source data is absent, the analysis (do files), their outputs, and the figure and table scripts are all included below.

---

###  Output: Final Data Produced by Replication

The following are outputs from the R-scripts in `code/` exported to the `output/` directory, which are the final data products of the replication. The directory will be empty until the `master.R` script is run. 

The directory structure mirrors the paper organization (main figures, main tables, appendix figures, appendix tables, supplemental appendix figures, supplemental appendix tables). It is structured as follows:

```
📁 output/
├── 📁 overleaf_figures/                        # Figures for the main paper
│   ├── 📄 *.pdf                                # PDF versions of figures
│   └── 📄 *.tex                                # LaTeX code for figure footnotes
│
├── 📁 overleaf_figures_appendix/               # Figures for the appendix
│   ├── 📄 *.pdf                                # PDF versions of figures
│   └── 📄 *.tex                                # LaTeX code for figure footnotes
│
├── 📁 overleaf_figures_supplementalappendix/   # Figures for the supplemental appendix
│   ├── 📄 *.pdf                                # PDF versions of figures
│   └── 📄 *.tex                                # LaTeX code for figure footnotes
│
├── 📁 overleaf_tables/                         # Tables for the main paper
│   └── 📄 *.tex                                # LaTeX code for tables
│
├── 📁 overleaf_tables_appendix/                # Tables for the appendix
│   └── 📄 *.tex                                # LaTeX code for tables
│
└── 📁 overleaf_tables_supplementalappendix/    # Tables for the supplemental appendix
│   └── 📄 *.tex                                # LaTeX code for tables
```

#### Output: Main Figures

Figures produced by R-scripts in `code/1_figures`

- Figure 1: `policyplot.pdf`
- Figure 2: `mainoutputplot.pdf`
- Figure 3: `devcombinedplot.pdf`
- Figure 4: `dddtradeplot.pdf`
- Figure 5: `capitalplot.pdf`
- Figure 6: `forwardlinkageplot.pdf`
- Figure 7: `forwardlinkagetrade.pdf`

#### Output: Main Tables

Tables produced by R-scripts in `code/2_tables`

- Table 1: `tfpcrosssection_kable.tex`
- Table 2: `kable_att.tex`
- Table 3: `kable_trade_att.tex`
- Table 4: `kable_invest_att.tex`
- Table 5: `industry_lbd_mechanism_kable.tex`
- Table 6: `plant_lbd_mechanism_kable.tex`
- Table 7: `avg_out_table.tex`
- Table 8: `avg_prices_table.tex`

Tiny results exported to `code/2_tables` for interpretation of results:
- TFP cross-section: `results_tfpcrosssection_maxtfp.tex`, `results_tfpcrosssection_mintfp.tex`
- Double robustness: `results_semi_ship.tex`, `results_ols_ship.tex`, `results_semi_max_yn.tex`, `results_semi_min_yn.tex`
- Trade: `results_log_rca.tex`, `results_export_share.tex`, `results_prob_rca.tex`
- Prices: `results_semi_prices.tex`, `results_ols_prices.tex`, `results_min_price.tex`, `results_max_price.tex`
- Labor: `results_semi_labor.tex`, `results_ols_labor.tex`, `results_semi_labor_4digit.tex`
- Investment: `results_ols_invest.tex`, `results_semi_invest.tex`, `results_semi_costs.tex`, `results_ols_costs.tex`
- Linkages: `results_forwardoutput_nonhci.tex`, `results_forwardprices_all.tex`, `results_forwardoutput_all.tex`, `results_forwardprices_nonhci.tex`


#### Output: Appendix Figures and Tables

Appendix figures produced by R-scripts in `code/3_appendix`:

- Appendix Figure A1: `appendixnewsplotrobust.pdf`
- Appendix Figure A2: `appendixpolicyplot.pdf`
- Appendix Figure B1: `appendixrobustoutput.pdf`
- Appendix Figure B2: `appendixproductivityprices.pdf`
- Appendix Figure B3: `industrytfpfigure.pdf`
- Appendix Figure B4: `semidd_4digit_plot.pdf`
- Appendix Figure B5: `semidd_5digit_plot.pdf`
- Appendix Figure B6: `semidd_sitc4_plot.pdf`
- Appendix Figure D1: `gg_gridinvest.pdf`
- Appendix Figure D2: `gg_mrpk_plot.pdf`
- Appendix Figure D3: `combined_crowdout_plot.pdf`
- Appendix Figure D4: `trade_ridge_plots.pdf`
- Appendix Figure E1: `gg_devlink_grid.pdf`
- Appendix Figure E2: `gg_rcatotallink_grid.pdf`
- Appendix Figure E3: `gg_mechanismlink_grid.pdf`
- Appendix Figure F1: `gg_backwardlink_grid.pdf`
- Appendix Figure F2: `gg_backwardlink_lf_grid.pdf`
- Appendix Figure G1: `gg_io_exposure_figure.pdf`
- Appendix Figure G2: `gg_control_io_figure.pdf`
- Appendix Figure G3: `gg_crowdingout_io_figure.pdf`

Appendix tables produced by R-scripts in `code/3_appendix`:

- Appendix Table A1: `tabledescriptive.tex`
- Appendix Table C1: `trade_prob_table.tex`
- Appendix Table D1: `industry_lbd_robust_mechanism.tex`
- Appendix Table D2: `plant_lbd_robust_mechanism.tex`
- Appendix Table D3: `tradepolicy_kable.tex`
- Appendix Table E1: `avg_lf_output_table.tex`
- Appendix Table E2: `avg_lf_prices_table.tex`
- Appendix Table E3: `avg_io_moredev_table.tex`
- Appendix Table E4: `avg_lf_moredev_kable.tex`

- Tiny results exported to `code/3_appendix` for interpretation of results: `results_tradeprob_minrca.tex`, `results_tradeprob_maxrca.tex`, `results_tradeprob_meanrcahci.tex`, `results_hci_rca_mean.tex`, `results_nonhci_rca_mean.tex`

#### Output: Supplemental Appendix Figures and Tables

Supplemental appendix figures produced by R-scripts in `code/4_suppappendix`

- Supplemental Appendix Figure A1: `newspapeealternative.pdf`
- Supplemental Appendix Figure B1: `tfpmicrodynamic.pdf`
- Supplemental Appendix Figure B2: `continuoustreatmentplot.pdf`
- Supplemental Appendix Figure C1: `combined_ddd_unido_figure.pdf`
- Supplemental Appendix Figure C2: `combined_dd_rca_alt_figure.pdf`

Supplemental appendix tables produced by R-scripts in `code/4_suppappendix`

- Supplemental Appendix Table A1: `sectoracttable.tex`
- Supplemental Appendix Table A2: `japansectoractlisttable.tex`
- Supplemental Appendix Table A3: `pretradepolicytable.tex`
- Supplemental Appendix Table B1: `tablerollingoutput.tex`
- Supplemental Appendix Table B2: `tablerollingdevelopment.tex`
- Supplemental Appendix Table C1: `tablerollingca.tex`
- Supplemental Appendix Table C2: `tablerollingdddrca.tex`
- Supplemental Appendix Table C3: `tablerollingdaltca.tex`
- Supplemental Appendix Table D1: `tablerollingcapital.tex`
- Supplemental Appendix Table D2: `tablerollingcapital2.tex`
- Supplemental Appendix Table E1: `tablerollingforwardoutput.tex`
- Supplemental Appendix Table E2: `tablerollingforwardprices.tex`
- Supplemental Appendix Table E3: `tablerollingforwarddev.tex`
- Supplemental Appendix Table E4: `tablerollingforwardtrade.tex`
- Supplemental Appendix Table E5: `tablerollingforwardmech.tex`
- Supplemental Appendix Table F1: `tablebacklinkoutput.tex`
- Supplemental Appendix Table F2: `tablebacklinkprices.tex`
- Supplemental Appendix Table F3: `backlinkoutputlf.tex`

## Computational Requirements


### Software Requirements

This code requires Stata (17+) and R (4.3+), preferably with RStudio. It is portable across MacOS/Unix/Windows.


### Package Installation and Environment Setup

- [X] The replication package contains one or more programs/scripts to install all dependencies and set up the necessary environment:

> [`master.R`,`setup/setup.R`,`setup/setup.do`]


#### Stata Packages

The replication code requires the following user-written packages for Stata. User-written packages are installed automatically by the master do-file, `0_master_run_analysis.do`, from Stata's SSC archive.


| Package      | Package      |
|:-------------|:-------------|
| `reghdfe`    | `ppmlhdfe`   |
| `regsave`    | `estout`     |
| `ftools`     | `csdid`      |
| `drdid`      | `erepost`    |
| `binscatter` | `gph2xl`     |


All packages are installed automatically using the SSC Stata database, with the exception of `gph2xl` which is installed directly from the Center for Global Development's repository. 


#### R Packages

The replication code requires the following packages for R. All packages are installed by the `setup.R` program automatically.

Installed packages (with versions used):

| Package          | Version  | Package          | Version  |
|:-----------------|:---------|:-----------------|:---------|
| `assertthat`     | 0.2.1    | `data.table`     | 1.17.0   |
| `DescTools`      | 0.99.60  | `devtools`       | 2.4.5    |
| `dplyr`          | 1.1.4    | `gghighlight`    | 0.4.1    |
| `ggnewscale`     | 0.5.1    | `ggplot2`        | 3.5.2    |
| `ggpubr`         | 0.6.0    | `ggridges`       | 0.5.6    |
| `gridExtra`      | 2.3      | `kableExtra`     | 1.4.0    |
| `knitr`          | 1.50     | `magrittr`       | 2.0.3    |
| `openxlsx`       | 4.2.8    | `papaja`         | 0.1.3    |
| `plyr`           | 1.8.9    | `RColorBrewer`   | 1.1-3    |
| `reshape`        | 0.8.9    | `reshape2`       | 1.4.4    |
| `rprojroot`      | 2.0.4    | `RStata`         | 1.1.2    |
| `RUnit`          | 0.4.33   | `scales`         | 1.4.0    |
| `showtext`       | 0.9.7    | `stringr`        | 1.5.1    |
| `sysfonts`       | 0.8.9    | `testthat`       | 3.2.3    |
| `tidyr`          | 1.3.1    | `tinylabels`     | 0.2.5    |
| `usethis`        | 3.1.0    | `viridis`        | 0.6.5    |
| `viridisLite`    | 0.4.2    | `yaml`           | 2.3.10   |

Base R packages used (no installation necessary):

| Package     | Package     |
|:------------|:------------|
| `datasets`  | `graphics`  |
| `grDevices` | `grid`      |
| `methods`   | `rlang`     |
| `utils`     | `stats`     |

### Controlled Randomness

- [x] Random seed(s) are set to ensure reproducibility for analyses involving pseudo-random number generation.

>The seed is set for R `/setup/setup.R` and for Stata in `/setup/setup.do`.


### Hardware Requirements

- **Processor:** Tested on Apple Silicon M3 14 core.
- **RAM:** 16 GB+.
- **Operating System of original run:** The code was written on MacOS 14.4.1.


### Memory, Estimated Runtime, and Storage Requirements

- **Approximate time needed to reproduce all analyses:**
    - [ ] <10 minutes
    - [ ] 10-60 minutes
    - [x] 1-2 hours [For newer builds and StataMP]
    - [x] 2-8 hours [For entry-level systems and StataBE]
    - [ ] 8-24 hours
    - [ ] 1-3 days
    - [ ] 3-14 days
    - [ ] > 14 days

- **Approximate *additional* storage space needed during run (for temporary files, downloaded data, generated outputs):**
    - [ ] < 25 MB
    - [x] 25 MB - 250 MB
    - [ ] 250 MB - 2 GB
    - [ ] 2 GB - 25 GB
    - [ ] 25 GB - 250 GB
    - [ ] > 250 GB

The zipped package is approximately 45MB and the unzipped file is approximately 150MB.

- [ ] Full replication may not be feasible on a standard desktop machine due to [e.g., extensive computation time, very large memory requirements for specific steps]. See details below.

---
## Summary of Replication Workflow


### Directory Structure

The replication package is organized as follows:

````
📁 industrialpolicy_forqje/
├── 📄 master.R                               # Master R script executes the entire workflow
├── 📄 config.yml                             # Configuration of paths and user settings
├── 📄 README.md                              # Main project documentation
├── 📄 replicationpackage.Rproj                 # RStudio project file for quickstart.
│
├── 📁 code/                                  # Replication code
│   ├── 📁 0_analysis/                        # Stata analysis scripts
│   │   ├── 📄 0_master_run_analysis.do       # Top-level driver for all analyses
│   │   ├── 📁 1_main_scripts/                # Main analysis do files
│   │   ├── 📁 2_appendix_scripts/            # Appendix do files
│   │   ├── 📁 3_suppappendix_scripts/        # Supplemental appendix do files
│   │   └── 📁 subdofiles/                    # Uility do files
│   │
│   ├── 📁 1_figures/                         # R scripts for main paper figures
│   │   └── 📄 0_master_run_figure.R          # Master R script to make figures
│   │
│   ├── 📁 2_tables/                          # R scripts for main paper tables
│   │   └── 📄 0_master_run_table.R           # Master R script to make tables
│   │
│   ├── 📁 3_appendix/                        # R scripts for appendix outputs
│   │   └── 📄 0_master_run_appendix.R        # Master R script to make appendix outputs
│   │
│   └── 📁 4_suppappendix/                    # R scripts for supplemental appendix outputs
│       └── 📄 0_master_run_suppappendix.R    # Master R script to make supplemental outputs
│
├── 📁 data/                                  # Data
│   ├── 📁 input/                             # Input data
│   │   └── 📁 supp/                          # Appendix and supplemental data
│   │
│   ├── 📁 intermediate_datasets/             # Intermediate data
|   ├── 📁 included_datasets/                 # Intermediate data
│   └── 📁 [Other data directories]           # Other input data
│
├── 📁 output/                                # Generated outputs (figures, tables)
├── 📁 log/                                   # Log files
├── 📁 setup/                                 # Setup scripts (Stata and R)
├── 📁 entrypoints/                           # Entry point scripts for specific workflows
|
├── 📄 PACKAGE_INFO.txt                       # Metadata on package version.
└── 📄 MANIFEST.txt                           # Metadata on package contents.
````

### Key Code

The following are essentials files of the repository

| File                     | Purpose                                            |
|:-------------------------|:---------------------------------------------------|
| `master.R`               | Main project driver. This is what you run.         |
| `config.yml`             | Sets up directories and user information.          |
| `replicationpackage.Rproj` | RStudio project file. Opens and sets project root. |

The user will have to edit `config.yml` file to point to their Stata installation and Stata version, and the `replicationpackage.Rproj` file allows the user to open and set the project path in RStudio.

The script `master.R` runs the entire replication workflow from R:

| Step  | File                                              | Purpose                             |
|:------|:--------------------------------------------------|:------------------------------------|
| **0** | `master.R`                                        | Sets up R environment               |
|       |  **Executes scripts below**                       | Opens `log/master.log`              |
|       |                                                   | Reads `config.yml` settings         |
| **1** | `setup/setup.do`                                  | Sets up Stata environment           |
|       |                                                   | Installs required Stata packages    |
| **2** | `code/0_analysis/0_master_run_analysis.do`        | **Top-level Stata driver:**         |
|       |                                                   | - Runs all Stata analysis modules   |
| **3** | `setup/setup.R`                                   | - Installs/loads R packages         |
|       |                                                   | Configures R environment            |
| **4** | `code/1_figures/0_master_run_figure.R`            | Makes main paper figures            |
|       |                                                   | Outputs to `output/figures/`        |
| **5** | `code/2_tables/0_master_run_table.R`              | Makes main paper tables             |
|       |                                                   | Outputs to `output/tables/`         |
| **6** | `code/3_appendix/0_master_run_appendix.R`         | Makes appendix tables/figures       |
|       |                                                   | Outputs to `output/appendix/`       |
| **7** | `code/4_suppappendix/0_master_run_suppappendix.R` | Makes supplemental appendix outputs |
|       |                                                   | Outputs to `output/suppappendix/`   |
## Instructions to Replicators


### Prerequisites

1. **Software:** Ensure all software listed in the [Software Requirements](#software-requirements) section is installed.
2. **Packages/Libraries:** Running the master script (e.g., `master.R`) will automatically install all required packages, detailed in [Package Installation and Environment Setup](#package-installation-and-environment-setup).
3. **Data:**
    - All public data files are included in the project's `data/` directory []. 
    - For restricted-access data, obtain access as described and place the files in the designated locations (or modify path globals in the master script if necessary). If using synthetic data for code-checking, ensure it's in place.
4.  **Working Directory:** It is assumed that Stata/R/Python will be run with the root of this replication package (the directory containing this README.md and config.yml, etc.) as the current working directory. Master scripts handle subdirectory navigation, and code uses relative paths.


### Step-by-Step Replication Workflow

1. **Configure Stata Settings in config.yml**

   * Open `config.yml` in any text editor
   * Put your Stata settings in the `user_dirs` section (bottom):
      - `stata_path:` [path/to/stata/executible]
      - > EX `/Applications/Stata/StataSE.app/Contents/MacOS/stata-se`
      - `stata_version` [e.g, 17, 18.5, etc.]
   * Optional: Set `skip_stata: true` to run only R scripts.

> See ["Configuring Project `config.yml`"](#configuring-project-configyml) below for details.

1. **Open R (RStudio) and master.R**
    - Ensure R is installed (R 4.3+ and RStudio is recommended).
    - Navigate to the location of `replicationpackage/`.
    - (recommended) Double-click `replicationpackage.Rproj` to open RStudio.
    - Or open your preferred R environment.

2. **Open and Run master.R**
   * Open the `master.R`.
   * Execute `master.R` by
      - Clicking "Source" button in RStudio, or
      - Pressing `Ctrl+Shift+Enter` (Windows/Linux) or `Cmd+Shift+Enter` (macOS).

3. **The master.R workflow will**
    - Set up the environment and create logs
    - Run Stata analyses (approx. 1-2 hours)
    - Run R scripts for figures and tables

4. **Monitor Progress In:**
    - The R console.
    - The `log/master.log` file
    - The `data/intermediate_data` directory
    - The `data/output` directory

### Expected Output and Verification

- All Stata output will be saved in `data/intermediate_data`.
- All generated tables will be saved in the `output/tables/` directory.
- All generated figures will be saved in the `output/figures/` directory. 
- All generated Appendix and Supplemental content in the output directory.
- Log files for each major script execution will be saved in `log/`.
- Replicators can verify successful replication by comparing the generated tables and figures against those presented in the published manuscript.

### Configuring Project (config.yml)

- Common Paths for Stata executables:
 -  MacOS: `/Applications/Stata/StataSE.app/Contents/MacOS/stata-SE`
 -  Windows: `C:/Program Files (x86)/Stata18/`

---
## Code Details

This project driver script `master.R` runs the code files in the `code/` directory in the following order. Which consists of a two-stage workflow:

1. **Stata Analysis** (`0_analysis/`):
   - Entry point: `0_master_run_analysis.do` 
   - Calls three subordinate masters to analyze main paper, appendix, and supplemental appendix
   - Outputs intermediate datasets to `intermediate_datasets/`

2. **R Output Generation** (`1_figures/`, `2_tables/`, `3_appendix/`, `4_suppappendix/`):
   - Each section has its own master R script (e.g., `0_master_run_figure.R`, `0_master_run_table.R`, ... )
   - Processes intermediate data into publication-ready outputs
   - Saves outputs to `output/` directory

The `code/` directory is structured as follows:

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

### Stata Analysis 

The `0_master_run_analysis.do` file is the top-level Stata driver that calls three subordinate masters to analyze main paper, appendix, and supplemental appendix:
 

#### 1. The Main Stata Analysis

The `code/0_analysis/1_main_scripts/` directory contains the subordinate do-files. The `0_1_master_run_main_analyses` performs the analyses of the main paper, ordered by the way they are presented in the manuscrip.

| Main Analysis     | `0_1_master_run_main_analyses`  Ⓜ️        | Analysis description                             |
|:------------------|:------------------------------------------|:-------------------------------------------------|
| `/1_main_scripts` | `1_run_growth_analysis.do`                | Main growth event study.                         |
| `/1_main_scripts` | `2a_run_devoutcomes_analysis.do`          | Further development outcomes event study.        |
| `/1_main_scripts` | `2b_run_koreatrade_analysis.do`           | Korean trade patterns.                           |
| `/1_main_scripts` | `3a_run_micro_tfp_analysis.do`            | Micro-level TFP analysis                         |
| `/1_main_scripts` | `3b_run_doublerobust_analysis.do`         | Double robust statistical analysis               |
| `/1_main_scripts` | `3c_run_worldtrade_analysis.do`           | Analysis of world trade patterns                 |
| `/1_main_scripts` | `4_run_policy_analysis.do`                | Industrial policy analysis                       |
| `/1_main_scripts` | `5a_run_mechanisms_lbd_analysis.do`       | LBD mechanism analysis                           |
| `/1_main_scripts` | `5b_run_mechanisms_lbd_micro_analysis.do` | Micro-level LBD mechanism analysis               |
| `/1_main_scripts` | `6a_run_linkages_growthprice_analysis.do` | Linkages between growth and prices               |
| `/1_main_scripts` | `6b_run_linkages_trade_analysis.do`       | Analysis of trade linkages                       |   


#### 2. The Appendix Stata Analysis

The `code/0_analysis/2_appendix_scripts/` directory contains the `0_2_master_run_appendix_analyses.do` master do-file, which runs the analysis for the main online appendix.

| Appendix Analysis     | `0_2_master_run_appendix_analyses.do`        | Analysis description                           |
|:----------------------|:---------------------------------------------|:-----------------------------------------------|
| `/2_appendix_scripts` | `APP_B_run_industry_tfp_analysis.do`         | Industry-level TFP event study                 |
| `/2_appendix_scripts` | `APP_B_run_priceandyn_analysis.do`           | Price and labor productivity event study       |
| `/2_appendix_scripts` | `APP_C_run_worldtrade_analysis_prob.do`      | Probability models for world trade patterns    |
| `/2_appendix_scripts` | `APP_D_run_lbd_micro_analysis.do`            | Micro-level LBD analysis                       |
| `/2_appendix_scripts` | `APP_D_run_policy_aggregate_figures.do`      | Aggregate policy plots                         |
| `/2_appendix_scripts` | `APP_D_run_policy_crowdingout_analysis.do`   | Analysis of policy crowding-out                |
| `/2_appendix_scripts` | `APP_D_run_policy_mrpk_analysis.do`          | Marginal returns to capital policy analysis    |
| `/2_appendix_scripts` | `APP_D_run_policy_trade_analysis.do`         | Trade impacts of industrial policy             |
| `/2_appendix_scripts` | `APP_E_run_linkages_mechanisms_analysis.do`  | Analysis of linkage mechanisms                 |
| `/2_appendix_scripts` | `APP_E_run_linkages_morecomes_analysis.do`   | Additional linkage outcomes                    |
| `/2_appendix_scripts` | `APP_G_run_sutva_analysis.do`                | SUTVA assumption and crowding-out analysis     |


#### 3. The Supplemental Appendix Stata Analysis

The `code/0_analysis/3_suppappendix_scripts/` directory contains the `0_3_master_run_suppappendix_analyses.do` master do-file, which runs the analysis for the supplemental appendix.

| Section/Master            | `0_3_master_run_suppappendix_analyses.do`  Ⓜ️      | Analysis description                            |
|:--------------------------|:-------------------------------------------------|:------------------------------------------------|
| `/3_suppappendix_scripts` | `SUPP_APP_A_run_policy_trade_1968_analysis.do`   | Analysis of 1968 policy trade patterns          |
| `/3_suppappendix_scripts` | `SUPP_APP_B_run_4digit_continuous_analysis.do`   | 4-digit continuous industry analysis            |
| `/3_suppappendix_scripts` | `SUPP_APP_B_run_micro_tfp_dynamic_analysis.do`   | Dynamic micro-level TFP analysis                |
| `/3_suppappendix_scripts` | `SUPP_APP_C_run_unido_analysis.do`               | Analysis using UNIDO industrial data            |
| `/3_suppappendix_scripts` | `SUPP_APP_D_run_policy_dissagg_investment_...do` | Investment by asset class                       |
| `/3_suppappendix_scripts` | `SUPP_APP_E_run_dd_comtrade_analysis.do`         | DiD version of COMTRADE DDD in main paper       |

### R Output Generation

The Stata analysis scripts generate intermediate datasets that are used by the R scripts to create publication-ready figures and tables.

These R-scripts, located in the `1_figures/`, `2_tables/`, `3_appendix/`, and `4_suppappendix/` directories, are executed by the `master.R` driver.

All R-scripts are named directly after their corresponding figures and tables. All files export output to the `output/` directory.


#### Main Figures and Tables Generation

The `0_master_run_figure.R` script sources the following figure scripts for the main section of the paper.

| Script    | Data Used ( from `data/intermediate_datasets/` directory)           |   Output Path               |
|:----------|:--------------------------------------------------------------------|:----------------------------
| Figure2.R | did_largerolling_mainresults_alloutput_all_results.csv              | `output/overleaf_figures/`  |
| Figure2.R | did_largerolling_mainresults_alloutput_4d_all_results.csv           | `output/overleaf_figures/`  |
| Figure3.R | did_largerolling_allproductivity_all_results.csv                    | `output/overleaf_figures/`  |
| Figure3.R | did_largerolling_allproductivity_4d_all_results.csv                 | `output/overleaf_figures/`  |
| Figure3.R | did_largerolling_koreatrade_ppml_rca_all_results.csv                | `output/overleaf_figures/`  |
| Figure4.R | did_largerolling_worldtrade_ppml_rca_all_results.csv                | `output/overleaf_figures/`  |
| Figure5.R | did_largerolling_mainpolicycapital_results_papermain.csv            | `output/overleaf_figures/`  |
| Figure6.R | did_io_main_all_results.csv                                         | `output/overleaf_figures/`  |
| Figure7.R | did_io_comtrade_all_results.csv                                     | `output/overleaf_figures/`  |

All figure files export output to the `output/overleaf_figures/` directory.

The `0_master_run_table.R` script sources the following table scripts for the main section of the paper. Most of these are sourced from analysis outputs in `data/intermediate_datasets/`, with the exception of private micro data analyses. These data sets are provided in `data/included_datasets/`: 

| R Script    | Input File(s)                                                                   | Output Path                 |
|:------------|:--------------------------------------------------------------------------------|:----------------------------|
| Table1.R    | did_crossection_results_microtfp_results_estout.csv (`included_dir`)            |  `output/overleaf_tables/`  |
| Table2-4.R  | doublyrobust_att.csv (`intermediate_dir`)                                       |  `output/overleaf_tables/`  |
| Table2-4.R  | doublyrobust_trade_att.csv, doublyrobust_invest_att.csv (`intermediate_dir`)    |  `output/overleaf_tables/`  |
| Table2-4.R  | doublyrobust_invest_att.csv (`intermediate_dir`)   |  `output/overleaf_tables/` |  `output/overleaf_tables/`  |
| Table5.R    | mechanism_prod_interactions_results_estout.csv (`intermediate_dir`)             |  `output/overleaf_tables/`  |
| Table6.R    | mechanism_prod_micro_results_estout.csv (`included_dir`)                        |  `output/overleaf_tables/`  |
| Table7.R    | did_io_main_prepost_bothlink_l_valueadded_5estout.csv (`intermediate_dir`)      |  `output/overleaf_tables/`  |
| Table7.R    | did_io_main_prepost_bothlink_l_valueadded_4estout.csv (`intermediate_dir`)      |  `output/overleaf_tables/`  |
| Table8.R    | did_io_main_prepost_bothlink_l_ppi_5estout.csv (`intermediate_dir`)             |  `output/overleaf_tables/`  |
| Table8.R    | did_io_main_prepost_bothlink_l_ppi_4estout.csv (`intermediate_dir`)             |  `output/overleaf_tables/`  |

All table files export output to the `output/overleaf_tables/` directory.

#### Appendix Figures and Tables Generation

The `0_master_run_appendix.R` script sources the following figure and table scripts for the appendix section of the paper. Most of these are sourced from analysis outputs in `data/intermediate_datasets/`, with the exception of private micro data analyses. These data sets are provided in `data/included_datasets/`: 

| R Script   | Input File(s) it reads                             | Output Path                        |
|:-----------|:---------------------------------------------------|:-----------------------------------|
| FigureA1.R | ngram_political_troop.csv, article_info.csv        | `output/overleaf_appendix_figures/`|
| FigureA2.R | policy_commercialbanking_yearbook_loans.csv        | `output/overleaf_appendix_figures/`|
| FigureB1.R | did_largerolling_mainresults_alloutput_all_.. .csv | `output/overleaf_appendix_figures/`|
|            | did_largerolling_mainresults_alloutput_4d_... .csv | `output/overleaf_appendix_figures/`|
| FigureB2.R | did_priceandyn_robust_all_results.csv              | `output/overleaf_appendix_figures/`|
| FigureB3.R | did_largerolling_results_tfp_all_results.csv       | `output/overleaf_appendix_figures/`|
| FigureB4.R | doublyrobust_all_results.csv                       | `output/overleaf_appendix_figures/`|
|            | doublyrobust_invest_all_results.csv                | `output/overleaf_appendix_figures/`|
|            | doublyrobust_trade_all_results.csv                 | `output/overleaf_appendix_figures/`|
| FigureD1.R | investment_binscatter.csv                          | `output/overleaf_appendix_figures/`|
| FigureD2.R | did_largerolling_mrpk_all_results.csv              | `output/overleaf_appendix_figures/`|
| FigureD3.R | did_largerolling_crowding_basic_all_results.csv    | `output/overleaf_appendix_figures/`|
|            | did_largerolling_crowding_intensity_all_res... .csv| `output/overleaf_appendix_figures/`|
| FigureD4.R | tariffs.csv                                        | `output/overleaf_appendix_figures/`|
| FigureE1.R | did_io_moredev_all_results.csv                     | `output/overleaf_appendix_figures/`|
| FigureE2.R | did_iolf_comtrade_all_results.csv                  | `output/overleaf_appendix_figures/`|
| FigureE3.R | did_io_mechanism_all_results.csv                   | `output/overleaf_appendix_figures/`|
|            | did_iolf_mechanism_all_results.csv                 | `output/overleaf_appendix_figures/`|
| FigureF1.R | did_io_main_all_results.csv                        | `output/overleaf_appendix_figures/`|
| FigureF2.R | did_iolf_main_all_results.csv                      | `output/overleaf_appendix_figures/`|
| FigureG1.R | did_io_limitexposure_all_results.csv               | `output/overleaf_appendix_figures/`|
| FigureG2.R | did_io_downonly_sutva_all_results.csv              | `output/overleaf_appendix_figures/`|
|            | did_iolf_downonly_sutva_all_results.csv            | `output/overleaf_appendix_figures/`|
|            | did_iolf_sutva_all_results.csv                     | `output/overleaf_appendix_figures/`|
| FigureG3.R | did_io_crowdingout_all_results.csv                 | `output/overleaf_appendix_figures/`|

| R Script     | Input File(s) it reads                                        | Output Path                        |
|:-------------|:--------------------------------------------------------------|:-----------------------------------|
| TableA1.R    | pre1973_4digit.csv, pre1973_5digit.csv, pre1973_trade.csv     | `output/overleaf_appendix_tables/` |
| TableC1.R    | did_probrca_results_estout.csv                                | `output/overleaf_appendix_tables/` |
| TableD1.R    | mechanism_prod_interactions_alt_results_estout.csv            | `output/overleaf_appendix_tables/` |
| TableD2.R    | mechanism_prod_micro_robustness_results_estout.csv            | `output/overleaf_appendix_tables/` |
| TableD3.R    | did_output_tradepolicy_results_estout.csv                     | `output/overleaf_appendix_tables/` |
| TableD3.R    | did_input_tradepolicy_results_estout.csv                      | `output/overleaf_appendix_tables/` |
| TableE1.R    | did_iolf_main_prepost_bothlink_l_valueadded_5estout.csv,      | `output/overleaf_appendix_tables/` |
|              | did_iolf_main_prepost_bothlink_l_valueadded_4estout.csv       | `output/overleaf_appendix_tables/` |
| TableE2.R    | did_iolf_main_prepost_bothlink_l_ppi_5estout.csv,             | `output/overleaf_appendix_tables/` |
|              | did_iolf_main_prepost_bothlink_l_ppi_4estout.csv              | `output/overleaf_appendix_tables/` |
| TableE3.R    | did_io_moredev_prepost_bothlink_allvars_5estout.csv,          | `output/overleaf_appendix_tables/` |
|              | did_io_moredev_prepost_bothlink_allvars_4estout.csv           | `output/overleaf_appendix_tables/` |
| TableE4.R    | did_iolf_moredev_prepost_bothlink_allvars_5estout.csv,        | `output/overleaf_appendix_tables/` |
|              | did_iolf_moredev_prepost_bothlink_allvars_4estout.csv         | `output/overleaf_appendix_tables/` |

#### Supplemental Appendix Figures and Tables Generation

The `0_master_run_suppappendix.R` script sources the following figure scripts for the main section of the paper (sources from analysis outputs in `data/intermediate_datasets/`, with the exception of private micro data analyses. These data sets are provided in `data/included_datasets/`)

| R Script    | Data / Other Files it reads                                 | Output Path                             |
|:------------|:------------------------------------------------------------|:----------------------------------------|
| Figure_A1.R | ngrams/ngram_political_troop.csv, defensedata/defense.xlsx  | `output/overleaf_suppappendix_figures/` |
| Figure_B1.R | did_largerolling_results_microtfp_all_results.csv           | `output/overleaf_suppappendix_figures/` |
| Figure_B2.R | did_largerolling_continuous_4d_all_results.csv              | `output/overleaf_suppappendix_figures/` |
| Figure_C1.R | did_largerolling_unido_all_results.csv                      | `output/overleaf_suppappendix_figures/` |
| Figure_C2.R | did_largerolling_worldtrade_supp_ppml_rca_all_results.csv   | `output/overleaf_suppappendix_figures/` |


| R Script    | Data / Other Files it reads                                       | Output Path                              |
|:------------|:------------------------------------------------------------------|:-----------------------------------------|
| Table_A1.R  | acts_table_simple_combined_all.csv                                | `output/overleaf_suppappendix_tables/`   |
| Table_A2.R  | japan_legalact_table.csv                                          | `output/overleaf_suppappendix_tables/`   |
| Table_A3.R  | did_output_tradepolicy_1968only_results_estout.csv                | `output/overleaf_suppappendix_tables/`   |
| Table_B1.R  | did_largerolling_mainresults_alloutput_results_estout.csv         | `output/overleaf_suppappendix_tables/`   |
|             | did_largerolling_mainresults_alloutput_4d_results_estout.csv      | `output/overleaf_suppappendix_tables/`   |
| Table_B2.R  | did_largerolling_allproductivity_results_estout.csv               | `output/overleaf_suppappendix_tables/`   |
|             | did_largerolling_allproductivity_4d_results_estout.csv            | `output/overleaf_suppappendix_tables/`   |
| Table_C1.R  | did_largerolling_koreatrade_ppml_rca_results_estout.csv           | `output/overleaf_suppappendix_tables/`   |
| Table_C2.R  | did_largerolling_worldtrade_ppml_rca_results_estout.csv           | `output/overleaf_suppappendix_tables/`   |
| Table_C3.R  | did_largerolling_worldtrade_supp_ppml_rca_results_estout.csv      | `output/overleaf_suppappendix_tables/`   |
| Table_D1.R  | did_largerolling_mainpolicycapital.csv                            | `output/overleaf_suppappendix_tables/`   |
| Table_D2.R  | did_largerolling_policydisaggregatedcapital.csv                   | `output/overleaf_suppappendix_tables/`   |
| Table_E1.R  | did_io_main_rolling_bothlink_l_valueadded_5estout.csv             | `output/overleaf_suppappendix_tables/`   |
|             | did_io_main_rolling_bothlink_l_valueadded_4estout.csv             | `output/overleaf_suppappendix_tables/`   |
| Table_E2.R  | did_io_main_rolling_bothlink_l_ppi_5estout.csv                    | `output/overleaf_suppappendix_tables/`   |
|             | did_io_main_rolling_bothlink_l_ppi_4estout.csv                    | `output/overleaf_suppappendix_tables/`   |
| Table_E3.R  | did_io_moredev_rolling_bothlink_allvars_5estout.csv               | `output/overleaf_suppappendix_tables/`   |
|             | did_io_moredev_rolling_bothlink_allvars_4estout.csv               | `output/overleaf_suppappendix_tables/`   |
| Table_E4.R  | did_io_comtrade_rolling_bothlink_allvars_4estout.csv              | `output/overleaf_suppappendix_tables/`   |
| Table_E5.R  | did_io_mechanism_rolling_bothlink_allvars_estout.csv              | `output/overleaf_suppappendix_tables/`   |
|             | did_iolf_mechanism_rolling_bothlink_allvars_estout.csv            | `output/overleaf_suppappendix_tables/`   |
| Table_F1.R  | did_io_main_rolling_bothlink_l_valueadded_5estout.csv             | `output/overleaf_suppappendix_tables/`   |
|             | did_io_main_rolling_bothlink_l_valueadded_4estout.csv             | `output/overleaf_suppappendix_tables/`   |
| Table_F2.R  | did_io_main_rolling_bothlink_l_ppi_5estout.csv                    | `output/overleaf_suppappendix_tables/`   |
|             | did_io_main_rolling_bothlink_l_ppi_4estout.csv                    | `output/overleaf_suppappendix_tables/`   |
| Table_F3.R  | did_iolf_main_rolling_bothlink_l_valueadded_5estout.csv           | `output/overleaf_suppappendix_tables/`   |
|             | did_iolf_main_rolling_bothlink_l_valueadded_4estout.csv           | `output/overleaf_suppappendix_tables/`   |

---

## Data Citations
Bank of Korea. Economic Statistics Yearbook, 1973. Seoul: Bank of Korea, 1973.

Bank of Korea. Economic Statistics Yearbook, 1976. Seoul: Bank of Korea, 1976.

Bank of Korea. Economic Statistics Yearbook, 1978. Seoul: Bank of Korea, 1978.

Bank of Korea. Economic Statistics Yearbook, 1981. Seoul: Bank of Korea, 1981.

Bank of Korea. Economic Statistics Yearbook, 1984. Seoul: Bank of Korea, 1983.

Choi, Tae Young, and Su Gyo Lee. 1989. "Effect Analysis of US Military Aid to the Republic of Korea." Naval Postgraduate School Archive.

Luedde-Neurath, Richard. 1986. Import Controls and Export-Oriented Development: A Reassessment of the South Korean Case. Boulder, Colorado and London, England: Westview Press.

Economic Planning Board. Mining and Manufacturing Census. Seoul: Economic Planning Board, (various years) 1968-1987.

Economic Planning Board, Republic of Korea. Statistical Yearbook of Korea 1968. Seoul: Economic Planning Board, (various years) 1968-1987.

Kwack, Taewon. 1984. "Industrial Restructuring Experience and Policies in Korea in the 1970s." WP84-08. KDI Working Paper Series. Seoul.

Kwack, Taewon. 1985. "Depreciation and Taxation of Income from Capital." Seoul, Korea. Korean Development Institute.

Naver. "네이버 뉴스 라이브러리 [Naver News Library]." NAVER Corp. Accessed 2019. https://newslibrary.naver.com/.

The New York Times R&D Lab. Chronicle. 2012. Accessed June 09, 2013. https://chronicle.nytlabs.com/. [Archived/Deprecated]

Okazaki, Tetsuji. 1998. "Industrial Policy and Government Organization in Postwar Japan (in Japanese)." CIRJE J-Series. CIRJE, Faculty of Economics, University of Tokyo. 

United Nations. UN Comtrade Database. New York: United Nations. Accessed May 11, 2025. https://comtrade.un.org/.

United Nations Industrial Development Organization (UNIDO). INDSTAT2 Industrial Statistics Database, ISIC Rev.3, 2-Digit Level, 1963–2014. Vienna: UNIDO, 2017.

Yoshioka, Shinji, and Hirofumi Kawasaki. 2016. "Japan's High-Growth Postwar Period: The Role of Economic Plans." Tokyo.

