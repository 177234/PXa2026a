# Codebook for comtrade_worldsitc_panel_cleaned4reg_4digit_prob_HCIonly.dta

## Dataset Overview
- Number of Observations: 251,160
- Number of Variables: 11
- Description: Global trade data: post-1972 and only HCI products

## Variable Descriptions

### `code`
- **Description**: Industry Code
- **Type**: Numeric (integer)

### `cty`
- **Description**: Country Code
- **Type**: Numeric (integer)

### `year`
- **Description**: Year
- **Type**: Numeric (integer)

### `id`
- **Description**: Unit ID
- **Type**: Numeric (integer)

### `reporteriso`
- **Description**: ISO country code for the reporting country
- **Type**: String

### `reportercode`
- **Description**: Country code for the reporting country
- **Type**: Numeric (integer)

### `korea`
- **Description**: Korea indicator (0/1)
- **Type**: Numeric (integer)

### `l_gdp_pc`
- **Description**: Logarithm of gdp per capita
- **Type**: Numeric (float)

### `quantile_same_kor`
- **Description**: Same income quantile as Korea (pre-1973)
- **Type**: Numeric (integer)

### `quantile_neighbor_kor`
- **Description**: Neighbor and same income quantile as Korea (pre-1973)
- **Type**: Numeric (integer)

### `rca_dummy`
- **Description**: Revealed Comparative Advantage (RCA) dummy (0/1)
- **Type**: Numeric (integer)
