{smcl}
{* *! version 1.0.0 02Jun2025}{...}
{vieweralsosee "[R] contract" "help contract"}{...}
{vieweralsosee "[R] table" "help table"}{...}
{vieweralsosee "[R] tabstat" "help tabstat"}{...}
{vieweralsosee "[R] tabulate" "help tabulate"}{...}
{viewerjumpto "Syntax" "dtfreq##syntax"}{...}
{viewerjumpto "Description" "dtfreq##description"}{...}
{viewerjumpto "Options" "dtfreq##options"}{...}
{viewerjumpto "Examples" "dtfreq##examples"}{...}
{viewerjumpto "Stored results" "dtfreq##results"}{...}
{viewerjumpto "Author" "dtfreq##author"}{...}
{title:Title}

{phang}
{bf:dtfreq} {hline 2} Produce comprehensive frequency datasets

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:dtfreq}
{varlist}
{ifin}
{weight}
[{cmd:using} {it:filename}]
[{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt df(framename)}}specify name for destination {help frame}; default is {cmd:_df}{p_end}
{synopt:{opt by}({varname})}create frequency tables by row groups{p_end}
{synopt:{opt cross}({varname})}create frequency tables by column groups{p_end}
{synopt:{opt binary}}reshape binary variables for yes/no analysis{p_end}

{syntab:Statistics}
{synopt:{opt stats(statlist)}}specify statistics direction: {cmdab:row}, {cmdab:col}, {cmdab:cell}; default is {cmd:col}{p_end}
{synopt:{opt type(typelist)}}specify statistics type: {cmdab:prop}, {cmdab:pct}; default is {cmd:prop}{p_end}

{syntab:Display}
{synopt:{opt format(%fmt)}}specify display format for numeric variables{p_end}
{synopt:{opt nomiss}}exclude missing values from analysis{p_end}

{syntab:Export}
{synopt:{opt save(filename)}}export results to Excel file{p_end}
{synopt:{opt excel(export_options)}}additional options for Excel export{p_end}
{synopt:{opt clear}}clear data from memory when using external file{p_end}
{synopt:{opt replace}}replace existing Excel file when saving{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:aweight}s, {cmd:fweight}s, {cmd:iweight}s, and {cmd:pweight}s are allowed; see {help weight}.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:dtfreq} produces comprehensive frequency datasets from one or more numeric variables. 
The command creates detailed frequency tables with counts, proportions, and percentages, 
optionally organized by row and column groupings. Results are stored in a new {help frame}
and can be exported to Excel format.

{pstd}
Unlike basic frequency commands (e.g., {help tabulate} or {help contract}), {cmd:dtfreq} provides:

{phang2}• Processing of multiple variables simultaneously.{p_end}
{phang2}• Cross-tabulation capabilities, creating tables with row and column groupings defined by variables.{p_end}
{phang2}• Flexible statistics calculation (row, column, or cell proportions/percentages).{p_end}
{phang2}• Automatic calculation of totals for groups and overall.{p_end}
{phang2}• Preservation and display of value labels in the output dataset.{p_end}
{phang2}• Binary variable reshaping, which structures variables with yes/no type responses into separate columns for each category.{p_end}
{phang2}• Direct Excel export functionality for the resulting dataset.{p_end}

{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt df(framename)} specifies the name of the {help frame} where the resulting dataset will be stored.
If {it:framename} is not specified, results are stored in a frame named {cmd:_df}.
Any existing frame with the specified name will be replaced.

{phang}
{opt by}({varname}) creates frequency tables organized by row groups based on the categories of {it:varname}.
The specified variable defines these row groupings. Totals are automatically calculated for each group,
and an overall "Total" row (coded as -1 in the {it:varname} column of the output frame, unless a value label is defined for -1 for that variable) is added to show overall frequencies.

{phang}
{opt cross}({varname}) creates frequency tables with column groups based on the categories of {it:varname}.
The specified variable defines this column structure, creating separate sets of frequency, proportion,
and percentage columns for each of its values. This option cannot be used with the same variable specified in {opt by()}.

