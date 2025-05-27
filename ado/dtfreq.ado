local proglist _xtab _xtab_core _binreshape _labelvars
foreach prog in `proglist' {
    capture program drop `prog'
}
capture mata: mata drop _xtab_calc()

// subroutine
program define _xtab
    version 16
    syntax, var(varname) [colby(varname) rowby(varname) binary]
    
    // Store original frame name and create working frames
    local source_frame = c(frame)
    capture frame drop _df
    frame create _df
    tempname _temp
    frame create `_temp'
    
    // Get variable label from main data
    local `var'_varlab: variable label `var'
    if "`varlab'" == "" local varlab "`var'"
    
    // If rowby specified, process each level separately  
    if "`rowby'" != "" {
        frame `source_frame': quietly levelsof `rowby', local(rowby_levels)
        
        foreach level in `rowby_levels' {
            // Get rowby label from main frame
            frame `source_frame': local rowby_label: label (`rowby') `level'
            if "`rowby_label'" == "" local rowby_label "`level'"
            
            // Run analysis for this level
            frame `_temp' {
                _xtab_core, var(`var') rowby(`rowby') colby(`colby') ///
                    varlab(`varlab') stratum_label(`rowby_label') ///
                    source_frame(`source_frame') binary(`binary') if_condition("if `rowby' == `level'")
                tempfile _result
                quietly save `_result'
            }
            frame _df: quietly append using `_result'
        }
        
        // Add totals (all data)
        frame `_temp' {
            _xtab_core, var(`var') colby(`colby') varlab(`varlab') ///
                stratum_label("Total") binary(`binary') source_frame(`source_frame')
            tempfile _result
            quietly save `_result'
        }
        frame _df: quietly append using `_result'
        
    }
    else {
        // No rowby - just run once
        frame `_temp' {
            _xtab_core, var(`var') colby(`colby') varlab(`varlab') ///
                stratum_label("Total") binary(`binary') source_frame(`source_frame')
        }
        frame copy `_temp' _df, replace
    }
    
    // give labels
    _labelvars, df(_df) rowby(`rowby') colby(`colby') source_frame(`source_frame') binary(`binary')
end

// * tabulate, calculate matrices, and reshape
program define _xtab_core
    // use name instead of varname
    syntax, var(name) varlab(string) stratum_label(string) source_frame(name) ///
        [rowby(name) colby(name) binary(name) if_condition(string)]
    
    frame `source_frame': quietly levelsof `var' `if_condition', local(vallabels)
    // Create tabulation with if condition
    if "`colby'" != "" local tabcmd "quietly tabulate `var' `colby' `if_condition', matcell(_FREQ) matrow(_ROWVAL) matcol(_COLVAL)" // Two-way tabulation
    else local tabcmd "quietly tabulate `var' `if_condition', matcell(_FREQ) matrow(_ROWVAL)" // One-way tabulation 
    frame `source_frame': `tabcmd'
    
    // Call mata function
    mata: _xtab_calc()

    // Build variable names - match matrix structure
    local varnamelist "numlab"
    
    if "`colby'" != "" {
        foreach prefix in freq col row cell {
            foreach col in `colval' {
                local varnamelist `varnamelist' `prefix'prop`col'
            }
        }
        local varnamelist = subinstr("`varnamelist'", "freqprop", "freq", .)
    }
    else local varnamelist "`varnamelist' freq prop" // One-way: simpler structure

    // Add row values and set column names
    matrix _FULLMAT = (_ROWVAL, _FULLMAT)
    matrix colnames _FULLMAT = `varnamelist'
    
    // Create results dataset
    clear
    quietly {
        svmat _FULLMAT, names(col)
        
        generate varname = "`var'", before(numlab)
        generate varlab = "`varlab'", before(numlab)
        capture generate `rowby' = "`stratum_label'", before(numlab)
        generate vallab = "", before(numlab)
    }

    // Fill value labels using main frame
    foreach val in `vallabels' {
        frame `source_frame': local vallabval: label (`var') `val'
        if "`vallabval'" == "" local vallabval "`val'"
        quietly replace vallab = "`vallabval'" if numlab == `val'
    }
    
    // Calculate totals
    if "`colby'" != "" {
        // Two-way
        local counter 1
        foreach freq of varlist freq* {
            egen total`counter' = total(`freq')
            local ++counter
        }
        egen rowfreq = rowtotal(freq*), missing
        egen total_all = total(rowfreq)
    }
    else {
        // One-way
        egen total = total(freq)
    }
    drop numlab
    if "`binary'" != "" _binreshape, rowby(`rowby') colby(`colby')
end

// * calculate row, column, and cell proportions
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

// * reshape binary data (formerly yesno)
program define _binreshape
    syntax, [rowby(name) colby(name)]
    
    quietly replace vallab = strlower(subinstr(vallab, " ", "_", .))
    quietly levelsof vallab, local(vallab_value)
    quietly replace vallab = "_" + strlower(vallab)

    // Determine which variables to reshape based on colby
    if "`colby'" != "" quietly ds freq* col* rowprop* rowfreq cell*, has(type numeric)
    else quietly ds freq prop, has(type numeric)

    local reshape_vars `r(varlist)'

    // Store variable labels before reshape
    foreach var in `reshape_vars' {
        local `var'_label: variable label `var'
    }

    if "`colby'" == "" {
        quietly reshape wide freq prop, i(`rowby' varname varlab) j(vallab) string
    }
    if "`colby'" != "" {
        quietly ds *, has(type numeric)
        foreach numvar in `r(varlist)' {
            local `numvar'_varlab: variable label `numvar'
        }
        quietly reshape wide freq* col* rowprop* rowfreq cell*, i(`rowby' varname varlab) j(vallab) string
    }

end

// * attach variable labels
program define _labelvars
    syntax, [df(name) rowby(name) colby(name) source_frame(name) binary(name)]
    // standard vars/vars in one-way
    frame `df' {
        label variable varname "Variable"
        label variable varlab "Variable label"
        capture label variable vallab "Value"
        capture label variable freq "Frequency"
        capture label variable prop "Proportion"
        capture label variable total "Total"
    }

    // rowby specified
    if "`rowby'" != "" {
        frame `source_frame': local rowby_varlab: variable label `rowby' 
        frame `df': label variable `rowby' "`rowby_varlab'"
    }
    // colby specified
    if "`binary'" == "" & "`colby'" != "" {
        frame `source_frame': levelsof `colby', local(colby_values)
        foreach val in `colby_values' {
            frame `source_frame': local colby_lbl_`val': label (`colby') `val'            
            frame `df': label variable freq`val' "Frequency `colby_lbl_`val''"
            frame `df': label variable total`val' "Total `colby_lbl_`val''"
            frame `df': label variable rowprop`val' "Row proportion `colby_lbl_`val''"
            frame `df': label variable colprop`val' "Column proportion `colby_lbl_`val''"
            frame `df': label variable cellprop`val' "Cell proportion `colby_lbl_`val''"
        }
        frame `df': label variable rowfreq "Overall row frequency"
        frame `df': label variable total_all "Overall total count"
    }
    else if "`binary'" != "" & "`colby'" == "" {
        frame `df': quietly ds freq* prop*
        foreach reshapevars in `r(varlist)' {
            frame `df': local `reshapevars'_varlab: variable label `reshapevars'
            local `reshapevars'_varlab: subinstr local `reshapevars'_varlab "_" "["
            local `reshapevars'_varlab: subinstr local `reshapevars'_varlab " " "] "
            local `reshapevars'_varlab: subinstr local `reshapevars'_varlab "freq" "Frequency"
            local `reshapevars'_varlab: subinstr local `reshapevars'_varlab "prop" "Proportion"
            frame `df': label variable `reshapevars' "``reshapevars'_varlab'"
        }
    }
    else if "`binary'" != "" & "`colby'" != "" {
        // get value and variable label from colby
        frame `source_frame': quietly levelsof `colby', local(colby_values)
        frame `df': quietly ds freq* col* rowprop* rowfreq* cell*
        foreach reshapevars in `r(varlist)' {
            frame `df': local `reshapevars'_varlab: variable label `reshapevars'
            local `reshapevars'_varlab: subinstr local `reshapevars'_varlab "_" "["
            local `reshapevars'_varlab: subinstr local `reshapevars'_varlab " " "] "
            local `reshapevars'_varlab: subinstr local `reshapevars'_varlab "_" " ", all
            foreach val in `colby_values' {
                frame `source_frame': local colby_lbl_`val': label (`colby') `val'
                local colby_lbl_`val' = strlower("`colby_lbl_`val''")
                local `reshapevars'_varlab: subinstr local `reshapevars'_varlab "`val'" " `colby_lbl_`val''"
                frame `df': label variable total`val' "Total `colby_lbl_`val''"
            }
            local `reshapevars'_varlab: subinstr local `reshapevars'_varlab "freq" "Frequency | ", word
            local `reshapevars'_varlab: subinstr local `reshapevars'_varlab "colprop" "Column proportion | ", word
            local `reshapevars'_varlab: subinstr local `reshapevars'_varlab "rowprop" "Row proportion | ", word
            local `reshapevars'_varlab: subinstr local `reshapevars'_varlab "cellprop" "Cell proportion | ", word
            local `reshapevars'_varlab: subinstr local `reshapevars'_varlab "rowfreq" "Row frequency"
            frame `df': label variable `reshapevars' "``reshapevars'_varlab'"
        }
        frame `df': label variable total_all "Overall total count"
    }
end

clear frames
sysuse nlsw88, clear
desc married
_xtab, var(married) binary //rowby(south) //colby(race)
frame _df: desc