clear frames
// Basic metadata extraction from data in memory

    . sysuse auto
    . dtmeta

// Extract metadata from external file

    . dtmeta using "https://www.stata-press.com/data/r18/nlswork.dta", replace

// Save metadata to files with replace

    . dtmeta using "https://www.stata-press.com/data/r18/nlswork.dta", saving("meta_output") replace

// Create merged metadata frame

    . dtmeta, merge replace
    . frame _dtmeta: tab frame_type

// Work with metadata

    . dtmeta using "https://www.stata-press.com/data/r18/nlswork.dta", merge replace
    . frame _dtmeta: keep if frame_type == "variable"

// Analyze value label coverage

    . dtmeta, replace
    . frame _dtvars: generate has_vallab = (value_code != "")
    . frame _dtvars: bysort name: egen max_vallab = max(has_vallab)
    . frame _dtvars: by name: keep if _n == 1
    . frame _dtvars: tab max_vallab

// Document variables with notes

    . dtmeta, replace
    . frame _dtnotes: list name note_text

// Comprehensive metadata report

    . dtmeta, merge saving("project_meta") replace report
    . frame _dtmeta: list if frame_type == "dataset_note"