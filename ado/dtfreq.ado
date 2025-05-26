local proglist _xtab _xtab_core reshape_binary give_varlab
foreach prog in `proglist' {
    capture program drop `prog'
}
capture mata: mata drop _xtab_calc()

// subroutine
program define _xtab
    version 16
    syntax, var(varname) [colby(varname) rowby(varname)]
    
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
                    source_frame(`source_frame') if_condition("if `rowby' == `level'")
                tempfile _result
                quietly save `_result'
            }
            frame _df: quietly append using `_result'
        }
        
        // Add totals (all data)
        frame `_temp' {
            _xtab_core, var(`var') colby(`colby') varlab(`varlab') ///
                stratum_label("Total") source_frame(`source_frame')
            tempfile _result
            quietly save `_result'
        }
        frame _df: quietly append using `_result'
        
    }
    else {
        // No rowby - just run once
        frame `_temp' {
            _xtab_core, var(`var') colby(`colby') varlab(`varlab') ///
                stratum_label("Total") source_frame(`source_frame')
        }
        frame copy `_temp' _df, replace
    }
end

// * tabulate, calculate matrices, and reshape
program define _xtab_core
    syntax, var(varname) varlab(string) stratum_label(string) source_frame(name) ///
        [rowby(varname) colby(varname) if_condition(string)]

    frame `source_frame': quietly levelsof `var' `if_condition', local(vallabels)
    
    // Create tabulation with if condition
    if "`colby'" != "" local tabcmd "quietly tabulate `var' `colby' `if_condition', matcell(_FREQ) matcol(_COLVAL)" // Two-way tabulation
    else local tabcmd "quietly tabulate `var' `if_condition', matcell(_FREQ)" // One-way tabulation 
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
    // reshape_binary, rowby(`rowby') colby(`colby')
end

// * calculate row, column, and cell proportions
mata:
void _xtab_calc()
{
    _FREQ = st_matrix("_FREQ")
    
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
program define reshape_binary
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
        quietly reshape wide freq prop, i(rowval varname varlab) j(vallab) string
    }
    if "`colby'" != "" {
        quietly ds *, has(type numeric)
        foreach numvar in `r(varlist)' {
            local `numvar'_varlab: variable label `numvar'
        }
        quietly reshape wide freq* col* rowprop* rowfreq cell*, i(rowval varname varlab) j(vallab) string
    }

end

// * attach variable labels
program define give_varlab

    syntax, df(name) rowby(name) colby(name) source_frame(name)
    // standard vars
    frame _df: label variable varname "Variable"
    frame _df: label variable varlab "Variable label"
    frame _df: capture label variable vallab "Value"

    // rowby specified
    // if "`rowby'" != "" {
    //     frame `source_frame': local rowby_varlab: variable label `rowby' 
    //     frame `source_frame': label variable `rowby' "`rowby_varlab'"
    // }
    // labeling reshaped variables
    foreach val in `vallab_value' {
        // local val = strlower("`val'")
        if "`colby'" != "" {
            quietly ds freq*`val' col*`val' rowprop*`val' rowfreq_`val' cell*`val'
            foreach reshapevar in `r(varlist)' {
                local reshapevar `reshapevar'
                local base_var: subinstr local reshapevar "_`val'" "", all
                local suffix: subinstr local val "_" "", word
                local original_label "``base_var'_label'"
                if "`original_label'" != "" label variable `reshapevar' "[`val'] `original_label'"
                else label variable `reshapevar' "[`suffix'] `base_var'"
            }
        }
        else if "`colby'" == "" {
            quietly ds prop*`val' 
            for var `r(varlist)': label variable X "[`val'] Proportion"
            quietly ds freq*`val'
            for var `r(varlist)': label variable X "[`val'] Frequency"
        }
    }

end

clear frames
sysuse nlsw88, clear
_xtab, var(married) rowby(south) //colby(race)
frame _df: desc