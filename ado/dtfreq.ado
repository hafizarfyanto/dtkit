local proglist dtfreq _argcheck _xtab _xtab_core _xtab_core _binreshape _labelvars _toexcel _formatvars
foreach prog in `proglist' {
    capture program drop `prog'
}
capture mata: mata drop _xtab_core_calc()

program define dtfreq
    *! Version 2.0.0 Hafiz 27May2025
    * Module to produce frequency dataset
    version 16
    syntax varlist(min=1 numeric) [if] [in] [aweight fweight iweight pweight] [using/] [, df(string) by(varname numeric) cross(varname numeric) BINary FOrmat(string) noMISS Exopt(string) STATs(namelist max=3) TYpe(namelist max=2)]

    // Validate arguments and get returned parameters
    _argcheck `varlist' `if' `in' [`weight'`exp'], df(`df') by(`by') cross(`cross') `binary' format(`format') `miss' using(`using') exopt(`exopt') stats("`stats'") type("`type'")
    
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
    else frame `df': format `r(varlist)' `format' 

    // drop variables
    local core_vars "`by' varname varlab"
    if "`binary'" == "" local core_vars "`core_vars' vallab"
    if "`cross'" != "" frame `df': order `core_vars' *prop* *pct* freq* rowfreq* total* 
    else frame `df': order `core_vars' *prop* *pct* freq* total* 
    if strpos("`stats'", "row") == 0 frame `df': capture drop row*
    if strpos("`stats'", "col") == 0 frame `df': capture drop col*
    if strpos("`stats'", "cell") == 0 frame `df': capture drop cell*
    if strpos("`type'", "prop") == 0 frame `df': capture drop *prop*
    if strpos("`type'", "pct") == 0 frame `df': capture drop *pct*


    // export to excel
    if "`using'" != "" {
        local inputfile = subinstr(`"`using'"', `"""', "", .)
        if ustrregexm("`inputfile'", "^(.*[/\\])?([^/\\]+?)(\.[^./\\]+)?$") {
            local fullpath = ustrregexs(1)
            local filename = ustrregexs(2)
            local extension = ustrregexs(3)
            local fullname = "`fullpath'`filename'`extension'"
        }
        frame `df': _toexcel, fullname(`fullname') exopt(`exopt')
    }

end

