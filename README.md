# dtkit: Data Toolkit for Stata

[![Stata Package](https://img.shields.io/badge/Stata-ado-blue)](https://github.com/hafizarfyanto/dtkit)
![Version](https://img.shields.io/badge/Version-2.1.0-green)
![Stata 16+](https://img.shields.io/badge/Stata-16%2B-purple)

`dtkit` is a Stata package that transforms data exploration by creating **structured datasets** instead of display-only results. It uses Stata's frame system to deliver improved statistics, frequency analysis, and dataset information.

## Features ✨

- **Creates reusable datasets** from analysis results
- **Exports directly to Excel**
- Preserves value labels automatically
- Supports all Stata weight types
- Optional faster processing with gtools

## Installation

Install `dtkit` directly from GitHub using Stata's `net install` command:

```stata
net install dtkit, from("https://raw.githubusercontent.com/hafizarfyanto/dtkit/main/")
```

## Updating to Latest Version
To ensure you have the most recent features and bug fixes:

```stata
net install dtkit, replace from("https://raw.githubusercontent.com/hafizarfyanto/dtkit/main/")
```

## Uninstalling
If you need to remove the package:

```stata
ado uninstall dtkit
```

## Commands Overview

### 📊 `dtstat` - Descriptive Statistics
Creates datasets with descriptive statistics

```stata
dtstat price mpg weight, by(region) stats(mean sd)
frame dir  // View created frames
```

### 🔢 `dtfreq` - Frequency Analysis
Generates frequency tables as datasets

```stata
dtfreq product, by(region) cross(approved) type(pct)
frame change _df  // Access frequency data
```

### 🗂️ `dtmeta` - Dataset Information
Extracts details about your dataset

```stata
dtmeta
frame _dtvars: describe  // View variable details
```

## Practical Workflow

```stata
* Load data
sysuse nlsw88, clear

* Extract dataset information
dtmeta

* Analyze numerical variables
dtstat wage hours, by(union) stats(mean sd p50)

* Examine categorical distributions
dtfreq occupation, by(married) cross(collgrad) type(pct)

* Access results
frame _dtstat: list if stat == "mean"
frame _dtfreq: list occupation if married == 1
```

## Compatibility
- Requires Stata 16 or newer
- Windows 11 compatible
- Optional: [`gtools`](https://github.com/mcaceresb/stata-gtools) for speed boost

## Support
Report issues or suggest improvements:  
[GitHub Issues](https://github.com/hafizarfyanto/dtkit/issues)

## Author
Hafiz Arfyanto  
[Email](mailto:hafizarfyanto@gmail.com) | [GitHub](https://github.com/hafizarfyanto)

## License
[MIT License](LICENSE)

## Citation

If you use `dtkit` in your research, please cite:

```
Hafiz Arfyanto (2025). dtkit: Data Toolkit for Stata. 
Retrieved from https://github.com/hafizarfyanto/dtkit
```

*For detailed documentation, see the official help file in Stata*
```Stata
help dtkit
```
