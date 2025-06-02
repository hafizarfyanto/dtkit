# dtkit: Data Toolkit for Stata

[![Stata Package](https://img.shields.io/badge/Stata-ado-blue)](https://github.com/hafizarfyanto/dtkit)
![Version](https://img.shields.io/badge/Version-1.0.0-green)
![Stata 16+](https://img.shields.io/badge/Stata-16%2B-purple)
![GitHub Downloads](https://img.shields.io/github/downloads/hafizarfyanto/dtkit/total)
![GitHub Stars](https://img.shields.io/github/stars/hafizarfyanto/dtkit?style=social)
[![GitHub license](https://img.shields.io/github/license/hafizarfyanto/dtkit.svg)](https://github.com/hafizarfyanto/dtkit/blob/main/LICENSE)

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
net install dtkit, replace force from("https://raw.githubusercontent.com/hafizarfyanto/dtkit/main/")
```

## Uninstalling
If you need to remove the package:

```stata
ado uninstall dtkit
```

### Alternative Uninstall Method
If the standard uninstall method doesn't work (e.g., if dtkit was installed multiple times), you can use:

```stata
ado dir dtkit
ado uninstall [pkgid]
```

Where `[pkgid]` is the index number shown by `ado dir dtkit`. This method is useful when you have accidentally installed dtkit multiple times or need to remove a specific installation.

## Commands Overview

### 📊 `dtstat` - Descriptive Statistics
Creates datasets with descriptive statistics

```stata
dtstat price mpg weight
dtstat price mpg, by(foreign)
```

### 🔢 `dtfreq` - Frequency Analysis
Generates frequency tables as datasets

```stata
dtfreq rep78
dtfreq rep78, by(foreign)
```

### 🗂️ `dtmeta` - Dataset Information
Extracts details about your dataset

```stata
dtmeta
dtmeta, save(metadata.xlsx) replace
```

## Practical Workflow

```stata
* Load data
sysuse auto, clear

* Extract dataset information
dtmeta

* Analyze numerical variables
dtstat price mpg weight, by(foreign)

* Examine categorical distributions
dtfreq rep78, by(foreign)

* Access results in frames
frame _df: list, noobs clean
frame _dtvars: list varname type format
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

## Citation

If you use `dtkit` in your research, please cite:

**Plain Text:**
```
Hafiz Arfyanto (2025). dtkit: Data Toolkit for Stata. Version 1.0.0.
Retrieved from https://github.com/hafizarfyanto/dtkit
```

**BibTeX Entry:**
```bibtex
@misc{arfyanto2025dtkit,
  author = {Hafiz Arfyanto},
  title = {dtkit: Data Toolkit for Stata},
  version = {1.0.0},
  year = {2025},
  url = {https://github.com/hafizarfyanto/dtkit},
  note = {Stata package for data exploration and analysis}
}
```

*For detailed documentation, see the official help file in Stata*
```Stata
help dtkit
```
