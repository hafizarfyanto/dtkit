# dtkit: Data Toolkit for Stata

A lightweight Stata toolkit for efficient data analysis, documentation, and reporting. Streamlines research workflows with organized outputs.

## Key Features

- **Frequency Analysis** (`dtfreq`): Create detailed frequency tables with cross-tabulation, binary variable formatting, and totals
- **Metadata Documentation** (`dtmeta`): Extract and organize comprehensive dataset documentation including variable information, value labels, and notes
- **Descriptive Statistics** (`dtstat`): Generate customizable summary statistics with grouping and comprehensive statistical measures
- **Excel Integration**: Direct export capabilities for `dtfreq` and `dtstat` with customizable formatting
- **Frame-based Results**: Organized output in separate frames for easy navigation and analysis
- **Performance Optimization**: Optional `gtools` integration for faster processing of large datasets
- **Flexible Grouping**: Support for multiple grouping variables with automatic totals calculation

## Installation

Install `dtkit` directly from GitHub using Stata's `net install` command:

```stata
net install dtkit, from("https://raw.githubusercontent.com/hafizarfyanto/dtkit/main/")
```

## Commands

### `dtfreq`
Creates comprehensive frequency tables for numeric variables with support for cross-tabulation, binary variable formatting, and Excel export. Produces frequencies, proportions, and percentages with optional row and column totals.

**Syntax:**
```stata
dtfreq varlist [if] [in] [weight] [using filename] [, options]
```

**Options:**
- `df(framename)` - specify frame name for results (default: "_df")
- `rowby(varname)` - numeric variable for row grouping (creates cross-tabulation)
- `colby(varname)` - numeric variable for column grouping (creates cross-tabulation)
- `yesno` - converts binary variables to yes/no format with appropriate labeling
- `format(%fmt)` - specify number format for all numeric variables
- `nomiss` - exclude missing values from frequency calculations
- `fast` - use gtools for faster processing (requires gtools package)
- `exopt(export_options)` - additional options for Excel export

**Output:** Creates a dataset in the specified frame containing frequencies, proportions, percentages, and totals for each variable and value combination.

### `dtmeta`
Creates comprehensive metadata documentation by extracting variable information, value labels, variable notes, and dataset notes into separate organized frames for analysis and documentation purposes.

**Syntax:**
```stata
dtmeta [using filename] [, options]
```

**Options:**
- `clear` - clear data from memory after creating metadata frames
- `saving(fprefix)` - save metadata to files with specified prefix
- `replace` - replace existing frames/files if they exist
- `merge` - create additional merged frame (_dtmeta) combining all metadata
- `report` - display detailed summary report of created metadata

**Output:** Creates 3 frames: `_dtvars` (variables + value labels), `_dtnotes` (variable notes), `_dtinfo` (dataset notes). With `merge` option, creates additional `_dtmeta` frame.

### `dtstat`
Produces comprehensive descriptive statistics datasets with support for grouping variables, custom statistics selection, and Excel export functionality.

**Syntax:**
```stata
dtstat varlist [if] [in] [weight] [using filename] [, options]
```

**Options:**
- `df(framename)` - specify frame name for results (default: "_df")
- `by(varlist)` - grouping variables for statistics (creates totals automatically)
- `stats(statlist)` - specify statistics to calculate (default: "count mean median min max")
- `format(%fmt)` - specify number format for all numeric variables
- `nomiss` - exclude missing values from calculations
- `fast` - use gtools for faster processing (requires gtools package)
- `exopt(export_options)` - additional options for Excel export

**Available Statistics:**
- Basic: `count`, `sum`, `rawsum`, `mean`, `median`, `min`, `max`
- Variability: `sd`, `semean`, `sebinomial`, `sepoisson`, `iqr`
- Percentiles: `p1`, `p5`, `p10`, `p25`, `p50`, `p75`, `p90`, `p95`, `p99` (and others)
- Extremes: `first`, `last`, `firstnm`, `lastnm`

**Output:** Creates a dataset in the specified frame containing requested statistics for each variable, with optional grouping and totals.

## Examples

### Basic Usage

```stata
* Load your data
use "dataset.dta", clear

* Basic frequency table for a single variable
dtfreq education_level

* Create metadata documentation for current dataset
dtmeta, report

* Generate descriptive statistics for numeric variables
dtstat income age height weight

* Frequency table excluding missing values
dtfreq income_category, nomiss

* Descriptive statistics with grouping
dtstat test_scores, by(school_id treatment_group)

* Cross-tabulation with row and column grouping
dtfreq treatment_response, rowby(gender) colby(age_group)

* Create metadata from external file with saving
dtmeta using "survey_data.dta", saving(metadata) replace report

* Custom statistics selection
dtstat revenue profit, stats(count mean median sd min max p25 p75)

* Convert binary variables to yes/no format
dtfreq employed married, yesno

* Export frequency table to Excel
dtfreq satisfaction_score using "results.xlsx"

* Export statistics with custom Excel options
dtstat financial_vars*, using "stats.xlsx", exopt(sheet("Summary", replace) firstrow(varlabels))

* Use fast processing with gtools (if installed)
dtfreq multiple_vars, fast
dtstat large_dataset_vars*, fast by(region)
```

### Advanced Examples

```stata
* Complex cross-tabulation with yes/no formatting and Excel export
dtfreq disease_status treatment_success, ///
    rowby(hospital_id) colby(patient_type) yesno ///
    using "medical_analysis.xlsx", ///
    exopt(sheet("Results", replace) firstrow(varlabels))

* Weighted frequency analysis with custom frame
dtfreq survey_response [pweight=sample_weight], ///
    df(survey_results) rowby(region) nomiss

* Fast processing of large dataset with multiple grouping variables
dtfreq outcome_vars*, fast rowby(treatment_group) colby(time_period)
```

For more detailed examples, see the files in the `examples/` folder:
- `dtfreq_examples.do` - Demonstrates dtfreq usage with various options
- `dtmeta_examples.do` - Demonstrates dtmeta usage  
- `dtstat_examples.do` - Demonstrates dtstat usage

## Getting Help

For help with any command, use Stata's built-in help system:

```stata
help dtfreq   // Frequency tables and cross-tabulations
help dtmeta   // Metadata documentation and extraction  
help dtstat    // Descriptive statistics and summaries
help dtkit    // General package information
```

### Frame Management

The `dtkit` commands create results in separate frames. To navigate between frames:

```stata
* View frequency results
frame change _df

* View metadata frames  
frame change _dtvars   // Variables and value labels
frame change _dtnotes  // Variable notes
frame change _dtinfo   // Dataset notes
frame change _dtmeta   // Merged metadata (if created)

* Return to main data
frame change default
```

## Requirements

- Stata 16.0 or later
- Optional: `gtools` package for fast processing (install with `ssc install gtools` followed by `gtools, upgrade`)

## Author

**Hafiz Arfyanto**  
Email: hafizarfyanto@gmail.com

## Version

Current version: 1.0.0 (May 25, 2025)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Issues and pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## Citation

If you use `dtkit` in your research, please cite:

```
Hafiz Arfyanto (2025). dtkit: Data Toolkit for Stata. 
Retrieved from https://github.com/hafizarfyanto/dtkit
```