{phang}
{opt binary} reshapes the output for binary variables (variables with only two distinct nonmissing values, typically representing yes/no, true/false, or 0/1).
This option creates separate columns in the output dataset for each response category of the binary variable.
When combined with {opt cross}, this may produce more complex output structures.

{dlgtab:Statistics}

{phang}
{opt stats(statlist)} specifies the direction for calculating proportions or percentages, similar to the options in {help tabulate}. Options are:

{phang2}{cmdab:col} - calculate column proportions/percentages (default). This means percentages are calculated relative to the column totals.{p_end}
{phang2}{cmdab:row} - calculate row proportions/percentages. This means percentages are calculated relative to the row totals.{p_end}
{phang2}{cmdab:cell} - calculate cell proportions/percentages. This means percentages are calculated relative to the overall total count.{p_end}

{pmore}Multiple options can be specified (e.g., {cmd:stats(row col)}). The default is {cmd:col}.
This option is effective when {opt cross()} is also specified, as it determines the denominator for percentage calculations.

{phang}
{opt type(typelist)} specifies the type of statistics to display. Options are:

{phang2}{cmdab:prop} - display proportions (scaled from 0 to 1; default).{p_end}
{phang2}{cmdab:pct} - display percentages (scaled from 0 to 100).{p_end}

{pmore}Both types can be specified together (e.g., {cmd:type(prop pct)}). The default is {cmd:prop}.

{dlgtab:Display}

{phang}
{opt format(%fmt)} specifies the {helpb format:display format} for all numeric statistic variables
(frequencies, proportions, percentages) in the output dataset. If not specified, {cmd:dtfreq} automatically
applies suitable formats: {cmd:%20.0fc} for counts, {cmd:%6.3fc} for proportions (0-1),
and {cmd:%20.1fc} for percentages (0-100) and other decimal numbers.
The format must strictly follow Stata's {helpb format:formatting rules}.

{phang}
{opt nomiss} excludes observations with missing values in any of the {varlist} variables from all calculations.
By default, missing values in {varlist} are treated as a distinct category for frequency counts.
Specifying {opt nomiss} ensures that proportions and percentages are calculated based only on nonmissing observations.

{dlgtab:Export}

{phang}
{opt save(filename)} exports the results to an Excel file named {it:filename}.
When {cmd:save()} is specified, the frequency table frame is exported to the Excel file.
If not specified, results are only stored in the Stata frame.

{phang}
{opt excel(export_options)} specifies additional options for {help export_excel##export_excel_options:Excel export} when using the 
{cmd:save()} option. These options are passed directly to the {help export_excel:export excel} 
command. Can only be used with {cmd:save()}.

{marker examples}{...}
{title:Examples}

{pstd}Setup using standard Stata datasets:{p_end}

        {cmd:. sysuse auto, clear}

{pstd}Basic frequency examples:{p_end}

{pstd}1. Simple frequency table for one variable:{p_end}

        {cmd:. dtfreq rep78}
        {cmd:. frame _df: list, clean noobs}

{pstd}2. Multiple variables:{p_end}

        {cmd:. dtfreq rep78 foreign}
        {cmd:. frame _df: tab varname}

{pstd}3. Show percentages instead of proportions:{p_end}

        {cmd:. dtfreq rep78, type(pct)}
        {cmd:. frame _df: list, clean noobs}

{pstd}Cross-tabulation examples:{p_end}

{pstd}4. by option (row groups):{p_end}

        {cmd:. dtfreq rep78, by(foreign)}
        {cmd:. frame _df: list varname foreign vallab freq colprop, clean sepby(varname)}

{pstd}5. cross option (column groups):{p_end}

        {cmd:. dtfreq rep78, cross(foreign)}
        {cmd:. frame _df: describe, simple}
        {cmd:. frame _df: list, clean noobs}

{pstd}6. Both by and cross options:{p_end}

        {cmd:. dtfreq rep78, by(foreign) cross(trunk)}
        {cmd:. frame _df: list, clean sepby(varname)}

{pstd}Statistics direction examples:{p_end}

{pstd}7. Row proportions:{p_end}

        {cmd:. dtfreq rep78, cross(foreign) stats(row)}
        {cmd:. frame _df: list, clean noobs}

{pstd}8. Cell proportions:{p_end}

        {cmd:. dtfreq rep78, cross(foreign) stats(cell)}
        {cmd:. frame _df: list, clean noobs}

{pstd}9. Multiple statistics types:{p_end}

        {cmd:. dtfreq rep78, cross(foreign) stats(row col) type(prop pct)}
        {cmd:. frame _df: describe}

{pstd}Binary variable examples:{p_end}

        {cmd:. sysuse nlsw88, clear}

{pstd}10. Binary variable reshaping:{p_end}

        {cmd:. dtfreq union, binary}
        {cmd:. frame _df: list, clean noobs}

{pstd}11. Binary with cross-tabulation:{p_end}

        {cmd:. dtfreq union, binary cross(collgrad)}
        {cmd:. frame _df: list, clean noobs}

{pstd}Export examples:{p_end}

{pstd}12. Export to Excel:{p_end}

        {cmd:. dtfreq rep78, save(dtfreq_output.xlsx) replace}

{pstd}13. Using external data file:{p_end}

        {cmd:. dtfreq rep78 using "auto.dta", clear}
        {cmd:. frame _df: list, clean noobs}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:dtfreq} stores results in the specified frame (default: {cmd:_df}). The output dataset contains:

