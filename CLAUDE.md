# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Package Overview

dtkit is a Stata package providing enhanced data exploration through frame-based output. The package contains three main commands that create structured datasets instead of display-only results.

## Architecture

### Core Commands
- **dtfreq** (739 lines): Frequency analysis with cross-tabulation capabilities
- **dtstat** (419 lines): Descriptive statistics with grouping support  
- **dtmeta** (389 lines): Dataset metadata extraction into organized frames

### Shared Infrastructure
- `_formatvars()`: Intelligent number formatting (shared across dtfreq/dtstat)
- `_toexcel()`: Excel export functionality
- `_argload()`: Data source management (using vs. in-memory data)
- Frame management utilities with automatic cleanup

### Design Patterns
- **Frame-based architecture**: All outputs stored in Stata frames for reusability
- **Modular subroutines**: Each command broken into specialized functions
- **Preservation-first**: Maintains value labels, variable labels, and formatting
- **Shared core functions**: Common utilities to avoid code duplication

## Testing

Run comprehensive test suites located in `/test/` directory:

```stata
* Test individual commands
do test/dtfreq_test1.do    // 532 lines of tests
do test/dtstat_test1.do    // 544 lines of tests  
do test/dtmeta_test1.do    // 265 lines of tests

* Or run all tests
foreach cmd in dtfreq dtstat dtmeta {
    do test/`cmd'_test1.do
}
```

Tests include basic functionality, error conditions, weight support, Excel export, and performance validation.

## Development Commands

### Package Installation (for testing)
```stata
* Install from local development
net install dtkit, from("`c(pwd)'") replace

* Test installation
help dtkit
```

### Version Management
- Update version numbers in: `dtkit.pkg`, individual `.ado` files, and `.sthlp` help files
- Maintain semantic versioning across components
- Update `changelog.md` with detailed changes

### Key File Relationships
- `.ado` files contain main command logic with modular subroutines
- `.sthlp` files provide comprehensive documentation with cross-references
- `examples/*.do` demonstrate practical usage patterns
- `test/*.do` provide validation and regression testing

## Technical Notes

### Stata Version Requirements
- Minimum: Stata 16+ (required for frames functionality)
- Optional dependency: gtools package for dtstat performance enhancement

### Frame Naming Conventions
- Default output frame: `_df`
- Metadata frames: `_dtvars`, `_dtlabel`, `_dtnotes`, `_dtinfo`
- User can specify custom frame names via `df()` option

### Excel Export Architecture
- Shared `_toexcel()` function across all commands
- Supports worksheet naming and file overwrite options
- Preserves formatting and value labels in export

### Performance Considerations
- dtstat supports `fast` option using gtools for large datasets
- Mata integration in dtfreq for optimized cross-tabulation calculations
- Memory-efficient frame management for large data processing