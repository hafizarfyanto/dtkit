local proglist dtfreq _xtab _xtab_core _xtab_core _binreshape _labelvars
foreach prog in `proglist' {
    capture program drop `prog'
}
capture mata: mata drop _xtab_core_calc()

// subroutine
program define dtfreq
    *! Version 2.0.0 Hafiz 27May2025
    * Module to produce frequency dataset
    version 16
    syntax varlist(min=1 numeric) [if] [in] [aweight fweight iweight pweight] [using/] [, df(string) by(varname numeric) cross(varname numeric) BINary FOrmat(string) noMISS Exopt(string)]

    // Set default frame name
    if "`df'" == "" local df "_df"
    if "`stats'" == "" local stats "col"
    if "`type'" == "" local type "prop"

    // Store original frame name and create working frames
    local source_frame = c(frame)
    capture frame drop `df'
    frame create `df'
    tempname _temp
    frame create `_temp'

    // tabulation
    _xtab `varlist', df(`df') by(`by') cross(`cross') binary(`binary') source_frame(`source_frame') temp_frame(`_temp')

    // give labels
    _labelvars, df(`df') by(`by') cross(`cross') source_frame(`source_frame') binary(`binary')
end

// execute xtab
program define _xtab
    syntax varlist(min=1 numeric) [, df(string) by(name) cross(name) binary(name) source_frame(name) temp_frame(name)]

    foreach var of local varlist {

        // Get variable label from main data
        local `var'_varlab: variable label `var'
        if "`varlab'" == "" local varlab "`var'"
        
        // If by specified, process each level separately  
        if "`by'" != "" {
            frame `source_frame': quietly levelsof `by', local(by_levels)
            
            foreach level in `by_levels' {
                // Get by label from main frame
                frame `source_frame': local by_label: label (`by') `level'
                if "`by_label'" == "" local by_label "`level'"
                
                // Run analysis for this level
                frame `temp_frame' {
                    _xtab_core, var(`var') by(`by') cross(`cross') ///
                        varlab(`varlab') stratum_label(`by_label') ///
                        source_frame(`source_frame') binary(`binary') if_condition("if `by' == `level'")
                    tempfile _result
                    quietly save `_result'
                }
                frame _df: quietly append using `_result'
            }
            
            // Add totals (all data)
            frame `temp_frame' {
                _xtab_core, var(`var') cross(`cross') varlab(`varlab') ///
                    stratum_label("Total") binary(`binary') source_frame(`source_frame')
                tempfile _result
                quietly save `_result'
            }
            frame _df: quietly append using `_result'
            
        }
        else {
            // No by - just run once
            frame `temp_frame' {
                _xtab_core, var(`var') cross(`cross') varlab(`varlab') ///
                    stratum_label("Total") binary(`binary') source_frame(`source_frame')
            }
            frame copy `temp_frame' _df, replace
        }

    }

end

// * tabulate, calculate matrices, and reshape
program define _xtab_core
    // use name instead of varname
    syntax, var(name) varlab(string) stratum_label(string) source_frame(name) ///
        [by(name) cross(name) binary(name) if_condition(string)]
    
    frame `source_frame': quietly levelsof `var' `if_condition', local(vallabels)
    // Create tabulation with if condition
    if "`cross'" != "" local tabcmd "quietly tabulate `var' `cross' `if_condition', matcell(_FREQ) matrow(_ROWVAL) matcol(_COLVAL)" // Two-way tabulation
    else local tabcmd "quietly tabulate `var' `if_condition', matcell(_FREQ) matrow(_ROWVAL)" // One-way tabulation 
    frame `source_frame': `tabcmd'
    
    // Call mata function
    mata: _xtab_core_calc()

    // Build variable names - match matrix structure
    local varnamelist "numlab"
    
    if "`cross'" != "" {
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
        capture generate `by' = "`stratum_label'", before(numlab)
        generate vallab = "", before(numlab)
    }

    // Fill value labels using main frame
    foreach val in `vallabels' {
        frame `source_frame': local vallabval: label (`var') `val'
        if "`vallabval'" == "" local vallabval "`val'"
        quietly replace vallab = "`vallabval'" if numlab == `val'
    }
    
    // Calculate totals
    if "`cross'" != "" {
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
    if "`binary'" != "" _binreshape, by(`by') cross(`cross')
end

// * calculate row, column, and cell proportions
mata:
void _xtab_core_calc()
{
    _FREQ = st_matrix("_FREQ")
    _ROWVAL = st_matrix("_ROWVAL")
    
    // Check if this is one-way or two-way
    if (st_local("cross") == "") {
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
    syntax, [by(name) cross(name)]
    
    quietly replace vallab = strlower(subinstr(vallab, " ", "_", .))
    quietly levelsof vallab, local(vallab_value)
    quietly replace vallab = "_" + strlower(vallab)

    // Determine which variables to reshape based on cross
    if "`cross'" != "" quietly ds freq* col* rowprop* rowfreq cell*, has(type numeric)
    else quietly ds freq prop, has(type numeric)

    local reshape_vars `r(varlist)'

    // Store variable labels before reshape
    foreach var in `reshape_vars' {
        local `var'_label: variable label `var'
    }

    if "`cross'" == "" {
        quietly reshape wide freq prop, i(`by' varname varlab) j(vallab) string
    }
    if "`cross'" != "" {
        quietly ds *, has(type numeric)
        foreach numvar in `r(varlist)' {
            local `numvar'_varlab: variable label `numvar'
        }
        quietly reshape wide freq* col* rowprop* rowfreq cell*, i(`by' varname varlab) j(vallab) string
    }

end

// * attach variable labels
program define _labelvars
    syntax, [df(name) by(name) cross(name) source_frame(name) binary(name)]
    // standard vars/vars in one-way
    frame `df' {
        label variable varname "Variable"
        label variable varlab "Variable label"
        capture label variable vallab "Value"
        capture label variable freq "Frequency"
        capture label variable prop "Proportion"
        capture label variable total "Total"
    }

    // by specified
    if "`by'" != "" {
        frame `source_frame': local by_varlab: variable label `by' 
        frame `df': label variable `by' "`by_varlab'"
    }
    // cross specified
    if "`binary'" == "" & "`cross'" != "" {
        frame `source_frame': levelsof `cross', local(cross_values)
        foreach val in `cross_values' {
            frame `source_frame': local cross_lbl_`val': label (`cross') `val'            
            frame `df': label variable freq`val' "Frequency `cross_lbl_`val''"
            frame `df': label variable total`val' "Total `cross_lbl_`val''"
            frame `df': label variable rowprop`val' "Row proportion `cross_lbl_`val''"
            frame `df': label variable colprop`val' "Column proportion `cross_lbl_`val''"
            frame `df': label variable cellprop`val' "Cell proportion `cross_lbl_`val''"
        }
        frame `df': label variable rowfreq "Overall row frequency"
        frame `df': label variable total_all "Overall total count"
    }
    else if "`binary'" != "" & "`cross'" == "" {
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
    else if "`binary'" != "" & "`cross'" != "" {
        // get value and variable label from cross
        frame `source_frame': quietly levelsof `cross', local(cross_values)
        frame `df': quietly ds freq* col* rowprop* rowfreq* cell*
        foreach reshapevars in `r(varlist)' {
            frame `df': local `reshapevars'_varlab: variable label `reshapevars'
            local `reshapevars'_varlab: subinstr local `reshapevars'_varlab "_" "["
            local `reshapevars'_varlab: subinstr local `reshapevars'_varlab " " "] "
            local `reshapevars'_varlab: subinstr local `reshapevars'_varlab "_" " ", all
            foreach val in `cross_values' {
                frame `source_frame': local cross_lbl_`val': label (`cross') `val'
                local cross_lbl_`val' = strlower("`cross_lbl_`val''")
                local `reshapevars'_varlab: subinstr local `reshapevars'_varlab "`val'" " `cross_lbl_`val''"
                frame `df': label variable total`val' "Total `cross_lbl_`val''"
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
    frame `df': order total*, last
end

clear frames
sysuse nlsw88, clear
desc married
dtfreq married smsa, binary by(south) cross(race)
frame _df: desc