{synoptset 15 tabbed}{...}
{p2col 5 20 24 2: Variables}{p_end}
{synopt:{cmd:varname}}original variable name{p_end}
{synopt:{cmd:varlab}}variable label{p_end}
{synopt:{cmd:vallab}}value labels or string representation{p_end}
{synopt:{cmd:freq*}}frequency counts (with suffixes when using {opt cross}){p_end}

{pstd}Statistics variables (prefixed by direction):{p_end}
{synopt:{cmd:colprop*}}column proportions (default){p_end}
{synopt:{cmd:colpct*}}column percentages{p_end}
{synopt:{cmd:rowprop*}}row proportions{p_end}
{synopt:{cmd:rowpct*}}row percentages{p_end}
{synopt:{cmd:cellprop*}}cell proportions{p_end}
{synopt:{cmd:cellpct*}}cell percentages{p_end}
{synopt:{cmd:*total*}}total counts for denominators{p_end}

{pstd}Variable presence depends on {opt stats()} and {opt type()} options:{p_end}

{phang2}• {opt stats(col)} creates {cmd:colprop*} and/or {cmd:colpct*} variables{p_end}
{phang2}• {opt stats(row)} creates {cmd:rowprop*} and/or {cmd:rowpct*} variables{p_end}
{phang2}• {opt stats(cell)} creates {cmd:cellprop*} and/or {cmd:cellpct*} variables{p_end}
{phang2}• {opt type(prop)} includes proportion variables{p_end}
{phang2}• {opt type(pct)} includes percentage variables{p_end}

{pstd}When {opt cross}({it:varname}) is specified, the output variables representing frequencies and statistics are reshaped wide. This means that for each category of the {it:varname} specified in {opt cross()}, a new set of variables is created, typically with numeric suffixes (e.g., {cmd:freq_1}, {cmd:freq_2}, {cmd:colprop_1}, {cmd:colprop_2}) appended to the base variable names to distinguish the column groups.{p_end}
{pstd}When {opt binary} is specified, variables in the output dataset are structured to represent the different response categories of the binary input variable. This often involves creating prefixed variable names (e.g., {cmd:yes_variablename}, {cmd:no_variablename}) or similar structures to clearly indicate each response category within the reshaped data.{p_end}

{pstd}
The active frame remains unchanged unless an error occurs during frame switching.

{marker author}{...}
{title:Author}

{pstd}Hafiz Arfyanto{p_end}
{pstd}Email: {browse "mailto:hafizarfyanto@gmail.com":hafizarfyanto@gmail.com}{p_end}
{pstd}GitHub: {browse "https://github.com/hafizarfyanto/dtkit":https://github.com/hafizarfyanto/dtkit}{p_end}

{pstd}
Program Version: {bf:1.0.0} (02 June 2025)

{title:Also see}

{pstd}{helpb tabulate}, {helpb contract}, {helpb table}, {helpb tabstat}{p_end}