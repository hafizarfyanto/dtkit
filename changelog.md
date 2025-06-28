# Changelog

All notable changes to the dtkit project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Package Release [dtkit-v1.0.1] - 2025-06-03

- This update includes an important bug fix for the `dtfreq` and `dtstat` commands.
- Component versions included in this release:
  - **dtfreq: v1.0.1 (Updated)**
  - **dtstat: v1.0.1 (Updated)**
  - dtmeta: v1.0.0 (Unchanged)

### Fixed

- **dtfreq v1.0.1**:
  - Fixed an issue where the "Total" row in tables created with the `cross()` option sometimes showed incorrect calculations for proportions and percentages. Totals are now accurate.
- **dtstat v1.0.1**:
  - Fixed unused internal subroutine for sample marking.
  
## Package Release [dtkit-v1.0.0] - 2025-06-02

- **First official release** of the `dtkit` tools for Stata.
- All tools (`dtfreq`, `dtstat`, `dtmeta`) have been fully updated for better performance and easier use.
- Thoroughly tested for reliability.

### Added

New tools included in this release:

- **dtstat v1.0.0**: For descriptive statistics.
  - Choose from many stats (count, mean, median, sd, min, max, sum, iqr, percentiles).
  - Get stats for groups, with automatic totals.
  - Uses your chosen number format, instead of auto-formatting.
  - Export to Excel with multiple sheets and options.
  - Faster if you have `gtools` installed (optional).

- **dtfreq v1.0.0**: For frequency tables and cross-tabulations.
  - Create one-way and two-way tables easily.
  - Shows row, column, and cell proportions/percentages.
  - Helps organize data for variables with two categories (e.g., yes/no).
  - Automatically adds totals to cross-tabulations.
  - Keeps your value labels and formats numbers smartly.
  - Export to Excel with options to customize sheets.

- **dtmeta v1.0.0**: To get information about your dataset.
  - Extracts details about variables, value labels, and notes into new, organized dataset (frames).
  - Also provides general information about your dataset.
  - Export all this information to Excel, with multiple sheets.
  - Includes commands to easily view these new tables.
  - Works well even if your dataset doesn't have many notes or labels.

### Improved

General improvements for all tools:

- **File Saving**: More reliable when saving files.
- **Excel Export**: Consistent Excel export options across all tools.
- **Help Files**: Updated help files with more examples.
- **Reliability**: Increased reliability from extensive testing.
- **Table Handling**: Better management of the tables (frames) created by the tools.
- **Stata Compatibility**: Works with Stata 16 and newer.
- **Weight Support**: Supports all standard Stata weight types.
- **Error Messages**: More helpful error messages.
- **Documentation**: README file updated with clear installation and usage steps. Citation information provided for academic use.

---

## Version Tag Strategy

- **dtkit-vX.Y.Z**: Overall package releases
- **dtstat-vX.Y.Z**: dtstat module-specific releases  
- **dtfreq-vX.Y.Z**: dtfreq module-specific releases
- **dtmeta-vX.Y.Z**: dtmeta module-specific releases

## Previous Versions

### Pre-v1.0.0

- Development versions with inconsistent functionality
- Mixed version numbers across modules
- Limited documentation and test coverage
