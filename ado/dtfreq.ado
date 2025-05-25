capture program drop dtfreq
program define dtfreq
    *! Version 2.0.0 Hafiz 25May2025
    * Module to produce frequency dataset

    version 16
    syntax varlist(min=1 numeric) [if] [in] [aweight fweight iweight pweight] [using/] [, df(string) ROWby(varname numeric) COLby(varname numeric) Yesno FOrmat(string) noMISS FAst Exopt(string) STATs(string) TYpe(string)]

    // * initialization and validation
    // Set default frame name
    if "`df'" == "" local df "_df"
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
    local currentframe = c(frame)
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

    // Validate that rowby and colby are categorical (integer) variables
    if "`rowby'" != "" {
        quietly levelsof `rowby', local(rowby_vals)
        foreach val of local rowby_vals {
            if `val' != int(`val') & !missing(`val') {
                display as error "rowby variable `rowby' contains non-integer values. Use categorical variables only."
                exit 198
            }
        }
    }

    if "`colby'" != "" {
        quietly levelsof `colby', local(colby_vals)
        foreach val of local colby_vals {
            if `val' != int(`val') & !missing(`val') {
                display as error "colby variable `colby' contains non-integer values. Use categorical variables only."
                exit 198
            }
        }
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

        // Create frequency table using table and collect commands
        collect clear
        collect style autolevels on // Ensure all levels of categorical variables are included

        // Build dimension list for collect layout, e.g. (var1) (rowby_var) (colby_var)
        local table_layout_vars "(\`var')"
        if "`rowby'" != "" {
            local table_layout_vars "`table_layout_vars' (\`rowby')"
        }
        if "`colby'" != "" {
            local table_layout_vars "`table_layout_vars' (\`colby')"
        }

        // Build variable list for the table command itself, e.g. var1 rowby_var colby_var
        local table_cmd_vars "`var'"
        if "`rowby'" != "" {
            local table_cmd_vars "`table_cmd_vars' `rowby'"
        }
        if "`colby'" != "" {
            local table_cmd_vars "`table_cmd_vars' `colby'"
        }
        
        // Execute table, collecting the frequency directly as 'freq'
        quietly table `table_cmd_vars' `markcmd', collect(freq name(dtfreq_collect))

        // Define the layout for the collection
        collect layout `table_layout_vars' (freq)

        // Export the collection to a temporary dta file
        tempfile current_var_freqs_dta
        collect export "`current_var_freqs_dta'", as(dta) replace

        // Load the exported dta file. It will contain `var`, `rowby` (if any), `colby` (if any), and `freq`.
        use "`current_var_freqs_dta'", clear
        
        // Variable `freq` should already be named correctly due to `collect(freq)`.
        // Dimension variables (`var`, `rowby`, `colby`) are named correctly by `collect layout`.

        // Label base frequency variable (already done by collect's default or if specified in table)
        // For safety, ensure it's labeled if not already.
        capture label variable freq "Frequency" 

        // --- New Proportion/Percentage Calculations ---

        // Cell Proportions/Percentages (grand total for current `var`)
        // Renaming N_cell to total_freq_for_var as per instruction point 5
        quietly egen total_freq_for_var = total(freq) // Total N for the current `var` across all its combinations
        quietly generate cellprop = freq / total_freq_for_var
        quietly generate cellpct = cellprop * 100
        label variable total_freq_for_var "Total Freq for `var'"
        label variable cellprop "Cell Proportion"
        label variable cellpct "Cell Percent"

        // Row Proportions/Percentages (Only if `rowby` is specified)
        // Proportions within each category of `rowby` for the current `var`.
        if "`rowby'" != "" {
            quietly egen N_row = total(freq), by(`var' `rowby')
            quietly generate rowprop = freq / N_row
            quietly generate rowpct = rowprop * 100
            label variable N_row "Total Freq for (`var', `rowby')" // Denominator for rowprop
            label variable rowprop "Row Proportion"
            label variable rowpct "Row Percent"
        }

        // Column Proportions/Percentages
        local col_total_by_vars "`var'" // Default: by `var` only (makes colprop = cellprop)
        if "`colby'" != "" { // If colby is specified, then by `var` and `colby`
            local col_total_by_vars "`var' `colby'"
        }
        // If colby is NOT specified, col_total_by_vars remains `var`.
        // This means if only rowby is specified, colprop will still be freq / total(freq) by `var`.
        
        quietly egen N_col = total(freq), by(`col_total_by_vars')
        quietly generate colprop = freq / N_col
        quietly generate colpct = colprop * 100
        label variable N_col "Denominator for Col Prop" 
        label variable colprop "Col Proportion"
        label variable colpct "Col Percent"
        // --- End New Proportion/Percentage Calculations ---

        // Keep only non-missing observations for current variable
        quietly keep if !missing(`var')
        
        // Add variable metadata
        local varlab: variable label `var'
        quietly generate varname = "`var'"
        quietly generate varlab = "`varlab'"
        quietly generate vallab = ""

        // Handle value labels vs. string conversion
        tempvar temp_decoded temp_string

        if "`: value label `var''" != "" {
            quietly decode `var', generate(`temp_decoded')
            quietly replace vallab = `temp_decoded' if missing(vallab)
            quietly drop `temp_decoded'
        }
        else {
            quietly replace vallab = string(`var')
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

        // Remove observations with missing rowby or colby values
        if "`rowby'" != "" {
            quietly drop if missing(`rowby') | missing(`colby')
        }
        else {
            quietly drop if missing(`colby')
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

        foreach val of local colby_values {
            local clean_val = subinstr("`val'", ".", "_", .)
            local colby_lbl_`clean_val' : label (`colby') `val', strict
            if "`colby_lbl_`clean_val''" == "" local colby_lbl_`clean_val' "`val'"
        }

        // Define list of variables to reshape based on what was generated
        local reshape_wide_vars "freq cellprop cellpct total_freq_for_var colprop colpct N_col"
        // Check if row-specific variables were generated (i.e., if rowby was specified)
        // A simple way to check is if N_row exists (it's only created if rowby is present)
        capture confirm variable N_row
        if _rc == 0 {
            local reshape_wide_vars "`reshape_wide_vars' rowprop rowpct N_row"
        }

        // Perform reshape operation with new variables
        capture reshape wide `reshape_wide_vars', i(`rowby' varname varlab vallab) j(`colby')
        if _rc != 0 {
            display as error "Reshape failed. Check for duplicate observations or missing identifier variables (vars: `reshape_wide_vars'). Error: `_rc'"
            exit _rc
        }

        // Sort by the preserved numeric order
        sort varname _numeric_sort
        drop _numeric_sort

        foreach val of local colby_values {
            local clean_val = subinstr("`val'", ".", "_", .)
            capture label variable freq`val' "`colby_lbl_`val'' Freq"
            capture label variable cellprop`val' "`colby_lbl_`val'' Cell Prop"
            capture label variable cellpct`val' "`colby_lbl_`val'' Cell Pct"
            capture label variable total_freq_for_var`val' "`colby_lbl_`val'' Total N for Var"
            capture label variable colprop`val' "`colby_lbl_`val'' Col Prop"
            capture label variable colpct`val' "`colby_lbl_`val'' Col Pct"
            capture label variable N_col`val' "`colby_lbl_`val'' N for Col"
            
            capture confirm variable N_row`val' // Check if N_row was reshaped
            if _rc == 0 {
                capture label variable rowprop`val' "`colby_lbl_`val'' Row Prop"
                capture label variable rowpct`val' "`colby_lbl_`val'' Row Pct"
                capture label variable N_row`val' "`colby_lbl_`val'' N for Row"
            }
        }

        // Add overall frequency across columns. Other "overall" props/pcts are less direct now.
        // `total_freq_for_var` should be consistent across reshaped columns for the same original `varname`.
        quietly ds freq`colby_values[0]' // Check if freq* vars exist from reshape
        if _rc == 0 { // only proceed if reshape created freq vars
            quietly ds freq*, not(vallab varname varlab `rowby') // Get only reshaped freq vars
            if "`r(varlist)'" != "" {
                 quietly egen overall_freq = rowtotal(`r(varlist)')
                 label variable overall_freq "Overall Frequency (sum over `colby')"

                 // Overall cell proportion using the first reshaped total_freq_for_var
                 // (assuming total_freq_for_var is consistent for a given varname across colby values)
                 local first_col_val = `colby_values[1]' // Get the first value from the list
                 capture confirm variable total_freq_for_var`first_col_val'
                 if _rc == 0 {
                    quietly generate overall_cellprop = overall_freq / total_freq_for_var`first_col_val'
                    quietly generate overall_cellpct = overall_cellprop * 100
                    label variable overall_cellprop "Overall Cell Prop (vs Var Total)"
                    label variable overall_cellpct "Overall Cell Pct (vs Var Total)"
                 }
            }
        }
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
        // Determine which variables to reshape based on current data structure
        local yesno_reshape_vars_list "freq cellprop cellpct total_freq_for_var colprop colpct N_col overall_freq overall_cellprop overall_cellpct"
        capture confirm variable N_row // or N_row`val` if colby was active
        if _rc == 0 { // If N_row exists (meaning rowby was specified)
             local yesno_reshape_vars_list "`yesno_reshape_vars_list' rowprop rowpct N_row"
        }

        local current_vars_to_reshape // This will hold the actual existing variables for reshape
        if "`colby'" != "" { // Variables have been reshaped by colby (e.g., freq1, freq2)
            foreach basevar in `yesno_reshape_vars_list' {
                quietly ds `basevar`*, not(vallab varname varlab `rowby') // find basevar1, basevar2 etc.
                if "`r(varlist)'" != "" {
                    local current_vars_to_reshape "`current_vars_to_reshape' `r(varlist)'"
                }
            }
        }
        else { // No colby, variables are in their original form (e.g. freq, cellprop)
            foreach varname_chk in `yesno_reshape_vars_list' {
                capture confirm variable `varname_chk'
                if _rc == 0 {
                    local current_vars_to_reshape "`current_vars_to_reshape' `varname_chk'"
                }
            }
        }
        
        if "`current_vars_to_reshape'" == "" {
            display as error "No variables found for yes/no reshape. Vars checked: `yesno_reshape_vars_list'"
            // exit 198 // Or handle more gracefully
        }

        // Store variable labels before reshape
        foreach var in `reshape_vars' {
            local `var'_label: variable label `var'
        }

        // Perform yes/no reshape
        if "`colby'" == "" quietly reshape wide prop* pct* freq*, i(`rowby' varname varlab) j(vallab) string
        else if "`colby'" != "" quietly reshape wide prop* pct* freq* total*, i(`rowby' varname varlab) j(vallab) string

        // Apply new labels to reshaped yes/no variables
        foreach val_yesno in `vallab_values' { // e.g. _yes, _no
            foreach base_var_name in `current_vars_to_reshape' {
                 local reshaped_yesno_var = "`base_var_name'`val_yesno'"
                 capture confirm variable `reshaped_yesno_var'
                 if _rc == 0 {
                    local original_label "``base_var_name'_label'"
                    if "`original_label'" != "" {
                        label variable `reshaped_yesno_var' "[`val_yesno'] `original_label'"
                    }
            }
            else {
                         label variable `reshaped_yesno_var' "[`val_yesno'] `base_var_name'" // Fallback label
                    }
                 }
            }
        }
    }

    // * formatting and final organization (stats & type options applied here)
    // Add new options to syntax: stats(string asis) type(string asis)
    // For now, assume they are added to syntax elsewhere. For this subtask, implement logic.
    
    // Default stats and type if not specified by user (example)
    // if "`stats'" == "" local stats "cell row col" // Show all
    // if "`type'" == "" local type "freq pct"    // Show freq and percent

    // stats option handling (drop what's NOT requested)
    // If "all" is in stats, none of these specific stat types are dropped.
    if strpos("`stats'", "all") == 0 {
        if strpos("`stats'", "row") == 0 {
            capture drop rowprop*
            capture drop rowpct*
        }
        if strpos("`stats'", "col") == 0 {
            capture drop colprop*
            capture drop colpct*
        }
        if strpos("`stats'", "cell") == 0 {
            capture drop cellprop*
            capture drop cellpct*
        }
    }
    
    // type option handling (drop what's NOT requested)
    // If "all" is in type, none of these specific types are dropped.
    if strpos("`type'", "all") == 0 {
        if strpos("`type'", "prop") == 0 {
            capture drop cellprop* rowprop* colprop* overall_cellprop*
        }
        if strpos("`type'", "pct") == 0 {
            capture drop cellpct* rowpct* colpct* overall_cellpct*
        }
        if strpos("`type'", "freq") == 0 {
            capture drop freq*  // Catches freq, freq1, freq_yes, etc.
            capture drop overall_freq*
        }
    }

    // Drop helper total variables N_* unless "all" is in stats or "all" is in type (implicitly keeping them if their stats/types are kept)
    // Or more directly, if user hasn't asked for "all" stats, these are intermediate.
    if strpos("`stats'", "all") == 0 {
        capture drop N_col* N_row* total_freq_for_var*
    }
    // However, if a user asks for e.g. stats(cell) type(prop), they might implicitly want total_freq_for_var if it's used to derive cellprop.
    // The logic above for 'stats' and 'type' already handles prop/pct/freq.
    // Let's refine: N_* are purely denominators. Drop them if their specific stat type is not requested OR if "all" is not in stats.
    // The previous stats block was: if strpos("`stats'", "row") == 0 { capture drop N_row* }
    // This is better. The `total_freq_for_var` is tied to cell stats or freq.

    // Revised N_* dropping logic based on subtask point 4, applied AFTER specific stat/type drops.
    // This means if, for example, rowprop was kept, N_row would still be dropped here unless we make it conditional.
    // Subtask says: "explicitly drop the intermediate total variables".
    // This suggests they are always dropped if not part of "all".
    // Let's try a simpler approach for N_* vars: drop them if "all" is not in stats.
    // If stats(all) is present, they are kept. Otherwise, they are considered intermediate.
    // The specific proportions/percentages are handled by the main stat/type logic.
    
    // Final decision for N_* vars: Drop them if "all" is not in `stats`.
    // This is because they are denominators; their direct value is rarely reported unless for debugging or full data.
    if strpos("`stats'", "all") == 0 {
        capture drop N_col*
        capture drop N_row*
        capture drop total_freq_for_var*
    }


    // Final Ordering
    local final_order_vars `rowby' `colby' varname varlab vallab 
    // Add variables that might exist, in preferred order
    // N_* vars and total_freq_for_var* are removed from this list as they are likely dropped.
    local potential_vars "freq* overall_freq* cellpct* rowpct* colpct* overall_cellpct* cellprop* rowprop* colprop* overall_cellprop*"
    
    foreach pvar in `potential_vars' {
        quietly ds `pvar', not(vallab varname varlab `rowby' `colby') // Check if vars matching pattern exist
        if "`r(varlist)'" != "" {
            local final_order_vars "`final_order_vars' `r(varlist)'"
        }
    }
    capture order `final_order_vars'
        
    // * stats and type options handling
    // make the percentage and proportion
    rename (prop* pct*) (colprop* colpct*)
    if "`colby'" != "" {
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

    }

    // order and drop variables
    order `rowby' varname varlab vallab *prop* *pct* freq* total*, alpha
    order *prop* *pct* freq* total*, last
    if strpos("`stats'", "row") == 0 capture drop row*
    if strpos("`stats'", "col") == 0 capture drop col*
    if strpos("`stats'", "cell") == 0 capture drop cell*
    if strpos("`type'", "prop") == 0 capture drop *prop*
    if strpos("`type'", "pct") == 0 capture drop *pct*

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
cd D:/OneDrive/MyWork/personal/stata/repo/dtkit
do test/dtfreq_test.do