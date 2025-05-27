local proglist dtfreq _argcheck _xtab _xtab_core _xtab_core _binreshape _labelvars _toexcel
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

    // Validate arguments and get returned parameters
    _argcheck `varlist' `if' `in' [`weight'`exp'], df(`df') by(`by') cross(`cross') `binary' format(`format') `miss' using(`using') exopt(`exopt')
    
    // * Set defaults
    if "`df'" == "" local df "_df"
    if "`stats'" == "" local stats "col"
    if "`type'" == "" local type "prop"
    local source_frame = c(frame)
    capture frame drop `df'
    frame create `df'
    tempname temp_frame
    frame create `temp_frame'

    // * weight and marker
    tempvar touse
    if "`miss'" == "nomiss" {
        marksample touse, strok
    }
    else {
        marksample touse, strok novarlist
    }
    local ifcmd "if `touse'"
    if "`weight'" != "" {
        local wtexp `"[`weight'`exp']"'
    }

    // tabulation
    _xtab `varlist', ifcmd(`ifcmd') wtexp(`wtexp') df(`df') by(`by') cross(`cross') binary(`binary') source_frame(`source_frame') temp_frame(`temp_frame')

    // give labels
    _labelvars, df(`df') by(`by') cross(`cross') source_frame(`source_frame') binary(`binary')

    // format vars
    frame `df': quietly ds *, has(type numeric)
    if "`format'" == "" {
        frame `df': _formatvars `r(varlist)'
    }
    else format `r(varlist)' `format' 

    // export to excel
    if "`using'" != "" {
        local inputfile = subinstr(`"`using'"', `"""', "", .)
        if ustrregexm("`inputfile'", "^(.*[/\\])?([^/\\]+?)(\.[^./\\]+)?$") {
            local fullpath = ustrregexs(1)
            local filename = ustrregexs(2)
            local extension = ustrregexs(3)
            local fullname = "`fullpath'`filename'`extension'"
        }
        _toexcel, fullname(`fullname') exopt(`exopt')
    }

end

// execute xtab
program define _xtab
    syntax varlist(min=1 numeric) [, df(name) by(name) cross(name) binary(name) source_frame(name) temp_frame(name) ifcmd(string) wtexp(string)]

    foreach var of local varlist {

        // Get variable label from main data
        local `var'_varlab: variable label `var'
        if "`varlab'" == "" local varlab "`var'"
        
        // If by specified, process each level separately  
        if "`by'" != "" {
            frame `source_frame': quietly levelsof `by' `ifcmd', local(by_levels)
            
            foreach level in `by_levels' {
                // Get by label from main frame
                frame `source_frame': local by_label: label (`by') `level'
                if "`by_label'" == "" local by_label "`level'"
                
                // Run analysis for this level
                frame `temp_frame' {
                    _xtab_core, var(`var') by(`by') cross(`cross') ///
                        varlab(`varlab') stratum_label(`by_label') ///
                        source_frame(`source_frame') binary(`binary') by_condition("& `by' == `level'") ///
                        ifcmd(`ifcmd') wtexp(`wtexp')
                    tempfile _result
                    quietly save `_result'
                }
                frame `df': quietly append using `_result'
            }
            
            // Add totals (all data)
            frame `temp_frame' {
                _xtab_core, var(`var') cross(`cross') varlab(`varlab') ///
                    stratum_label("Total") binary(`binary') source_frame(`source_frame') ///
                    ifcmd(`ifcmd') wtexp(`wtexp') by(`by')
                tempfile _result
                quietly save `_result'
            }
            frame `df': quietly append using `_result'
            
        }
        else {
            // No by - just run once
            frame `temp_frame' {
                _xtab_core, var(`var') cross(`cross') varlab(`varlab') ///
                    stratum_label("Total") binary(`binary') source_frame(`source_frame') ///
                        ifcmd(`ifcmd') wtexp(`wtexp')
            }
            frame copy `temp_frame' `df', replace
        }

    }

end

// * tabulate, calculate matrices, and reshape
program define _xtab_core
    // use name instead of varname
    syntax, var(name) varlab(string) stratum_label(string) source_frame(name) ///
        [by(name) cross(name) binary(name) by_condition(string) ifcmd(string) wtexp(string)]

    frame `source_frame': quietly levelsof `var' `ifcmd' `by_condition', local(vallabels)
    // Create tabulation with if condition
    if "`cross'" != "" local tabcmd "quietly tabulate `var' `cross' `wtexp' `ifcmd' `by_condition', matcell(_FREQ) matrow(_ROWVAL) matcol(_COLVAL)" // Two-way tabulation
    else local tabcmd "quietly tabulate `var' `wtexp' `ifcmd' `by_condition', matcell(_FREQ) matrow(_ROWVAL)" // One-way tabulation 

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

