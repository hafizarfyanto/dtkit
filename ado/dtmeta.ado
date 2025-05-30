capture program drop dtmeta
program define dtmeta, rclass
    *! Version 2.1.0 Hafiz 30May2025
    * Module to produce three metadata datasets in separate frames
    
    version 16
    syntax [using/] [, Clear REPlace REPORT excel(string asis)]

    // validate inputs
    _argload, clear(`clear') using(`using') replace(`replace') excel(`excel')

    // Define frames
    local source_frame `r(source_frame)'
    local _defaultframe `r(_defaultframe)'
    foreach frname in _dtvars _dtlabel _dtnotes _dtinfo {
        local `frname' "`frname'"
        capture frame drop `frname'
        capture frame create `frname'
    }

    // Create and check metadata datasets
    _makevars , source_frame(`source_frame') target_frame(`_dtvars')
    _labelframes, frame(`_dtvars') source_frame(`source_frame') // dtvars always has content
    
    _makevarnotes , source_frame(`source_frame') target_frame(`_dtnotes')
    _isempty, frame(`_dtnotes') message("the dataset has no variable notes") source_frame(`source_frame')
    
    _makevallab , source_frame(`source_frame') target_frame(`_dtlabel')
    _isempty, frame(`_dtlabel') message("the dataset has no value labels") source_frame(`source_frame')
    
    _makedtainfo , source_frame(`source_frame') target_frame(`_dtinfo')
    _labelframes, frame(`_dtinfo') source_frame(`source_frame') // dtinfo always has content

    // store returned results
    quietly describe, varlist
    return add
    quietly labelbook
    return add

    // export to excel
    if `"`excel'"' != "" _toexcel, excel(`excel')
    if "`_defaultframe'" != "" cwf `_defaultframe'
    return local source_frame `source_frame'

    // Generate report if requested
    _makereport, source_frame(`source_frame') clear(`clear') saving(`excel') report(`report')
end

// * create variable metadata
capture program drop _makevars
program define _makevars, rclass
    syntax , source_frame(name) target_frame(name)
    frame copy `source_frame' `target_frame', replace
    frame `target_frame': quietly describe, replace clear
    frame `target_frame': rename name varname
    frame `target_frame': quietly generate _level = "variable", before(position)
end

// * create variable notes
capture program drop _makevarnotes
program define _makevarnotes
    syntax , source_frame(name) target_frame(name)

    frame `source_frame': notes _dir varnotelist
    local varnotelist : subinstr local varnotelist "_dta" "", all
    tempname collector
    frame create `collector' 
    frame `collector' {
        quietly set obs 0
        quietly generate varname = ""
        quietly generate _note_id = .
        quietly generate strL _note_text = ""
        quietly generate _level = "", before(varname)
    }

    foreach var of local varnotelist {
        frame `source_frame': notes _count notecount : `var'
        forvalues i = 1/`notecount' {
            frame `source_frame': notes _fetch text : `var' `i'
            frame `collector' {
                quietly set obs `=_N+1'
                quietly replace varname = "`var'" in l // l refers to last observation
                quietly replace _note_id = `i' in `=_N' // we can use this as well l and `=_N' are equivalent
                quietly replace _note_text = `"`text'"' in `=_N'
                quietly replace _level = "variable" in `=_N'
            }
        }
    }
    frame copy `collector' `target_frame', replace
    frame drop `collector'
end

// * create value labels
capture program drop _makevallab
program define _makevallab, rclass
    syntax , source_frame(name) target_frame(name)
    frame copy `source_frame' `target_frame', replace
    frame `target_frame': uselabel, clear var
    frame `target_frame' {
        if _N == 0 exit
    }
    frame `target_frame': ren lname vallab
    frame `target_frame': quietly generate varname = ""
    foreach lbl in `r(__labnames__)' {
        frame `target_frame': quietly replace varname = "`r(`lbl')'" if vallab == "`lbl'"
    }
    frame `target_frame': quietly sort vallab value
    frame `target_frame': quietly generate _level = "value label"
    frame `target_frame': quietly by vallab: generate index = _n
    frame `target_frame': order _level varname index vallab
end

// * Dataset-level info
capture program drop _makedtainfo
program define _makedtainfo
    syntax , source_frame(name) target_frame(name)

    tempname collector
    frame create `collector' 
    frame `collector' {
        quietly set obs 0
        quietly generate _level = ""
        quietly generate dta_note_id = .
        quietly generate strL dta_note = ""
    } 

    frame `source_frame': notes _count notecount : _dta
    forvalues i = 1/`notecount' {
        frame `source_frame': notes _fetch text : _dta `i'
        frame `collector' {
            quietly set obs `=_N+1'
            quietly replace _level = "dataset" in l // l refers to last observation. l and `=_N' are equivalent
            quietly replace dta_note_id = `i' in l
            quietly replace dta_note = `"`text'"' in l
        } 
    }

    // Get metadata from source dataset
    frame `source_frame' {
        local nobs = c(N)
        local nvars = c(k)
        local dlabel : data label
        local timestamp = c(filedate)
    }

    frame `collector' {
        if c(N) == 0 set obs 1
        // Add new variables with appropriate storage types
        quietly generate long dta_obs = `nobs'
        quietly generate int dta_vars = `nvars'
        quietly generate strL dta_label = `"`dlabel'"'
        quietly generate dta_ts = clock("`timestamp'", "DMY hm")
        format dta_ts %tc
    }

    frame copy `collector' `target_frame', replace
    frame drop `collector'
end

* New subroutine: Check if frame is empty and handle accordingly
capture program drop _isempty
program define _isempty
    syntax , frame(name) message(string) source_frame(name)
    frame `frame' {
        local emptyframe = c(N)
        if `emptyframe' > 0 _labelframes, frame(`frame') source_frame(`source_frame')
    }
    if `emptyframe' == 0 {
        frame drop `frame'
        di as text "Note: `message'"
        exit 0
    }
