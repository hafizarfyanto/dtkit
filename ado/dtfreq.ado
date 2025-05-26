capture program drop _xtab _xtab_core
capture mata: mata drop _xtab_calc()

// subroutine
program define _xtab
    version 16
    syntax, var(varname) [colby(varname) rowby(varname)]
    
    // Store original frame name and create working frames
    local mainframe = c(frame)
    capture frame drop _df
    frame create _df
    tempname _temp
    frame create `_temp'
    
    // Get variable label from main data
    local varlab: variable label `var'
    if "`varlab'" == "" local varlab "`var'"
    
    // If rowby specified, process each level separately  
    if "`rowby'" != "" {
        frame `mainframe': quietly levelsof `rowby', local(rowby_levels)
        
        foreach level in `rowby_levels' {
            // Get rowby label from main frame
            frame `mainframe': local rowby_label: label (`rowby') `level'
            if "`rowby_label'" == "" local rowby_label "`level'"
            
            // Run analysis for this level
            frame `_temp' {
                _xtab_core "`var'" "`colby'" "`varlab'" "`rowby_label'" `mainframe' "if `rowby' == `level'"
                tempfile _result
                save `_result'
            }
            frame _df: append using `_result'
        }
        
        // Add totals (all data)
        frame `_temp' {
            _xtab_core "`var'" "`colby'" "`varlab'" "Total" `mainframe' ""
            tempfile _result
            save `_result'
        }
        frame _df: append using `_result'
        
        // Switch to results frame and display
        frame change _df
        list
    }
    else {
        // No rowby - just run once
        frame `_temp' {
            _xtab_core "`var'" "`colby'" "`varlab'" "Total" `mainframe' ""
        }
        frame change `_temp'
        list
    }
end

program define _xtab_core
    args var colby varlab stratum_label mainframe if_condition

    frame `mainframe': quietly levelsof `var' `if_condition', local(vallabels)
    
    // Create tabulation with if condition
    if "`colby'" != "" {
        // Two-way tabulation
        local tabcmd "tabulate `var' `colby' `if_condition', matcell(_FREQ) matrow(_ROWVAL) matcol(_COLVAL)"
    }
    else {
        // One-way tabulation  
        local tabcmd "tabulate `var' `if_condition', matcell(_FREQ) matrow(_ROWVAL)"
    }
    frame `mainframe': `tabcmd'
    
    // Call mata function
    mata: _xtab_calc()
    
    // Build variable names - match matrix structure
    local varnamelist "numlab"
    
    if "`colby'" != "" {
        // Two-way: existing logic
        foreach prefix in freq col row cell {
            foreach col in `colval' {
                local varnamelist `varnamelist' `prefix'prop`col'
            }
        }
        local varnamelist = subinstr("`varnamelist'", "freqprop", "freq", .)
    }
    else {
        // One-way: simpler structure
        local varnamelist "`varnamelist' freq prop"
    }

    // Add row values and set column names
    matrix _FULLMAT = (_ROWVAL, _FULLMAT)
    matrix colnames _FULLMAT = `varnamelist'
    
    // Create results dataset
    clear
    svmat _FULLMAT, names(col)
    
    generate varname = "`var'", before(numlab)
    generate varlab = "`varlab'", before(numlab)
    generate rowvarname = "`stratum_label'", before(numlab)
    generate vallab = "", before(numlab)
    
    // Fill value labels using main frame
    foreach val in `vallabels' {
        frame `mainframe': local vallabval: label (`var') `val'
        if "`vallabval'" == "" local vallabval "`val'"
        quietly replace vallab = "`vallabval'" if numlab == `val'
    }
    
    drop numlab
    
    // Calculate totals
    if "`colby'" != "" {
        // Two-way: existing logic
        foreach freq of varlist freq* {
            egen total_`freq' = total(`freq')
        }
        egen freq_all = rowtotal(freq*), missing
        egen total_all = total(freq_all)
    }
    else {
        // One-way: simpler totals
        egen total_freq = total(freq)
        egen total_prop = total(prop)
    }
end

mata:
void _xtab_calc()
{
    _FREQ = st_matrix("_FREQ")
    _ROWVAL = st_matrix("_ROWVAL") 
    
    // Check if this is one-way or two-way
    if (st_local("colby") == "") {
        // One-way tabulation
        _PROP = _FREQ / sum(_FREQ)
        _FULLMAT = (_FREQ, _PROP)
        st_matrix("_FULLMAT", _FULLMAT)
        st_local("colval", "")  // No column values for one-way
    }
    else {
        // Two-way tabulation (existing logic)
        _COLVAL = st_matrix("_COLVAL")
        
        rowsum = _FREQ * J(cols(_FREQ),1,1)
        colsum = J(1,rows(_FREQ),1) * _FREQ
        
        _COLPROP = _FREQ :/ (J(rows(_FREQ),1,1) * colsum)
        _ROWPROP = _FREQ :/ (rowsum * J(1,cols(_FREQ),1))
        _CELLPROP = _FREQ / sum(_FREQ)
        
        _FULLMAT = (_FREQ, _COLPROP, _ROWPROP, _CELLPROP)
        st_matrix("_FULLMAT", _FULLMAT)
        st_local("colval", invtokens(strofreal(_COLVAL)))
    }
}
end

clear frames
sysuse nlsw88, clear
_xtab, var(married) rowby(south) colby(race)