// * Loops through variables and groups to make tables
program define _xtab
    syntax varlist(min=1 numeric) [, df(name) by(name) cross(name) binary(name) source_frame(name) temp_frame(name) ifcmd(string) wtexp(string)]

    foreach var of local varlist {

        // Get variable label from main data
        local `var'_varlab: variable label `var'
        if "``var'_varlab'" == "" local `var'_varlab "`var'"
        
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
                        varlab(``var'_varlab') stratum_label(`by_label') ///
                        source_frame(`source_frame') binary(`binary') by_condition("& `by' == `level'") ///
                        ifcmd(`ifcmd') wtexp(`wtexp')
                    tempfile _result
                    quietly save `_result'
                }
                frame `df': quietly append using `_result'
            }
            
            // Add totals (all data)
            frame `temp_frame' {
                _xtab_core, var(`var') cross(`cross') varlab(``var'_varlab') ///
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
                _xtab_core, var(`var') cross(`cross') varlab(``var'_varlab') ///
                    stratum_label("Total") binary(`binary') source_frame(`source_frame') ///
                    ifcmd(`ifcmd') wtexp(`wtexp')
                tempfile _result
                quietly save `_result'
            }
            frame `df': quietly append using `_result'
        }

    }

end

// * Does the actual counting and math for each table
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

    // calculate percentage
    quietly ds *prop*, has(type numeric)
    foreach var in `r(varlist)' {
        local pctname: subinstr local var "prop" "pct"
        quietly generate `pctname' = `var' * 100
    }
    
    // Calculate totals
    if "`cross'" != "" {
        // Two-way - use actual cross variable values from the column values
        // The colval should contain the cross variable levels from mata
        foreach val in `colval' {
            capture egen total`val' = total(freq`val')
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
    if "`cross'" != "" quietly ds freq* col* row* cell*, has(type numeric)
    else quietly ds freq prop, has(type numeric)

    local reshape_vars `r(varlist)'

    // Store variable labels before reshape
    foreach var in `reshape_vars' {
        local `var'_label: variable label `var'
    }

    if "`cross'" == "" {
        quietly reshape wide freq prop pct, i(`by' varname varlab) j(vallab) string
    }
    if "`cross'" != "" {
        quietly ds *, has(type numeric)
        foreach numvar in `r(varlist)' {
            local `numvar'_varlab: variable label `numvar'
        }
        quietly reshape wide freq* col* row* cell*, i(`by' varname varlab) j(vallab) string
    }

end

// * Adds nice names to all output columns
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
        frame `source_frame': quietly levelsof `cross', local(cross_values)
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
        frame `df': quietly ds freq* col* row* cell*
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
            local `reshapevars'_varlab: subinstr local `reshapevars'_varlab "colpct" "Column percentage (%) | ", word
            local `reshapevars'_varlab: subinstr local `reshapevars'_varlab "rowpct" "Row percentage (%) | ", word
            local `reshapevars'_varlab: subinstr local `reshapevars'_varlab "cellpct" "Cell percentage (%) | ", word
            local `reshapevars'_varlab: subinstr local `reshapevars'_varlab "rowfreq" "Row frequency"
            frame `df': label variable `reshapevars' "``reshapevars'_varlab'"
        }
        frame `df': label variable total_all "Overall total count"
    }
    frame `df': order total*, last
end

// * Saves the final table to Excel file
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

// * Makes numbers look good with commas and decimals
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

// * Checks if user inputs are valid before starting
program define _argcheck, rclass
    syntax varlist(min=1 numeric) [if] [in] [aweight fweight iweight pweight] ///
           [, df(string) by(varname numeric) cross(varname numeric) BINary ///
           FOrmat(string) noMISS using(string) exopt(string) stats(namelist) type(namelist) ///
           fullpath(string) filename(string) extension(string)]

    // * Validate stats and type options
    if "`stats'" != "" {
        local dupstats: list dups stats
        if "`dupstats'" != "" {
            display as error "Option stats() must be unique. Duplicates found: " as result "`dupstats'" as error " in " as result "stats(`stats')" as error "."
            exit 198
        }
        if !regexm("`stats'", "^\s*(row|col|cell)([ ]+(row|col|cell)){0,2}\s*$") {
            display as error "Option stats() must be up to three of row, col, or cell. Entered stats: " as result "`stats'"
            exit 198
        }
    }
    if "`type'" != "" {
        local duptype: list dups type
        if "`duptype'" != "" {
            display as error "Option type() must be unique. Duplicates found: " as result "`duptype'" as error " in " as result "type(`type')" as error "."
            exit 198
        }
        if !regexm("`type'",  "^\s*(prop|pct)([ ]+(prop|pct)){0,1}\s*$") {
            display as error "Option type() must be up to two of prop or pct. Entered type: " as result "`type'"
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

    // ensure stats can only be used with cross
    if "`stats'" != "" & "`cross'" == "" {
        display as error "stats() option is only allowed when cross() is also specified."
        exit 198
    }


    // * Binary option validation (domain-specific)
    if "`binary'" != "" {
        tempvar touse
        if "`miss'" == "nomiss" {
            marksample touse, strok
        }
        else {
            marksample touse, strok novarlist
        }
        
        // Step 1: Check each variable has exactly 2 values and collect all value-label pairs
        local first_var 1
        local standard_values ""
        local problem_vars ""
        
        foreach var of local varlist {
            quietly levelsof `var' if `touse' & !missing(`var'), local(var_values)
            local n_values : word count `var_values'
            
            // Check if variable has exactly 2 values
            if `n_values' != 2 {
                local var_display "`var':"
                foreach val in `var_values' {
                    local val_label : label (`var') `val'
                    if "`val_label'" == "" local val_label "`val'"
                    local var_display `"`var_display' `val' "`val_label'""'
                }
                local problem_vars "`problem_vars' `var'"
                continue
            }
            
            // For first valid variable, establish the standard
            if `first_var' {
                local standard_values "`var_values'"
                // Store standard labels for each value
                foreach val in `standard_values' {
                    local standard_label_`val' : label (`var') `val'
                    if "`standard_label_`val''" == "" local standard_label_`val' "`val'"
                }
                local first_var 0
            }
            else {
                // Check if this variable matches the standard values
                if "`var_values'" != "`standard_values'" {
                    local problem_vars "`problem_vars' `var'"
                    continue
                }
                
                // Check if labels match the standard
                local labels_match 1
                foreach val in `var_values' {
                    local this_label : label (`var') `val'
                    if "`this_label'" == "" local this_label "`val'"
                    if "`this_label'" != "`standard_label_`val''" {
                        local labels_match 0
                        break
                    }
                }
                
                if !`labels_match' {
                    local problem_vars "`problem_vars' `var'"
                }
            }
        }
        // get base var value set
        gettoken basevarname: varlist
        quietly levelsof `basevarname' if `touse' & !missing(`basevarname'), local(var_values)
        local var_display "`basevarname':"
        foreach val in `var_values' {
            local val_label : label (`basevarname') `val'
            if "`val_label'" == "" local val_label "`val'"
            local var_display `"`var_display' `val' "`val_label'""'
        }

        // Report any problematic variables
        if "`problem_vars'" != "" {
            display as error "Some variables have inconsistent values/labels compared with:" ///
            _newline as result `"`var_display'"' as error _newline "Problematic variable(s):"
            foreach var of local problem_vars {
                quietly levelsof `var' if `touse' & !missing(`var'), local(var_values)
                local var_display "`var':"
                foreach val in `var_values' {
                    local val_label : label (`var') `val'
                    if "`val_label'" == "" local val_label "`val'"
                    local var_display `"`var_display' `val' "`val_label'""'
                }
                display as result `"`var_display'"'
            }
            exit 198
        }
    }

end

// * Calculates percentages and proportions in Mata
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

// clear frames
// sysuse nlsw88, clear
// desc married
// label values smsa marlbl
// dtfreq smsa married
// frame _df: desc
// cwf _df
// br
// // exit, clear
// cd "D:\OneDrive\MyWork\personal\stata\repo\dtkit"
// do test/dtfreq_test.do