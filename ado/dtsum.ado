capture program drop dtsum
program define dtsum
    *! Version 1.1.0 Hafiz 25May2025
    * Module to produce descriptive statistics dataset

    version 16
    syntax varlist(min=1 numeric) [if] [in] [aweight fweight iweight pweight] [using/] [, df(string) by(varlist) stats(string asis) FOrmat(string) noMISS FAst Exopt(string)]
    
    // * initialization and validation
    // Set default frame name
    if "`df'" == "" local df "_df"
    
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
        local collapsecmd "gcollapse"
    }
    else {
        local collapsecmd "collapse"
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

    // * stats option processing
    // Default statistics if STATS() option is not specified
    if `"`stats'"' == "" {
        local stats "count mean median min max"
    }
    // Define a local macro for the "total" identifier value
    local total_id -1 // Using -1 to represent totals, assumes -1 is not a valid category in by-vars

    // Parse the requested statistics into a format suitable for collapse
    local collapse_stats "" // Initialize empty local for collapse syntax parts
    foreach stat of local stats {
        // Basic validation: check if stat name looks reasonable (can be expanded)
        local collapse_stats `"`collapse_stats' (`stat') `stat'"' // Building the stat part for collapse command
    }
    // Trim leading space and finalize quotes (handling varname later)
    local collapse_stats = strtrim(`"`collapse_stats'"')

    // * main collapse loop
    local varcount = 1
    foreach var in `varlist' {
        preserve
        local `var'lab: variable label `var'
        foreach vartype in `stats' {
            quietly clonevar `vartype' = `var'
        }
        // option 1: without by
        if "`by'" == "" {
            capture `collapsecmd' `collapse_stats' `markcmd', fast favor(speed)
            if _rc != 0 `collapsecmd' `collapse_stats' `markcmd', fast
        }

        // option 2: with by
        else if "`by'" != "" {
            tempvar expanded
            quietly expand 2, generate(`expanded')
            foreach byvar in `by' {
                // Check if -1 already exists in by values
                quietly levelsof `byvar', local(existing_vals)
                if `: list posof "-1" in existing_vals' > 0 {
                    display as error "Value -1 already exists in `byvar'. Cannot create total row."
                    exit 198
                }

                quietly replace `byvar' = -1 if `expanded' == 1

                // Handle value labels for row totals
                local by_vallbl : value label `byvar'
                if "`by_vallbl'" == "" {
                    tempname by_temp_lbl
                    label define `by_temp_lbl' -1 "Total", modify
                    label values `byvar' `by_temp_lbl'
                    if `varcount' == 1 {
                        display as text "Note: Added temporary labels to `byvar' for totals"
                    }
                }
                else {
                    capture label define `by_vallbl' -1 "Total", modify
                    if _rc != 0 {
                        display as error "Cannot modify existing value labels for `rowby'"
                        exit 198
                    }
                }

            }
            capture `collapsecmd' `collapse_stats' `markcmd', by(`by')fast favor(speed)
            if _rc != 0 `collapsecmd' `collapse_stats' `markcmd', by(`by')fast
            quietly for var `by': drop if missing(X)
        }

        quietly generate varname = "`var'"
        quietly generate varlab = "``var'lab'", after(varname)

        tempfile data`var'
        quietly save `data`var''
        frame `df': quietly append using `data`var''
        restore 
        local ++varcount
    }

    frame `df' {
        order `by' varname varlab
        sort `by' varname varlab, stable

        quietly replace varlab = substr(varlab,strpos(varlab, ".") + 2, strlen(varlab)) if strpos(varlab, ".")>0

        capture label variable mean "means"
        capture label variable median "medians"

        forvalues i = 1/99 {
            local suffix "th"
            if inrange(`i', 11, 13) local suffix "th"
            else if mod(`i', 10) == 1 local suffix "st"
            else if mod(`i', 10) == 2 local suffix "nd"
            else if mod(`i', 10) == 3 local suffix "rd"
            capture label variable p`i' "`i'`suffix' percentile"
        }

        capture label variable sd "standard deviations"
        capture label variable semean "standard error of the mean (sd/sqrt(n))"
        capture label variable sebinomial "standard error of the mean, binomial (sqrt(p(1-p)/n))"
        capture label variable sepoisson "standard error of the mean, Poisson (sqrt(mean/n))"
        capture label variable sum "sums"
        capture label variable rawsum "sums, ignoring optionally specified weight except observations with a weight of zero are excluded"
        capture label variable count "number of nonmissing observations"
        capture label variable percent "percentage of nonmissing observations in the by group"
        capture label variable max "maximums"
        capture label variable min "minimums"
        capture label variable iqr "interquartile range"
        capture label variable first "first value"
        capture label variable last "last value"
        capture label variable firstnm "first nonmissing value"
        capture label variable lastnm "last nonmissing value"
        label variable varname "Variable"
        label variable varlab "Variable label"

        // * formatting and final organization
        if `"`format'"' == "" {
            quietly ds *, has(type numeric)
            foreach var in `r(varlist)' {
                capture assert `var' == round(`var')
                if _rc == 9 {
                    quietly format %20.1fc `var'
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
                local exportcmd `"`fullname', sheet("dtsum_output", replace) firstrow(varlabels)"'
            }
            else {
                local exportcmd `"`fullname', `exopt'"'
            }
            
            // Perform export with error handling
            export excel using `exportcmd'
        }
    }

end

// if c(hostname)== "hafiz-A" local basedir "C:/Users/hafiz/"
// else if c(hostname) == "NUXS" local basedir "D:/"
// cd "`basedir'OneDrive/MyWork/personal/stata/repo/dtkit"
// do examples/dtsum_examples.do
