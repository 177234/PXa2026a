# Codebook for comtrade_merged_harmonized_panel_cleaned4reg_4digit.dta

## Dataset Overview
- Number of Observations: 13,508
- Number of Variables: 25

## Variable Descriptions

### `id`
- **Description**: Unit ID
- **Type**: Numeric (integer)

### `year`
- **Description**: Year
- **Type**: Numeric (integer)

### `code`
- **Description**: Industry Code
- **Type**: Numeric (integer)

### `hci`
- **Description**: Heavy and Chemical Industry (HCI) indicator (0/1)
- **Type**: Numeric (integer)

### `rca_cdk`
- **Description**: Revealed Comparative Advantage index (CDK method)
- **Type**: Numeric (float)

### `rca_core`
- **Description**: Revealed Comparative Advantage index (Balassa method)
- **Type**: Numeric (float)

### `reportercode`
- **Description**: Country code for the reporting country
- **Type**: Numeric (integer)

### `export_sh`
- **Description**: Percentage share of exports in total trade value
- **Type**: Numeric (float)

### `import_sh`
- **Description**: Percentage share of imports in total trade value
- **Type**: Numeric (float)

### `h_rca_core`
- **Description**: Transformed revealed comparative advantage index (balassa method) using hyperbolic sine function
- **Type**: Numeric (float)

### `l_rca_core`
- **Description**: Logarithm of revealed comparative advantage index (balassa method)
- **Type**: Numeric (float)

### `h_export_sh`
- **Description**: Transformed percentage share of exports in total trade value using hyperbolic sine function
- **Type**: Numeric (float)

### `l_export_sh`
- **Description**: Logarithm of percentage share of exports in total trade value
- **Type**: Numeric (float)

### `rca_dummy`
- **Description**: Revealed Comparative Advantage (RCA) dummy (0/1)
- **Type**: Numeric (integer)

### `post`
- **Description**: Post-1972 indicator (0/1)
- **Type**: Numeric (integer)

### `sitc_3`
- **Description**: Standard International Trade Classification code
- **Type**: Numeric (integer)

### `hci_share_make_tot_0`
- **Description**: Pre-1973 mean hci share make tot
- **Type**: Numeric (float)

### `hci_share_use_tot_0`
- **Description**: Pre-1973 mean hci share use tot
- **Type**: Numeric (float)

### `lf_hci_link_make_0`
- **Description**: Pre-1973 mean backward linkage exposure to hci (leontief, pre-1973)
- **Type**: Numeric (float)

### `lf_hci_link_use_0`
- **Description**: Pre-1973 mean forward linkage exposure to hci (leontief, pre-1973)
- **Type**: Numeric (float)

### `l_costs_0`
- **Description**: Logarithm of pre-1973 mean intermediate input costs
- **Type**: Numeric (float)

### `l_workers_0`
- **Description**: Logarithm of pre-1973 mean number of workers
- **Type**: Numeric (float)

### `l_avg_size_0`
- **Description**: Logarithm of pre-1973 mean avg size
- **Type**: Numeric (float)

### `l_y_n_0`
- **Description**: Logarithm of pre-1973 mean value added per worker
- **Type**: Numeric (float)

### `l_avg_wages_0`
- **Description**: Logarithm of pre-1973 mean avg wages
- **Type**: Numeric (float)