// * export to excel
program define _toexcel

    syntax, [fullname(string) exopt(string)]

    if "`fullname'" != "" {
        // Set export options
        if `"`exopt'"' == "" {
            local exportcmd `"`fullname', sheet("dtfreq_output", replace) firstrow(varlabels)"'
        }
        else {
            local exportcmd `"`fullname', `exopt'"'
        }
        
        // Perform export with error handling
        export excel using `exportcmd'
    }

end

* Program to automatically format numeric variables based on data characteristics
capture program drop _formatvars
program define _formatvars
    syntax varlist, [report]
    foreach var of local varlist {
        // skip string vars
        local vartype: type `var'
        if substr("`vartype'",1,3) == "str" continue

        * Check if variable has date-time format and skip if so
        local current_fmt : format `var'
        if regexm("`current_fmt'", "^%t[cCdwmqhy].*") | regexm("`current_fmt'", "^%d.*") {
            if "`report'" != "" display "Variable `var': Skipping date-time format (`current_fmt')"
            continue
        }
        
        * Get summary statistics
        quietly summarize `var', meanonly
        local max_val = r(max)
        local min_val = r(min)
        
        * Check if variable has value labels
        local vallbl : value label `var'
        local left_just = ("`vallbl'" != "")
        
        * Check if variable has decimal parts
        capture assert `var' == round(`var') if !missing(`var')
        local has_decimals = (_rc == 9)
        
        * Determine format based on rules
        local format_str ""
        
        * Rule 2: Proportions (0 to 1 range) - 3 decimal places
        if `max_val' <= 1 & `min_val' >= 0 {
            local width = 5 + 2  // "0.123" = 5 characters + 2 buffer
            if `left_just' {
                local format_str "%-`width'.3f"
            }
            else {
                local format_str "%`width'.3f"
            }
            if "`report'" != "" display "Variable `var': Detected as proportion, using format `format_str'"
        }
        
        * Rule 1 & 3: Large numbers (>=1000)
        else if `max_val' >= 1000 & !missing(`max_val') {
            * Calculate width needed for largest number
            local max_digits = floor(log10(`max_val')) + 1
            local commas = floor((`max_digits' - 1) / 3)
            
            if `has_decimals' {
                * Rule 1 + 3: Large numbers with decimals (1 decimal place + comma)
                local width = `max_digits' + `commas' + 2 + 2  // +2 for ".X", +2 buffer
                if `left_just' {
                    local format_str "%-`width'.1fc"
                }
                else {
                    local format_str "%`width'.1fc"
                }
                if "`report'" != "" display "Variable `var': Large number with decimals, using format `format_str'"
            }
            else {
                * Rule 1: Large integers (no decimal places + comma)
                local width = `max_digits' + `commas' + 2  // +2 buffer
                if `left_just' {
                    local format_str "%-`width'.0fc"
                }
                else {
                    local format_str "%`width'.0fc"
                }
                if "`report'" != "" display "Variable `var': Large integer, using format `format_str'"
            }
        }
        
        * Smaller numbers (<1000)
        else {
            local max_digits = max(1, floor(log10(max(abs(`max_val'), abs(`min_val')))) + 1)
            
            if `has_decimals' {
                * Small numbers with decimals (1 decimal place, no comma)
                local width = `max_digits' + 2 + 2  // +2 for ".X", +2 buffer
                if `left_just' {
                    local format_str "%-`width'.1f"
                }
                else {
                    local format_str "%`width'.1f"
                }
                if "`report'" != "" display "Variable `var': Small number with decimals, using format `format_str'"
            }
            else {
                * Small integers (no decimal places, no comma)
                local width = `max_digits' + 2  // +2 buffer
                if `left_just' {
                    local format_str "%-`width'.0f"
                }
                else {
                    local format_str "%`width'.0f"
                }
                if "`report'" != "" display "Variable `var': Small integer, using format `format_str'"
            }
        }
        
        * Apply the format
        format `var' `format_str'
    }
end

// * argument checking and validation
program define _argcheck, rclass
    syntax varlist(min=1 numeric) [if] [in] [aweight fweight iweight pweight] ///
           [, df(string) by(varname numeric) cross(varname numeric) BINary ///
           FOrmat(string) noMISS using(string) exopt(string) stats(string) type(string) ///
           fullpath(string) filename(string) extension(string)]


    // * Validate options
    // Validate stats option
    local valid_stats "row col cell all"
    local stats_clean = strtrim(strlower("`stats'"))
    foreach stat in `stats_clean' {
        if !`: list stat in valid_stats' {
            display as error "Invalid stats option: `stat'. Valid options are: `valid_stats'"
            exit 198
        }
    }
    
    // Validate type option  
    local valid_types "prop pct freq all"
    local type_clean = strtrim(strlower("`type'"))
    foreach t in `type_clean' {
        if !`: list t in valid_types' {
            display as error "Invalid type option: `t'. Valid options are: `valid_types'"
            exit 198
        }
    }

    // * Cross-option validation
    // Ensure exopt is only present if using is present
    if "`exopt'" != "" & "`using'" == "" {
        display as error "exopt() option is only allowed when using() is also specified."
        exit 198
    }

    // Issue warning if binary and cross are both used
    if "`binary'" != "" & "`cross'" != "" {
        display as text "Note: binary option with cross() may produce complex output structure."
    }

    // Ensure by and cross are not the same if both are specified
    if "`by'" != "" & "`cross'" != "" & "`by'" == "`cross'" {
        display as error "by() variable and cross() variable cannot be the same."
        exit 198
    }

    // * Binary option validation (enhanced with label consistency)
    if "`binary'" != "" {
        // Single efficient check for binary variables
        tempvar touse
        if "`miss'" == "nomiss" {
            marksample touse, strok
        }
        else {
            marksample touse, strok novarlist
        }
        
        // Initialize issue tracking
        local value_issues ""
        local label_issues ""
        local vars_with_value_issues ""
        local vars_with_label_issues ""
        
        // Check each variable for binary requirements
        foreach var of local varlist {
            
            // Check values - must have exactly 2 distinct non-missing values
            quietly levelsof `var' if `touse' & !missing(`var'), local(var_values)
            local n_values : word count `var_values'
            if `n_values' != 2 {
                local value_issues "`value_issues' `var'(`n_values' values: `var_values')"
                local vars_with_value_issues "`vars_with_value_issues' `var'"
            }
            
            // Check labels - must have exactly 2 distinct labels
            quietly levelsof `var' if `touse' & !missing(`var'), local(var_values_for_labels)
            local var_labels ""
            foreach val in `var_values_for_labels' {
                local val_label : label (`var') `val'
                if "`val_label'" == "" local val_label "`val'"  // Use value if no label
                local var_labels "`var_labels' `val_label'"
            }
            local var_labels : list uniq var_labels
            local n_labels : word count `var_labels'
            if `n_labels' != 2 {
                local label_issues "`label_issues' `var'(`n_labels' labels: `var_labels')"
                local vars_with_label_issues "`vars_with_label_issues' `var'"
            }
        }
        
        // Report value issues with informative messages
        if "`vars_with_value_issues'" != "" {
            display as error "binary option requires exactly 2 distinct non-missing values per variable."
            display as error "Variables with incorrect number of values:"
            foreach issue in `value_issues' {
                display as error "  `issue'"
            }
            exit 198
        }
        
        // Report label issues with informative messages  
        if "`vars_with_label_issues'" != "" {
            display as error "binary option requires exactly 2 distinct labels per variable."
            display as error "Variables with incorrect number of labels:"
            foreach issue in `label_issues' {
                display as error "  `issue'"
            }
            exit 198
        }
        
        // Check for consistent binary values across all variables (optional warning)
        local all_values ""
        foreach var of local varlist {
            quietly levelsof `var' if `touse' & !missing(`var'), local(var_vals)
            local all_values "`all_values' `var_vals'"
        }
        local unique_values : list sort all_values
        local unique_values : list uniq unique_values
        if `:word count `unique_values'' > 2 {
            display as error "Note: Variables use different binary values across the varlist: `unique_values'"
            display as error "      This may affect interpretation of results."
            error 198
        }
        
        // Check for consistent binary labels across all variables (optional warning)
        local all_labels ""
        foreach var of local varlist {
            quietly levelsof `var' if `touse' & !missing(`var'), local(var_values_for_labels)
            foreach val in `var_values_for_labels' {
                local val_label : label (`var') `val'
                if "`val_label'" == "" local val_label "`val'"
                local all_labels "`all_labels' `val_label'"
            }
        }
        local all_labels : list sort all_labels
        local all_labels : list uniq all_labels
        if `:word count `all_labels'' > 2 {
            display as error "Note: Variables use different binary labels across the varlist: `all_labels'"
            display as error "      This may affect interpretation of results."
            error 198
        }
    }
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

clear frames
sysuse nlsw88, clear
desc married
dtfreq married, binary by(south) cross(race)
frame _df: desc