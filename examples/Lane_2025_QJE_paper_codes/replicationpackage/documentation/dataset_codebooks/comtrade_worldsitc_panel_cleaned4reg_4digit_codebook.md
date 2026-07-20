# Codebook for comtrade_worldsitc_panel_cleaned4reg_4digit.dta

## Dataset Overview
- Number of Observations: 1,897,500
- Number of Variables: 19
- Description: Global trade data for comparative analysis

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

### `hci`
- **Description**: Heavy and Chemical Industry (HCI) indicator (0/1)
- **Type**: Numeric (integer)

### `korea`
- **Description**: Korea indicator (0/1)
- **Type**: Numeric (integer)

### `rca_cdk`
- **Description**: Revealed Comparative Advantage index (CDK method)
- **Type**: Numeric (float)

### `export_value`
- **Description**: Export value (US dollars)
- **Type**: Numeric (float)

### `export_share`
- **Description**: Percentage share of exports in total trade value
- **Type**: Numeric (float)

### `import_value`
- **Description**: Import value (US dollars)
- **Type**: Numeric (float)

### `rca_core`
- **Description**: Revealed Comparative Advantage index (Balassa method)
- **Type**: Numeric (float)

### `gdppccons00us`
- **Description**: GDP per capita
- **Type**: Numeric (float)

### `h_rca_core`
- **Description**: Transformed revealed comparative advantage index (balassa method) using hyperbolic sine function
- **Type**: Numeric (float)

### `l_rca_core`
- **Description**: Logarithm of revealed comparative advantage index (balassa method)
- **Type**: Numeric (float)

### `rca_dummy`
- **Description**: Revealed Comparative Advantage (RCA) dummy (0/1)
- **Type**: Numeric (integer)

### `post`
- **Description**: Post-1972 indicator (0/1)
- **Type**: Numeric (integer)

### `reg_id`
- **Description**: Unit ID
- **Type**: category
