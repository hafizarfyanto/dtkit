# Changelog

All notable changes to the dtkit project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [dtkit-v1.0.0] - 2025-06-02

### Package Release
- **Initial stable release** of the dtkit data exploration toolkit for Stata
- Complete rewrite and standardization of all three core modules
- Comprehensive test suite with automated tracking and reporting

### Added
- **dtstat-v1.0.0**: Enhanced descriptive statistics with frame output
  - Flexible statistics selection (count, mean, median, sd, min, max, sum, iqr, percentiles)
  - By-group processing with automatic totals
  - Respects user-specified format() option instead of always auto-formatting
  - Multi-sheet Excel export with customizable options
  - Optional gtools integration for performance boost
  - Comprehensive error handling and validation

- **dtfreq-v1.0.0**: Comprehensive frequency analysis and cross-tabulations
  - One-way and two-way frequency tables with flexible output
  - Row, column, and cell proportions/percentages
  - Binary variable reshaping functionality
  - Cross-tabulation with automatic totals
  - Value label preservation and intelligent formatting
  - Excel export with sheet customization

- **dtmeta-v1.0.0**: Dataset metadata extraction into organized frames
  - Variable metadata extraction (_dtvars frame)
  - Value label metadata (_dtlabel frame) 
  - Variable notes extraction (_dtnotes frame)
  - Dataset information and characteristics (_dtinfo frame)
  - Multi-sheet Excel export for all metadata frames
  - Optional detailed reporting with frame access commands
  - Graceful handling of datasets with no notes/labels

### Improved
- **Consistent file handling**: All modules use robust `save(string asis)` with compound quotes
- **Standardized Excel export**: Uniform behavior across all modules with replace/modify options
- **Enhanced documentation**: Complete help files with practical examples
- **Test coverage**: Comprehensive test suites with 79 total tests across all modules
- **Frame management**: Improved creation, labeling, and cleanup of output frames

### Technical
- **Stata 16+ compatibility**: Leverages modern frame functionality
- **Weight support**: All weight types (aweight, fweight, iweight, pweight) supported
- **Conditional processing**: Full support for if/in qualifiers
- **Error handling**: Robust validation and informative error messages

### Documentation
- Updated help files with examples matching test patterns
- Comprehensive README.md with installation and usage instructions
- BibTeX citation format for academic use
- Practical examples using standard Stata datasets

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