capture program drop dtmeta
program define dtmeta
    *! Version 2.1.0 Hafiz 30May2025
    * Module to produce three metadata datasets in separate frames
    
    version 16
    syntax [using/] [, Clear Saving(string) REPlace MERge REPORT]

    // Define default frame names
    local source_frame = c(frame)
    foreach frname in _dtvars _dtlabel _dtnotes _dtinfo {
        local `frname' "`frname'"
        capture frame drop `frname'
        capture frame create `frname'
    }


    // Create metadata datasets via subroutines
    _makevars , source_frame(`source_frame') target_frame(`_dtvars')
    _makevarnotes , source_frame(`source_frame') target_frame(`_dtnotes')
    _makevallab , source_frame(`source_frame') target_frame(`_dtlabel')
    _makedtainfo , source_frame(`source_frame') target_frame(`_dtinfo')
end

// * create variable metadata
capture program drop _makevars
program define _makevars
    syntax , source_frame(name) target_frame(name)
    frame copy `source_frame' `target_frame', replace
    frame `target_frame': describe, replace clear
    frame `target_frame': rename name varname
    frame `target_frame': quietly generate _level = "variable", before(position)
    frame `target_frame': list, noobs
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
    frame `target_frame': list, noobs
end

// * create value labels
capture program drop _makevallab
program define _makevallab
    syntax , source_frame(name) target_frame(name)
    frame copy `source_frame' `target_frame', replace
    frame `target_frame': uselabel, clear var
    frame `target_frame': ren lname vallab
    frame `target_frame': quietly generate varname = ""
    foreach lbl in `r(__labnames__)' {
        frame `target_frame': quietly replace varname = "`r(`lbl')'" if vallab == "`lbl'"
    }
    frame `target_frame': quietly sort vallab value
    frame `target_frame': quietly generate _level = "value label"
    frame `target_frame': quietly by vallab: generate index = _n
    frame `target_frame': order _level varname index vallab
    frame `target_frame': list, noobs
end

// Subroutine 4: Dataset notes
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
        format dta_t %tc
    }

    frame copy `collector' `target_frame', replace
    frame drop `collector'
    frame `target_frame': list, noobs
end

// todo: labeling variables, using and exopt to export datasets to excel, merge in wide format.

clear frames
sysuse nlsw88, clear
notes union : note 1
notes union : note 2
notes union : note 3
notes south : note 1
notes south : note 2
notes south : note 3

// set trace on
// set tracedepth 2
dtmeta
set trace off
exit, clear