end

capture program drop _labelframes
program define _labelframes
    syntax, frame(name) source_frame(name)
    // extract filename
    frame `source_frame': local dataname = c(filename)
    if `"`dataname'"' != "" {
        local inputfile = subinstr(`"`dataname'"', `"""', "", .)
        if ustrregexm("`inputfile'", "^(.*[/\\])?([^/\\]+?)(\.[^./\\]+)?$") {
            local fullpath = ustrregexs(1)
            local filename = ustrregexs(2)
            local extension = ustrregexs(3)
            local fullname = "`fullpath'`filename'`extension'"
        }
    }

    if "`frame'" == "_dtvars" {
        frame `frame': label variable varname "Variable name"
        frame `frame': label variable _level "Metadata level"
        frame `frame': label variable position "Variable order in dataset"
        frame `frame': label variable type "Storage type"
        frame `frame': label variable format "Display format"
        frame `frame': label variable vallab "Value label name"
        frame `frame': label variable varlab "Variable label"
        frame `frame': label data "(`filename') Variable metadata"
    }
    else if "`frame'" == "_dtnotes" {
        frame `frame': label variable varname "Variable name"
        frame `frame': label variable _level "Metadata level"
        frame `frame': label variable _note_id "Note ID"
        frame `frame': label variable _note_text "Note content"
        frame `frame': label data "(`filename') Variable notes"
    }
    else if "`frame'" == "_dtlabel" {
        frame `frame': label variable varname "Variable name"
        frame `frame': label variable _level "Metadata level"
        frame `frame': label variable index "Value index"
        frame `frame': label variable vallab "Value label name"
        frame `frame': label variable value "Numeric value"
        frame `frame': label variable label "Value label"
        frame `frame': label variable trunc "= 1 if label text is truncated"
        frame `frame': label data "(`filename') Value label metadata"
    }
    else if "`frame'" == "_dtinfo" {
        frame `frame': label variable _level "Metadata level"
        frame `frame': label variable dta_note_id "Note ID"
        frame `frame': label variable dta_note "Dataset note"
        frame `frame': label variable dta_obs "Observation count"
        frame `frame': label variable dta_vars "Variable count"
        frame `frame': label variable dta_label "Dataset label"
        frame `frame': label variable dta_ts "Dataset timestamp"
        frame `frame': label data "(`filename') Dataset metadata"
    }
end

// * Saves the final table to Excel file
capture program drop _toexcel
program define _toexcel

    syntax, [excel(string asis) replace(string)]

    // export to excel
    if `"`excel'"' != "" {
        local inputfile = subinstr(`"`excel'"', `"""', "", .)
        if ustrregexm("`inputfile'", "^(.*[/\\])?([^/\\]+?)(\.[^./\\]+)?$") {
            local fullpath = ustrregexs(1)
            local filename = ustrregexs(2)
            local extension = ustrregexs(3)
            local fullname = "`fullpath'`filename'`extension'"
        }
    }

    if "`fullname'" != "" {
        // Set export options
        quietly frames dir _dt*
        if "`replace'" == "" local exportcmd `"`fullname', sheet("`sheetname'", modify) firstrow(varlabels)"'
        else local exportcmd `"`fullname', sheet("`sheetname'") firstrow(varlabels) replace"'
        foreach fr in `r(frames)' {
            frame `fr': local sheetname: data label
            frame `fr': export excel using `exportcmd'
        }
    }

end

