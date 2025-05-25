{smcl}
{* *! version 1.1.0 25May2025}{...}
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
{synopt:{opt rowby}({varname})}create frequency tables by row groups{p_end}
{synopt:{opt colby}({varname})}create frequency tables by column groups{p_end}
{synopt:{opt yesno}}reshape binary variables for yes/no analysis{p_end}

{syntab:Statistics}
{synopt:{opt stats(statlist)}}specify statistics direction: {cmdab:row}, {cmdab:col}, {cmdab:cell}; default is {cmd:col}{p_end}
{synopt:{opt type(typelist)}}specify statistics type: {cmdab:prop}, {cmdab:pct}; default is {cmd:prop}{p_end}

{syntab:Display}
{synopt:{opt format(%fmt)}}specify display format for numeric variables{p_end}
{synopt:{opt nomiss}}exclude missing values from analysis{p_end}

{syntab:Performance}
{synopt:{opt fast}}use {cmd:gcontract} instead of {cmd:contract} for faster processing{p_end}

{syntab:Export}
{synopt:{opt exopt(export_options)}}additional options for Excel export{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:aweight}s, {cmd:fweight}s, {cmd:iweight}s, and {cmd:pweight}s are allowed; see {help weight}.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:dtfreq} produces comprehensive frequency datasets from one or more numeric variables. 
The command creates detailed frequency tables with counts, proportions, and percentages, 
optionally organized by row and column groupings. Results are stored in a new frame 
and can be exported to Excel format.

{pstd}
Unlike basic frequency commands, {cmd:dtfreq} provides:

{phang2}• Multiple variables processed simultaneously{p_end}
{phang2}• Cross-tabulation capabilities with row and column groupings{p_end}
{phang2}• Flexible statistics calculation (row, column, or cell proportions/percentages){p_end}
{phang2}• Automatic total calculations{p_end}
{phang2}• Value label preservation and display{p_end}
{phang2}• Binary variable reshaping for yes/no analysis{p_end}
{phang2}• Direct Excel export functionality{p_end}

{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt df(framename)} specifies the name of the frame, i.e. {it:framename}, where results will be stored. If not specified, results are stored in frame {cmd:_df}. Any existing frame with 
this name will be replaced.

{phang}
{opt rowby}({varname}) creates frequency tables organized by row groups. The specified 
variable defines the grouping, and totals are automatically calculated for each group. A "Total" row (coded as -1) is added to show overall frequencies.

{phang}
{opt colby}({varname}) creates frequency tables organized by column groups. The specified 
variable defines the column structure, with separate frequency, proportion, and percentage 
columns for each value. Cannot be the same variable as {opt rowby}.

{phang}
{opt yesno} reshapes the output for binary variables containing only yes/no responses. This option creates separate columns for each response category. When combined with 
{opt colby}, may produce complex output structures.

{dlgtab:Statistics}

{phang}
{opt stats(statlist)} specifies which statistical directions to calculate, following the syntax of {help tabulate}. Options are:

{phang2}{cmdab:col} - column proportions/percentages (default){p_end}
{phang2}{cmdab:row} - row proportions/percentages{p_end}
{phang2}{cmdab:cell} - cell proportions/percentages{p_end}

{pmore}Multiple options can be specified (e.g., {cmd:stats(row col)}). Default is {cmd:col}.

{phang}
{opt type(typelist)} specifies which types of statistics to display. Options are:

{phang2}{cmdab:prop} - proportions (0-1 scale, default){p_end}
{phang2}{cmdab:pct} - percentages (0-100 scale){p_end}

{pmore}Both can be specified together (e.g., {cmd:type(prop pct)}). Default is {cmd:prop}.

{dlgtab:Display}

{phang}
{opt format(%fmt)} specifies the {helpb format:display format} for all numeric variables in the output. If not specified, {cmd:dtfreq} automatically applies appropriate formatting: %20.0fc for integers, %6.3fc for proportions (0-1), and %20.1fc for other decimal numbers. Must strictly follow Stata 
{helpb format:formatting}.

{phang}
{opt nomiss} excludes observations with missing values from the analysis. By default, 
missing values are included in frequency calculations. Enabling this option may help us produce correct proportions/percentages.

{dlgtab:Performance}

{phang}
{opt fast} uses {help gcontract} instead of the standard {help contract} command for 
potentially faster processing with large datasets. Requires {stata ssc intall gtools:gtools} package.

{dlgtab:Export}

