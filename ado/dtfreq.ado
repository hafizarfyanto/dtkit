capture program drop dtfreq
program define dtfreq
    *! Version 1.1.0 Hafiz 25May2025
    * Module to produce frequency dataset

    version 16
    syntax varlist(min=1 numeric) [if] [in] [aweight fweight iweight pweight] [using/] [, df(string) ROWby(varname numeric) COLby(varname numeric) Yesno FOrmat(string) noMISS FAst Exopt(string) STATs(string) TYpe(string)]

    // * initialization and validation
    // Set default frame name
    if "`df'" == "" local df "_df"

    // Set defaults for stats and type options
    if "`stats'" == "" local stats "col"
    if "`type'" == "" local type "prop"

    // Validate stats option
    local valid_stats "row col cell"
    local stats_clean = strtrim(strlower("`stats'"))
    foreach stat in `stats_clean' {
        if !`: list stat in valid_stats' {
            display as error "Invalid stats option: `stat'. Valid options are: `valid_stats'"
            exit 198
        }
    }
    
    // Validate type option  
    local valid_types "prop pct"
    local type_clean = strtrim(strlower("`type'"))
    foreach t in `type_clean' {
        if !`: list t in valid_types' {
            display as error "Invalid type option: `t'. Valid options are: `valid_types'"
            exit 198
        }
    }

    // Store current frame for cleanup
    quietly pwf
    local currentframe = r(currentframe)
    if "`currentframe'" == "" {
        display as error "Cannot determine current frame"
        exit 198
    }
    
    // Validate all options early to fail fast
    if "`using'" == "" & "`exopt'" != "" {
        display as error "exopt option only allowed with using"
        exit 198
    }
    
    if "`yesno'" != "" & "`colby'" != "" {
        display as text "Note: yesno option with colby may produce complex output structure"
    }
    
    if "`rowby'" != "" & "`colby'" != "" & "`rowby'" == "`colby'" {
        display as error "rowby and colby cannot be the same variable"
        exit 198
    }
    
    // Check if variables in varlist exist and are numeric
    foreach var of local varlist {
        capture confirm numeric variable `var'
        if _rc != 0 {
            display as error "Variable `var' not found or not numeric"
            exit 111
        }
    }
    
    // Check dependencies and set contract command
    if "`fast'" != "" {
        capture which gtools
        if _rc == 111 {
            display as error "gtools is required for fast option. Install using " ///
                as smcl "{stata ssc install gtools}" as error " and then " ///
                as smcl "{stata gtools, upgrade}"
            exit 111
        }
        local contractcmd "gcontract"
        local contractopt "fast"
    }
    else {
        local contractcmd "contract"
        local contractopt ""
    }

    // * sample marking and setup
    // Mark sample observations
    if "`miss'" == "nomiss" {
        marksample touse, strok
    }
    else {
        marksample touse, strok novarlist
    }

    if "`weight'" != "" {
        local wtexp `"[`weight'`exp']"'
        local markcmd "`wtexp' if `touse'"
    }
    else {
        local markcmd "if `touse'"
    }
    
    // Setup working frame with error handling
    capture frame drop `df'
    capture mkf `df'
    if _rc != 0 {
        display as error "Cannot create working frame `df'"
        exit 198
    }

    // varlist must have two values if yesno specified
    if "`yesno'" != "" {

        // all values in varlist has more than 2 values
        local numofvars: word count `varlist'
        if `numofvars' > 1 {
            local varidx = 1
            foreach var of local varlist {
                quietly levelsof `var', local(values`varidx')
                local allvalues `allvalues' `values`varidx''
                local ++varidx
            }

            local distinctvalues: list sort allvalues
            local distinctvalues: list uniq distinctvalues
            local numdistinctvalues: word count `distinctvalues'
            if `numdistinctvalues' > 2 {
                display as error "Combined values of variables: " as result "`varlist'" as error " have more than 2 distinct values: " as result "`distinctvalues'"
                exit 198
            }
        }

        // each variable in varlist has more or less than 2 values
        foreach checkvar of local varlist {
            preserve
            // Recreate the same sample and processing logic for this variable
            if "`miss'" == "nomiss" {
                marksample checkuse, strok
            }
            else {
                marksample checkuse, strok novarlist
            }
            
            quietly keep if `checkuse'
            quietly levelsof `checkvar' if !missing(`checkvar'), local(var_values)
            local n_values: word count `var_values'
            
            if `n_values' > 2 {
                display as error "Using yesno option -- Variable " as result "`checkvar'" as error " has `n_values' values: " as result "`var_values'"
            }
            else if `n_values' < 2 {
                display as error "Using yesno option -- Variable " as result "`checkvar'" as error " has only `n_values' value(s): " as result "`var_values'"
            }
            if `n_values'!= 2 exit 198
            restore
        }

    }

    // * variable processing loop

    local varcount = 1
    foreach var in `varlist' {
        preserve

        if "`rowby'" != "" {
            // Check if -1 already exists in rowby values
            quietly levelsof `rowby', local(existing_vals)
            if `: list posof "-1" in existing_vals' > 0 {
                display as error "Value -1 already exists in `rowby'. Cannot create total row."
                exit 198
            }

            // Expand observations for totals
            tempvar expanded
            quietly expand 2, generate(`expanded')
            quietly replace `rowby' = -1 if `expanded' == 1

            // Handle value labels for row totals
            local rowby_vallbl : value label `rowby'
            if "`rowby_vallbl'" == "" {
                tempname rowby_temp_lbl
                label define `rowby_temp_lbl' -1 "Total", modify
                label values `rowby' `rowby_temp_lbl'
                if `varcount' == 1 {
                    display as text "Note: Added temporary labels to `rowby' for totals"
                }
            }
            else {
                capture label define `rowby_vallbl' -1 "Total", modify
                if _rc != 0 {
                    display as error "Cannot modify existing value labels for `rowby'"
                    exit 198
                }
            }

            // Store label mappings for later use
            quietly levelsof `rowby', local(rowlist)
            foreach x in `rowlist' {
                if `x' == -1 local val = "_1"
                else local val = `x'
                local `rowby'`val': label (`rowby') `x'
            }
        }
        // Create frequency table using contract command
        `contractcmd' `var' `rowby' `colby' `markcmd', freq(freq) `contractopt'

        // Calculate proportions and percentages
        if "`rowby'" ~= "" | "`colby'" ~= "" quietly egen total = total(freq), by(`rowby' `colby')
        else quietly egen total = total(freq)

        generate prop = freq / total
        generate pct = prop * 100
        
        // Add descriptive variable labels
        label variable prop "Column proportion"
        label variable total "Total"
        label variable freq "Frequency"
        label variable pct "Column percentage (%)"

        // Keep only non-missing observations for current variable
        quietly keep if !missing(`var')
        
        // Add variable metadata
        local varlab: variable label `var'
        quietly generate varname = "`var'"
        quietly generate varlab = "`varlab'"
        quietly generate vallab = ""

        // Handle value labels vs. string conversion
        if "`: value label `var''" != "" {
            quietly decode `var', generate(temp_decoded)
            quietly replace vallab = temp_decoded if missing(vallab)
            sort `var', stable
            quietly drop temp_decoded
        }
        if "`: value label `var''" == "" {
            quietly tostring `var', generate(temp_string)
            quietly replace vallab = temp_string if missing(vallab)
            sort `var', stable
            quietly drop temp_string
        }
        // If yesno option, convert any 2-value variable to no/yes
        if "`yesno'" != "" {

            quietly levelsof `var', local(unique_vals)
            local n_vals: word count `unique_vals'
            
            if `n_vals' == 2 {
                local val1: word 1 of `unique_vals'
                local val2: word 2 of `unique_vals'
                
                // Sort values to ensure consistent assignment (lower=no, higher=yes)
                if `val1' > `val2' {
                    local temp `val1'
                    local val1 `val2'
                    local val2 `temp'
                }
                
                // Inform user about the conversion
                display as text "Note: Variable `var' has no value labels. " ///
                    "Treating value `val1' as 'no' and value `val2' as 'yes'"
                
                quietly replace vallab = "no" if `var' == `val1'
                quietly replace vallab = "yes" if `var' == `val2'
            }
        }

        // Save current variable data and append to working frame
        tempfile var_data
        quietly save `var_data'
        frame `df': quietly append using `var_data'
        
        restore
        local ++varcount
    }

    // * data cleaning and preparation
    // Switch to working frame and clean up
    cwf `df'
    drop `varlist'
    quietly duplicates drop

    // Clean up label formatting (remove prefix numbers if present)
    quietly replace varlab = substr(varlab,strpos(varlab, ".") + 2, strlen(varlab)) if strpos(varlab, ".")>0
    quietly replace vallab = substr(vallab,strpos(vallab, ".") + 2, strlen(vallab)) if strpos(vallab, ".")>0

    // * column-wise reshaping (if colby specified)

    if "`colby'" != "" {

        // Get unique values and their labels
        quietly levelsof `colby', local(colby_values) clean
        if `: word count `colby_values'' == 0 {
            display as error "`colby' has no non-missing values"
            exit 198
        }

        // Create numeric sort key to preserve order through reshape
        quietly generate _numeric_sort = .
        quietly levelsof varname, local(all_vars) clean
        foreach var in `all_vars' {
            quietly levelsof vallab if varname == "`var'", local(var_vallabs) clean
            foreach vallabval in `var_vallabs' {
                // Try to extract numeric value from vallab
                if real("`vallabval'") != . {
                    quietly replace _numeric_sort = real("`vallabval'") if varname == "`var'" & vallab == "`vallabval'"
                }
            }
        }

        // Store column labels for later use
        foreach val of local colby_values {
            local colby_lbl_`val' : label (`colby') `val', strict
            if "`colby_lbl_`val''" == "" local colby_lbl_`val' "`val'"
        }

        // Perform reshape operation
        capture reshape wide freq prop pct total, i(`rowby' varname varlab vallab) j(`colby')
        if _rc != 0 {
            display as error "Reshape failed. Check for duplicate observations or missing identifier variables"
            display as error "Error code: `_rc'"
            exit _rc
        }

        // Sort by the preserved numeric order
        sort varname _numeric_sort
        drop _numeric_sort

        foreach val of local colby_values {
            capture label variable freq`val' "`colby_lbl_`val''"
            capture label variable total`val' "Total `colby_lbl_`val''"
            capture label variable prop`val' "Column proportion `colby_lbl_`val''"
            capture label variable pct`val' "Column percentage `colby_lbl_`val'' (%)"
        }

        // Add overall statistics across columns
        quietly ds freq*, has(type numeric)
        quietly egen freq_all = rowtotal(`r(varlist)')
        quietly egen total_all = total(freq_all), by(`rowby' varname)
        quietly generate prop_all = freq_all / total_all
        quietly generate pct_all = prop_all * 100
        
        label variable freq_all "Overall frequency"
        label variable total_all "Overall total count"
        label variable prop_all "Overall proportion"
        label variable pct_all "Overall percentage (%)"

    }

    // * yes/no transformation (if yesno specified)

    if "`yesno'" != "" {
        // Standardize value labels to lowercase
        quietly replace vallab = lower(vallab)
        quietly levelsof vallab, local(vallab_values)

        // Validate that we have exactly 2 values (yes/no)
        if `r(r)' > 2 {
            display as error "yesno option requires variables, i.e. " as result "`varlist'" as error ", with same value label set."
            display as error "Current combined values:"
            foreach val in `vallab_values' {
                display as error "  `val'"
            }
            exit 198
        }

        // Prefix values for reshape
        quietly replace vallab = "_" + vallab
        
        // Determine which variables to reshape based on colby
        if "`colby'" != "" {
            quietly ds prop* pct* freq* total*, has(type numeric)
        }
        else {
            quietly ds prop* pct* freq*, has(type numeric)
        }

        local reshape_vars "`r(varlist)'"

        // Store variable labels before reshape
        foreach var in `reshape_vars' {
            local `var'_label: variable label `var'
        }

        // Perform yes/no reshape
        if "`colby'" == "" quietly reshape wide prop* pct* freq*, i(`rowby' varname varlab) j(vallab) string
        else if "`colby'" != "" quietly reshape wide prop* pct* freq* total*, i(`rowby' varname varlab) j(vallab) string

        // Apply new labels to reshaped yes/no variables
        foreach val in `vallab_values' {
            if "`colby'" != "" {
                ds prop*`val' pct*`val' freq*`val' total*`val'
                foreach var in `r(varlist)' {
                    local base_var: subinstr local var "_`val'" "", all
                    local original_label "``base_var'_label'"
                    if "`original_label'" != "" label variable `var' "[`val'] `original_label'"
                }
            }
            else {
                quietly ds prop*`val'
                foreach var in `r(varlist)' {
                    label variable `var' "[`val'] Column proportion"
                }
                quietly ds pct*`val'
                foreach var in `r(varlist)' {
                    label variable `var' "[`val'] Column percentage (%)"
                }
                quietly ds freq*`val'
                foreach var in `r(varlist)' {
                    label variable `var' "[`val'] Frequency"
                }
            }
        }
        
    }

    // * stats and type options handling
    // make the percentage and proportion
    rename (prop* pct*) (colprop* colpct*)
    rename (col*all) (*all)

    foreach var of varlist freq* {
        if strpos("`var'", "all") > 0 continue
        local varsuffix = subinstr("`var'", "freq", "", .)
        quietly {
            generate rowprop`varsuffix' = `var' / freq_all
            generate rowpct`varsuffix' = `var' / freq_all * 100
            generate cellprop`varsuffix' = `var' / total_all
            generate cellpct`varsuffix' = `var' / total_all * 100
        }
    }

    // labeling
    foreach var1 of varlist colprop* colpct* {
        local basename1 = subinstr("`var1'", "col", "", .)
        local baselab: variable label `var1'
        foreach var2 of varlist rowprop* rowpct* cellprop* cellpct* {
            if strpos("`var2'", "row") > 0 local basename2 = subinstr("`var2'", "row", "", .)
            else if strpos("`var2'", "cell") > 0 local basename2 = subinstr("`var2'", "cell", "", .)
            if "`basename1'" == "`basename2'" {
                if strpos("`var2'", "row") > 0 local varlab = subinstr("`baselab'", "Column", "Row", .)
                else if strpos("`var2'", "cell") > 0 local varlab = subinstr("`baselab'", "Column", "Cell", .)
                label variable `var2' "`varlab'"
            }
        }
    }

    foreach var of varlist *prop* *pct* {
        if strpos("`var'", "all") > 0 continue
        local varlab: variable label `var'
        // assign the same label with col
        if "`varlab'" != "" label variable `var' "`varlab'"
        if strpos("`var'", "row") > 0 {
            local varlab: variable label `var'
            local varlab = subinstr("`varlab'", "Column", "Row", .)
            label variable `var' "`varlab'"
        }
        else if strpos("`var'", "cell") > 0 {
            local varlab: variable label `var'
            local varlab = subinstr("`varlab'", "Column", "Cell", .)
            label variable `var' "`varlab'"
        }
    }

    // order and drop variables
    order `rowby' varname varlab vallab *prop* *pct* freq* total*, alpha
    order *prop* *pct* freq* total*, last
    if strpos("`stats'", "row") == 0 quietly drop row*
    if strpos("`stats'", "col") == 0 quietly drop col*
    if strpos("`stats'", "cell") == 0 quietly drop cell*
    if strpos("`type'", "prop") == 0 quietly drop *prop*
    if strpos("`type'", "pct") == 0 quietly drop *pct*

    // * formatting and final organization
    if `"`format'"' == "" {
        quietly ds *, has(type numeric)
        foreach var in `r(varlist)' {
            capture assert `var' == round(`var')
            if _rc == 9 {
                quietly summarize `var'
                if `=scalar(r(min))' >= 0 & `=scalar(r(max))' <= 1 quietly format %6.3fc `var'
                else quietly format %20.1fc `var'
            }
            else if _rc == 0 {
                quietly format %20.0fc `var'
            }
        }
    }
    else if `"`format'"' != "" {
        quietly ds *, has(type numeric)
        foreach var in `r(varlist)' {
            quietly format `format' `var'
        }
    }

    // Add standard variable labels
    capture label variable varname "Variable"
    capture label variable varlab "Variable label"
    capture label variable vallab "Value label"

    // Apply row labels if rowby was specified
    if "`rowby'" != "" {
        quietly levelsof `rowby', local(rowlist)
        local varupper = strupper("`rowby'")
        
        foreach x in `rowlist' {
            local val = cond(`x' == -1, "_1", "`x'")
            label define `varupper' `x' "``rowby'`val''", modify
        }
        label values `rowby' `varupper'
    }

    
    // * export to excel
    if "`using'" != "" {
        // Parse and validate file path
        local inputfile = subinstr(`"`using'"', `"""', "", .)
        
        if ustrregexm("`inputfile'", "^(.*[/\\])?([^/\\]+?)(\.[^./\\]+)?$") {
            local fullpath = ustrregexs(1)
            local filename = ustrregexs(2)
            local extension = ustrregexs(3)
            
            if "`filename'" == "" {
                display as error "Invalid filename specified"
                exit 198
            }
            
            // Handle file extension
            if "`extension'" == "" {
                local extension ".xlsx"
            }
            else if "`extension'" != ".xlsx" {
                display as error "Can only export to Excel (.xlsx) format"
                exit 198
            }
            
            local fullname = "`fullpath'`filename'`extension'"
        }
        else {
            display as error "Cannot parse filename from: `inputfile'"
            exit 198
        }

        // Test directory writability
        tempname testhandle
        local testpath = "`fullpath'temp_write_test.txt"
        capture file open `testhandle' using "`testpath'", write replace
        if _rc == 0 {
            file close `testhandle'
            capture erase "`testpath'"
        }
        else {
            display as error "Cannot write to specified directory: `fullpath'"
            exit 603
        }

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

    // * cleanup and return
    // Return to original frame
    capture cwf `currentframe'
    if _rc != 0 {
        display as error "Warning: Could not return to original frame `currentframe'"
        display as text "Current results are in frame `df'"
    }

end