// * Checks if user inputs are valid before starting
capture program drop _argload
program define _argload, rclass
    syntax, [using(string) clear(string) replace(string) excel(string)]

    // clear only makes sense together with using
    if "`clear'" != "" & "`using'" == "" {
        display as error "option clear only allowed with using"
        exit 198
    }

    // replace only makes sense together with excel
    if "`replace'" != "" & "`excel'" == "" {
        display as error "option replace only allowed with excel"
        exit 198
    }

    local _inmemory = c(filename) != "" | c(N) > 0 | c(k) > 0 | c(changed) == 1
    if `_inmemory' == 0 & "`using'" == "" {
        display as error "No data source for generating metadata datasets."
        exit 198
    }

    // define dataset
    if "`using'" != "" {
        if `_inmemory' == 1 & "`clear'" == "" {
            return local _defaultframe = c(frame)
            capture frame drop _dtsource
            frame create _dtsource
            cwf _dtsource
            return local source_frame "_dtsource"
            quietly use `"`using'"', clear
        }
        else {
            quietly use `"`using'"', clear
            return local source_frame = c(frame)
        }
    }
    else if "`using'" == "" & `_inmemory' == 1 return local source_frame = c(frame)

end

// * report metadata creation
capture program drop _makereport
program define _makereport

    syntax, source_frame(name) [clear(string) saving(string) report(string)]
    
    // Get original dataset information
    frame `source_frame' {
        local orig_filename = c(filename)
        local orig_k = c(k)
        local orig_N = c(N)
        
        // Extract just filename without path
        if `"`orig_filename'"' != "" {
            if ustrregexm("`orig_filename'", "^(.*[/\\])?([^/\\]+?)(\.[^./\\]+)?$") {
                local orig_filename = ustrregexs(2) + ustrregexs(3)
            }
        }
        else {
            local orig_filename "data in memory"
        }
    }
    
    // Count rows in each frame and check existence
    quietly frames dir _dt*
    local existing_frames "`r(frames)'"
    
    local frame_count = 0
    local var_frame_rows = 0
    local total_var_note_entries = 0
    local dta_note_count = 0
    local vallab_frame_rows = 0
    
    // Check _dtvars (always exists)
    if `: list posof "_dtvars" in existing_frames' {
        frame _dtvars: local var_frame_rows = _N
        local ++frame_count
    }
    
    // Check _dtnotes
    if `: list posof "_dtnotes" in existing_frames' {
        frame _dtnotes: local total_var_note_entries = _N
        local ++frame_count
    }
    
    // Check _dtlabel  
    if `: list posof "_dtlabel" in existing_frames' {
        frame _dtlabel: local vallab_frame_rows = _N
        local ++frame_count
    }
    
    // Check _dtinfo (always exists)
    if `: list posof "_dtinfo" in existing_frames' {
        frame _dtinfo: local dta_note_count = _N
        local ++frame_count
    }
    if "`report'" != "" {
        // Display summary
        display as result _n "Dataset metadata created successfully in " as result `frame_count' " frames"
        display as result "Source: " as result "`orig_filename'"
        display as result "Variables documented: " as result `orig_k'
        display as result "Original observations: " as result `orig_N'
        display as result _n "Frames created:"
        
        local frame_num = 1
        if `: list posof "_dtvars" in existing_frames' {
            display as result "  `frame_num'. _dtvars (variables metadata): " as result `var_frame_rows' " rows"
            local ++frame_num
        }
        
        if `: list posof "_dtnotes" in existing_frames' {
            display as result "  `frame_num'. _dtnotes (variable notes): " as result `total_var_note_entries' " rows"
            local ++frame_num
        }
        
        if `: list posof "_dtlabel" in existing_frames' {
            display as result "  `frame_num'. _dtlabel (value labels): " as result `vallab_frame_rows' " rows"
            local ++frame_num
        }
        
        if `: list posof "_dtinfo" in existing_frames' {
            display as result "  `frame_num'. _dtinfo (dataset notes): " as result `dta_note_count' " rows"
        }
    }


    // Display frame access commands
    display as result _n "Finish creating metadata datasets. Frame access commands:"
    if `: list posof "_dtvars" in existing_frames' {
        display as text "  " as smcl "{stata frame change _dtvars}" as text "  // Variables + metadata"
    }
    if `: list posof "_dtnotes" in existing_frames' {
        display as text "  " as smcl "{stata frame change _dtnotes}" as text " // Variable notes"
    }
    if `: list posof "_dtlabel" in existing_frames' {
        display as text "  " as smcl "{stata frame change _dtlabel}" as text " // Value labels"
    }
    if `: list posof "_dtinfo" in existing_frames' {
        display as text "  " as smcl "{stata frame change _dtinfo}" as text "  // Dataset metadata"
    }
    display as text "  " as smcl "{stata frame change `source_frame'}" as text "  // Return to source data"
    
end