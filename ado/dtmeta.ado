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
    _makedtanotes , source_frame(`source_frame') target_frame(`_dtinfo')
end

// * create variable metadata
capture program drop _makevars
program define _makevars
    syntax , source_frame(name) target_frame(name)
    frame copy `source_frame' `target_frame', replace
    frame `target_frame': describe, replace clear
    frame `target_frame': rename name varname
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
    frame `collector': set obs 0
    frame `collector': generate varname = ""
    frame `collector': generate _note_id = .
    frame `collector': generate strL _note_text = ""

    foreach var of local varnotelist {
        frame `source_frame': notes _count notecount : `var'
        forvalues i = 1/`notecount' {
            frame `source_frame': notes _fetch text : `var' `i'
            frame `collector': set obs `=_N+1'
            frame `collector': replace varname = "`var'" in l // l refers to last observation
            frame `collector': replace _note_id = `i' in `=_N' // we can use this as well l and `=_N' are equivalent
            frame `collector': replace _note_text = `"`text'"' in `=_N'
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
        quietly replace varname = "`r(`lbl')'" if vallab == "`lbl'"
    }
    frame `target_frame': quietly sort vallab value
    frame `target_frame': quietly by vallab: generate index = _n
    frame `target_frame': order varname index vallab
    frame `target_frame': list, noobs
end

// Subroutine 4: Dataset notes
capture program drop _makedtanotes
program define _makedtanotes
    syntax , source_frame(name) target_frame(name)

    tempname collector
    frame create `collector' 
    frame `collector': set obs 0
    frame `collector': generate varname = ""
    frame `collector': generate _note_id = .
    frame `collector': generate strL _note_text = ""

    frame `source_frame': notes _count notecount : _dta
    forvalues i = 1/`notecount' {
        frame `source_frame': notes _fetch text : _dta `i'
        frame `collector': set obs `=_N+1'
        frame `collector': replace varname = "_dta" in l // l refers to last observation
        frame `collector': replace _note_id = `i' in `=_N' // we can use this as well l and `=_N' are equivalent
        frame `collector': replace _note_text = `"`text'"' in l
    }
    frame copy `collector' `target_frame', replace
    frame drop `collector'
    frame `target_frame': list, noobs
end

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