{phang}
{opt exopt(export_options)} specifies additional options for {help export_excel##export_excel_options:Excel export} when using the 
{cmd:using} qualifier. These options are passed directly to the {help export_excel:export excel} 
command. Can only be used with {cmd:using}.

{marker examples}{...}
{title:Examples}

{pstd}Setup using a standard Stata dataset:{p_end}

        {cmd:. capture frame rename default nlsw88}
        {cmd:. sysuse nlsw88.dta, clear}

{pstd}Basic frequency examples:{p_end}

{pstd}1. Simple frequency table (column proportions by default):{p_end}

        {cmd:. frame nlsw88: dtfreq race, df(tf1)}
        {cmd:. frame tf1: list, clean noobs}

{pstd}2. Show percentages instead of proportions:{p_end}

        {cmd:. frame nlsw88: dtfreq race, df(tf2) type(pct)}
        {cmd:. frame tf2: list, clean noobs}

{pstd}3. Show both proportions and percentages:{p_end}

        {cmd:. frame nlsw88: dtfreq race, df(tf3) type(prop pct)}
        {cmd:. frame tf3: list, clean noobs}

{pstd}Statistics direction examples:{p_end}

{pstd}4. Row proportions with grouping:{p_end}

        {cmd:. frame nlsw88: dtfreq race, df(tf4) rowby(married) stats(row)}
        {cmd:. frame tf4: list, noobs sepby(varname)}

{pstd}5. Column percentages with grouping:{p_end}

        {cmd:. frame nlsw88: dtfreq race, df(tf5) rowby(married) stats(col) type(pct)}
        {cmd:. frame tf5: list, noobs sepby(varname)}

{pstd}6. Both row and column statistics:{p_end}

        {cmd:. frame nlsw88: dtfreq race, df(tf6) rowby(married) stats(row col) type(prop pct)}
        {cmd:. frame tf6: describe}

{pstd}Cross-tabulation examples:{p_end}

{pstd}7. Cross-tabulation with column groups:{p_end}

        {cmd:. frame nlsw88: dtfreq race, df(tf7) colby(married)}
        {cmd:. frame tf7: list, clean noobs}

{pstd}8. Two-way table with all statistics:{p_end}

        {cmd:. frame nlsw88: dtfreq race, df(tf8) rowby(collgrad) colby(married) stats(row col cell) type(prop pct)}
        {cmd:. frame tf8: describe}

{pstd}Binary variable examples:{p_end}

{pstd}9. Binary variable with yes/no reshaping (note: may produce incorrect proportions due to missing values):{p_end}

        {cmd:. frame nlsw88: dtfreq union, df(tf9) yesno}
        {cmd:. frame tf9: list, clean noobs}

{pstd}10. Binary variable with proper missing value handling:{p_end}

        {cmd:. frame nlsw88: dtfreq union, df(tf10) yesno nomiss stats(col) type(pct)}
        {cmd:. frame tf10: list, clean noobs}

{pstd}11. Complex binary analysis with grouping:{p_end}

        {cmd:. frame nlsw88: dtfreq union, df(tf11) rowby(collgrad) colby(race) yesno stats(row col) type(prop pct) format(%8.2f)}
        {cmd:. frame tf11: describe}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:dtfreq} stores results in the specified frame (default: {cmd:_df}). The output dataset contains:

{synoptset 15 tabbed}{...}
{p2col 5 20 24 2: Variables}{p_end}
{synopt:{cmd:varname}}original variable name{p_end}
{synopt:{cmd:varlab}}variable label{p_end}
{synopt:{cmd:vallab}}value labels or string representation{p_end}
{synopt:{cmd:freq*}}frequency counts (with suffixes when using {opt colby}){p_end}

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

{pstd}When {opt colby} is specified, all variables are reshaped wide with numeric suffixes for each column group value.{p_end}
{pstd}When {opt yesno} is specified, variables are reshaped with prefixes indicating response categories.{p_end}

{pstd}
The active frame remains unchanged unless an error occurs during frame switching.

{marker author}{...}
{title:Author}

{pstd}Hafiz Arfyanto{p_end}
{pstd}Email: {browse "mailto:hafizarfyanto@gmail.com":hafizarfyanto@gmail.com}{p_end}

{pstd}
Program Version: {bf:1.1.0} (25 May 2025)

{title:Dependencies}

{pstd}
{cmd:dtfreq} works with standard Stata commands. For enhanced performance with large datasets,
the optional {opt fast} option requires:

{phang2}{cmd:gtools} - Install with: {stata ssc install gtools} and then followed by {stata gtools, upgrade}{p_end}

{title:Also see}

{pstd}{helpb tabulate}, {helpb contract}, {helpb table}, {helpb tabstat}, {helpb gcontract} (if installed){p_end}