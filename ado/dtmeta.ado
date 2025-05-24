capture program drop dtmeta
program define dtmeta
    *! Version 1.0.0 Hafiz 25May2025
    * Module to produce three metadata datasets in separate frames
    
    version 16
    syntax [using/] [, Clear Saving(string) REPlace MERge REPORT]
    
    // * INPUT VALIDATION AND SETUP
    local currentframe = c(frame)

    // Enhanced input validation
    if "`using'" != "" {
        local url_regex `"^((https?|ftp)://[-A-Za-z0-9\._~:/?#\[\]@!$&'()*+,;=%]+)$"'
        local url_find_regex `"((https?|ftp)://[-A-Za-z0-9\._~:/?#\[\]@!$&'()*+,;=%]+)"'
        if ustrregexm("`using'", `"`url_regex'"') == 0 & ustrregexm("`using'", `"`url_find_regex'"') == 0 {
            // Validate external file exists in a desktop
            capture confirm file "`using'"
            if _rc {
                display as error "file `using' not found"
                exit 601
            }
        }
        local datasource "`using'"
        local use_external = 1
    }
    else {
        // Check if data is loaded in memory
        if c(N) == 0 & c(k) == 0 {
            display as error "no data in memory; specify a filename with 'using' or load data first"
            exit 2000
        }
        local use_external = 0
        local dataname = c(filename)
        local datasource "`dataname'"
    }
    
    // Define fixed frame names
    local frame_var = "_dtvars"
    local frame_varnote = "_dtnotes" 
    local frame_dtanote = "_dtinfo"
    local frame_merged = "_dtmeta"
    
    // Validate saving path if specified
    if "`saving'" != "" {
        local savedir = substr("`saving'", 1, strrpos("`saving'", "/"))
        if "`savedir'" != "" & "`savedir'" != "`saving'" {
            capture confirm file "`savedir'"
            if _rc {
                display as error "directory for saving file does not exist: `savedir'"
                exit 170
            }
        }
    }
    
    // * DATA PRESERVATION
    // Store current data in memory if any
    tempfile currentdata
    local has_current_data = 0
    if c(N) > 0 | c(k) > 0 {
        quietly save "`currentdata'"
        local has_current_data = 1
    }
    
    // * DATA LOADING
    if `use_external' quietly use "`datasource'", clear
    display as result "Processing metadata from: `datasource'"
    
    // * BASIC DATASET INFORMATION CAPTURE
    // Store dataset info before any modifications
    local orig_N = c(N)
    local orig_k = c(k)
    local orig_dtalabel : data label
    local orig_filename = "`datasource'"
    local timestamp = "`c(current_date)' `c(current_time)'"
    
    // Get basic variable information using describe
    quietly describe, replace clear
    
    // Store the variable information in locals
    local total_vars = _N
    forvalues i = 1/`total_vars' {
        local var_name_`i' = name[`i']
        local var_type_`i' = type[`i']
        local var_isnumeric_`i' = isnumeric[`i']
        local var_format_`i' = format[`i']
        local var_vallab_`i' = vallab[`i']
        local var_varlab_`i' = varlab[`i']
    }
    
    // * COLLECT NOTES AND VALUE LABELS FROM ORIGINAL DATA
    // Switch back to original data to collect notes and value labels
    if `use_external' {
        quietly use "`datasource'", clear
    }
    else if `has_current_data' {
        quietly use "`currentdata'", clear
    }
    
    // Collect variable notes
    local total_var_note_entries = 0
    forvalues i = 1/`total_vars' {
        local varname = "`var_name_`i''"
        local note_count_`i' = 0
        
        // Count and store notes for this variable
        local j = 1
        while "`: char `varname'[note`j']'" != "" {
            local var_note_`i'_`j' = `"`: char `varname'[note`j']'"'
            local note_count_`i' = `j'
            local j = `j' + 1
        }
        local total_var_note_entries = `total_var_note_entries' + `note_count_`i''
    }
    
    // Collect dataset notes
    local dta_note_count = 0
    local j = 1
    while "`: char _dta[note`j']'" != "" {
        local dta_note_`j' = `"`: char _dta[note`j']'"'
        local dta_note_count = `j'
        local j = `j' + 1
    }
    
    // Collect value labels information
    local total_value_mappings = 0
    forvalues i = 1/`total_vars' {
        local vlab = "`var_vallab_`i''"
        local varname = "`var_name_`i''"
        local value_count_`i' = 0
        
        if "`vlab'" != "" {
            quietly {
                capture levelsof `varname', local(observed_values)
                if _rc == 0 {
                    local map_count = 0
                    foreach val of local observed_values {
                        local label_text : label `vlab' `val'
                        // Include if there's a label different from the value
                        if "`label_text'" != "`val'" & "`label_text'" != "" {
                            local map_count = `map_count' + 1
                            local var_`i'_val_`map_count' = "`val'"
                            local var_`i'_lab_`map_count' = "`label_text'"
                        }
                    }
                    local value_count_`i' = `map_count'
                    local total_value_mappings = `total_value_mappings' + `map_count'
                }
            }
        }
    }
    
    // * CREATE FRAME 1: VARIABLE METADATA + VALUE LABELS
    // Handle existing frames based on replace option
    if "`replace'" != "" {
        capture frame drop `frame_var'
        capture frame drop `frame_varnote'
        capture frame drop `frame_dtanote'
        capture frame drop `frame_merged'
    }
    else {
        // Check if frames already exist
        capture frame dir
        local existing_frames = r(frames)
        local frames_to_check = "`frame_var' `frame_varnote' `frame_dtanote'"
        if "`merge'" != "" {
            local frames_to_check = "`frames_to_check' `frame_merged'"
        }
        
        foreach frame in `frames_to_check' {
            local frame_exists = 0
            foreach existing of local existing_frames {
                if "`existing'" == "`frame'" {
                    local frame_exists = 1
                    continue, break
                }
            }
            if `frame_exists' {
                display as error "frame `frame' already exists; use replace option to overwrite"
                exit 110
            }
        }
    }
    
    // Calculate total rows needed for variable metadata frame
    local var_frame_rows = 0
    forvalues i = 1/`total_vars' {
        if `value_count_`i'' > 0 {
            local var_frame_rows = `var_frame_rows' + `value_count_`i''
        }
        else {
            local var_frame_rows = `var_frame_rows' + 1  // One row even if no value labels
        }
    }
    
    frame create `frame_var'
    frame `frame_var' {
        clear
        quietly {
            set obs `var_frame_rows'
            
            // Create variables with ID system
            generate int var_id = .
            generate int row_id = _n
            generate str32 name = ""
            generate str9 type = ""
            generate byte isnumeric = .
            generate str49 format = ""
            generate str32 vallab = ""
            generate str80 varlab = ""
            generate str50 value_code = ""
            generate str244 value_label = ""
            generate str244 dta_label = `"`orig_dtalabel'"'
            generate long orig_N = `orig_N'
            generate int orig_k = `orig_k'
            generate str20 meta_created = "`timestamp'"
        }
        // Populate the data
        local current_row = 1
        forvalues i = 1/`total_vars' {
            if `value_count_`i'' > 0 {
                // Variable has value labels - one row per value-label pair
                forvalues j = 1/`value_count_`i'' {
                    quietly {
                        replace var_id = `i' in `current_row'
                        replace name = "`var_name_`i''" in `current_row'
                        replace type = "`var_type_`i''" in `current_row'
                        replace isnumeric = `var_isnumeric_`i'' in `current_row'
                        replace format = "`var_format_`i''" in `current_row'
                        replace vallab = "`var_vallab_`i''" in `current_row'
                        replace varlab = `"`var_varlab_`i''"' in `current_row'
                        replace value_code = "`var_`i'_val_`j''" in `current_row'
                        replace value_label = `"`var_`i'_lab_`j''"' in `current_row'
                    }
                    local current_row = `current_row' + 1
                }
            }
            else {
                // Variable has no value labels - one row with empty value info
                quietly {
                    replace var_id = `i' in `current_row'
                    replace name = "`var_name_`i''" in `current_row'
                    replace type = "`var_type_`i''" in `current_row'
                    replace isnumeric = `var_isnumeric_`i'' in `current_row'
                    replace format = "`var_format_`i''" in `current_row'
                    replace vallab = "`var_vallab_`i''" in `current_row'
                    replace varlab = `"`var_varlab_`i''"' in `current_row'
                    replace value_code = "" in `current_row'
                    replace value_label = "" in `current_row'
                }
                local current_row = `current_row' + 1
            }
        }
        
        // Add variable labels
        label variable var_id "Variable ID (sequential number)"
        label variable row_id "Row ID within this frame"
        label variable name "Variable name"
        label variable type "Variable type"
        label variable isnumeric "Numeric indicator"
        label variable format "Display format"
        label variable vallab "Value label name"
        label variable varlab "Variable label"
        label variable value_code "Value code (empty if no value labels)"
        label variable value_label "Value label text (empty if no value labels)"
        label variable dta_label "Dataset label"
        label variable orig_N "Original number of observations"
        label variable orig_k "Original number of variables"
        label variable meta_created "Metadata creation timestamp"
        
        // Sort by variable ID then value code
        sort var_id value_code
    }
    
    // * CREATE FRAME 2: VARIABLE NOTES
    if `total_var_note_entries' > 0 {
        frame create `frame_varnote'
        frame `frame_varnote' {
            clear
            quietly set obs `total_var_note_entries'
            
            // Create variables with ID system
            quietly {
                generate int var_id = .
                generate int row_id = _n
                generate str32 name = ""
                generate int note_sequence = .
                generate str2045 note_text = ""
                generate str244 dta_label = `"`orig_dtalabel'"'
                generate long orig_N = `orig_N'
                generate int orig_k = `orig_k'
                generate str20 meta_created = "`timestamp'"
            }
            
            // Populate variable notes
            local current_row = 1
            forvalues i = 1/`total_vars' {
                if `note_count_`i'' > 0 {
                    forvalues j = 1/`note_count_`i'' {
                        quietly {
                            replace var_id = `i' in `current_row'
                            replace name = "`var_name_`i''" in `current_row'
                            replace note_sequence = `j' in `current_row'
                            replace note_text = `"`var_note_`i'_`j''"' in `current_row'
                        }
                        local current_row = `current_row' + 1
                    }
                }
            }
            
            // Add variable labels
            label variable var_id "Variable ID (sequential number, matches metavar frame)"
            label variable row_id "Row ID within this frame"
            label variable name "Variable name"
            label variable note_sequence "Note sequence number"
            label variable note_text "Note text content"
            label variable dta_label "Dataset label"
            label variable orig_N "Original number of observations"
            label variable orig_k "Original number of variables"
            label variable meta_created "Metadata creation timestamp"
            
            // Sort by variable ID then sequence
            sort var_id note_sequence
        }
    }
    else {
        frame create `frame_varnote'
        frame `frame_varnote' {
            clear
            // Create empty structure with ID system
            quietly {
                generate int var_id = .
                generate int row_id = _n
                generate str32 name = ""
                generate int note_sequence = .
                generate str2045 note_text = ""
                generate str244 dta_label = `"`orig_dtalabel'"'
                generate long orig_N = `orig_N'
                generate int orig_k = `orig_k'
                generate str20 meta_created = "`timestamp'"
            }
            
            label variable var_id "Variable ID (sequential number, matches metavar frame)"
            label variable row_id "Row ID within this frame"
            label variable name "Variable name"
            label variable note_sequence "Note sequence number"
            label variable note_text "Note text content"
            label variable dta_label "Dataset label"
            label variable orig_N "Original number of observations"
            label variable orig_k "Original number of variables"
            label variable meta_created "Metadata creation timestamp"
        }
    }
    
    // * CREATE FRAME 3: DATASET NOTES
    frame create `frame_dtanote'
    frame `frame_dtanote' {
        clear
        quietly set obs `=max(1, `dta_note_count')'
        
        // Create variables with ID system
        quietly {
            generate int dataset_id = 1  // Constant ID for dataset-level notes
            generate int row_id = _n
            generate int note_sequence = .
            generate str2045 note_text = ""
            generate str244 dta_label = `"`orig_dtalabel'"'
            generate long orig_N = `orig_N'
            generate int orig_k = `orig_k'
            generate str20 meta_created = "`timestamp'"
        }
        
        // Populate dataset notes
        if `dta_note_count' > 0 {
            forvalues j = 1/`dta_note_count' {
                quietly {
                    replace note_sequence = `j' in `j'
                    replace note_text = `"`dta_note_`j''"' in `j'
                }
            }
        }
        else {
            // No dataset notes - create one empty row
            quietly {
                replace note_sequence = 0 in 1
                replace note_text = "" in 1
            }
        }
        
        // Add variable labels
        label variable dataset_id "Dataset ID (constant=1 for dataset-level notes)"
        label variable row_id "Row ID within this frame"
        label variable note_sequence "Note sequence number (0 if no notes)"
        label variable note_text "Dataset note text content"
        label variable dta_label "Dataset label"
        label variable orig_N "Original number of observations"
        label variable orig_k "Original number of variables"
        label variable meta_created "Metadata creation timestamp"
        
        // Sort by sequence
        sort note_sequence
    }
    
    // * COMPRESS ALL DATASETS
    frame `frame_var': quietly compress
    frame `frame_varnote': quietly compress  
    frame `frame_dtanote': quietly compress
    
    // * CREATE MERGED FRAME IF REQUESTED
    if "`merge'" != "" {
        // Create merged frame using simple merge/append operations
        frame `frame_var' {
            frame put *, into(`frame_merged')
        }
        
        frame `frame_merged' {
            // Save other frames as temporary files for merging
            frame `frame_varnote': tempfile dtnotes
            frame `frame_varnote': quietly save `dtnotes'
            frame `frame_dtanote': tempfile dtinfo  
            frame `frame_dtanote': quietly save `dtinfo'
            
            // Merge with variable notes (many-to-many since variables can have multiple notes and value labels)
            quietly merge m:m var_id using `dtnotes', nogenerate
            sort var_id row_id note_sequence
            
            // Append dataset notes at the end
            quietly append using `dtinfo'
            
            // Add merged frame identification
            quietly {
                generate str15 frame_type = ""
                replace frame_type = "variable" if name != "" & note_sequence == .
                replace frame_type = "var_note" if name != "" & note_sequence != .
                replace frame_type = "dataset_note" if name == ""
            }
            
            // Clean up and organize
            order frame_type var_id dataset_id row_id name type format vallab varlab ///
                  value_code value_label note_sequence note_text
            sort frame_type var_id dataset_id note_sequence
            
            // Add frame_type label
            label variable frame_type "Type of metadata (variable, var_note, dataset_note)"
            
            quietly compress
        }
    }
    
    // * SAVE FILES IF REQUESTED
    if "`saving'" != "" {
        frame `frame_var': quietly save "`saving'_vars.dta", `replace'
        frame `frame_varnote': quietly save "`saving'_notes.dta", `replace'
        frame `frame_dtanote': quietly save "`saving'_info.dta", `replace'
        
        if "`merge'" != "" {
            frame `frame_merged': quietly save "`saving'_meta.dta", `replace'
        }
        
        display as result "Metadata saved to:"
        display as result "  Variables + Value Labels: `saving'_vars.dta"
        display as result "  Variable Notes: `saving'_notes.dta"
        display as result "  Dataset Info: `saving'_info.dta"
        if "`merge'" != "" {
            display as result "  Merged Metadata: `saving'_meta.dta"
        }
    }
    
    // * OUTPUT SUMMARY AND RESULTS
    if "`report'" != "" {
        display as result _n "Dataset metadata created successfully in " _c
        if "`merge'" != "" {
            display as result "4 frames"
        }
        else {
            display as result "3 frames"
        }
        display as result "Source: " as result "`orig_filename'"
        display as result "Variables documented: " as result `orig_k'
        display as result "Original observations: " as result `orig_N'
        display as result _n "Frames created:"
        display as result "  1. _dtvars (variables + value labels): " as result `var_frame_rows' " rows"
        display as result "  2. _dtnotes (variable notes): " as result `total_var_note_entries' " rows" 
        display as result "  3. _dtinfo (dataset notes): " as result `=max(1, `dta_note_count')' " rows"
        if "`merge'" != "" {
            frame `frame_merged': local merged_rows = _N
            display as result "  4. _dtmeta (merged metadata): " as result `merged_rows' " rows"
        }
        
        // Show sample from each frame
        display as result _n "Sample from variable metadata (frame: _dtvars):"
        frame `frame_var': list var_id row_id name type value_code value_label in 1/5, ///
            abbreviate(12) separator(0)
        
        if `total_var_note_entries' > 0 {
            display as result _n "Sample from variable notes (frame: _dtnotes):"
            frame `frame_varnote': list var_id row_id name note_sequence note_text in 1/3, ///
                abbreviate(25) separator(0)
        }
        
        if `dta_note_count' > 0 {
            display as result _n "Dataset notes (frame: _dtinfo):"
            frame `frame_dtanote': list dataset_id row_id note_sequence note_text, ///
                noobs abbreviate(35) separator(0)
        }
        
        if "`merge'" != "" {
            display as result _n "Sample from merged metadata (frame: _dtmeta):"
            frame `frame_merged': list frame_type var_id name note_text in 1/8, ///
                abbreviate(20) separator(0)
        }
    
        // * CLEANUP AND DATA RESTORATION
        // Handle data restoration based on options
        if "`clear'" != "" {
            clear
            display as result _n "Original data cleared. Use 'frame change framename' to view metadata."
        }
        else if `has_current_data' {
            if "`saving'" != "" {
                display as result _n "Metadata saved to files. Original data restored to memory."
            }
            else {
                display as result _n "Original data restored to memory."
            }
            quietly use "`currentdata'", clear
        }
        else {
            clear
            display as result _n "Use 'frame change framename' to view metadata frames."
        }
    }
    display as result _n "Frame access commands:"
    display as text "  " as smcl "{stata frame change _dtvars}" as text "  // Variables + value labels"
    display as text "  " as smcl "{stata frame change _dtnotes}" as text " // Variable notes"  
    display as text "  " as smcl "{stata frame change _dtinfo}" as text "  // Dataset notes"
    if "`merge'" != "" {
        display as text "  " as smcl "{stata frame change _dtmeta}" as text "  // Merged metadata (all combined)"
    }
    display as text "  " as smcl "{stata frame change `currentframe'}" as text "  // Return to main data"
        
end