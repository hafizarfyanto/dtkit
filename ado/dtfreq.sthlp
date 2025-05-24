{smcl}
{* *! version 1.0.0 25May2025}{...}
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

{dlgtab:Display}

{phang}
{opt format(%fmt)} specifies the {helpb format:display format} for all numeric variables in the output. If not specified, {cmd:dtfreq} automatically applies appropriate formatting: %20.0fc for integers and %20.1fc for decimal numbers. Must strictly follow Stata 
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

{pstd}1. One-way frequency table for race, results in frame tf1:{p_end}

        {cmd:. frame nlsw88: dtfreq race, df(tf1)}
        {cmd:. frame tf1: list, clean noobs}

{pstd}2. Frequency table for race stratified by married (rows), results in frame tf2:{p_end}

        {cmd:. frame nlsw88: dtfreq race, df(tf2) rowby(married)}
        {cmd:. frame tf2: list, noobs sepby(varname)}

{pstd}3. Frequency table for race cross-tabulated by married (columns), results in frame tf3:{p_end}

        {cmd:. frame nlsw88: dtfreq race, df(tf3) colby(married)}
        {cmd:. frame tf3: list, clean noobs}

{pstd}4. Two-way table for race, rows by collgrad, columns by married, results in frame tf4:{p_end}

        {cmd:. frame nlsw88: dtfreq race, df(tf4) rowby(collgrad) colby(married)}
        {cmd:. frame tf4: describe}

{pstd}5. Using yesno for the binary variable union. Results in frame tf5. This will produce incorrect proportions/percentages, because union has missing values:{p_end}

        {cmd:. frame nlsw88: dtfreq union, df(tf5) yesno}
        {cmd:. frame tf5: list, clean noobs}

{pstd}6. Using yesno with colby. Results in frame tf6. This will correct the proportions/percentages:{p_end}

        {cmd:. frame nlsw88: dtfreq union, df(tf6) yesno nomiss}
        {cmd:. frame tf6: list, clean noobs}

{pstd}7. Using yesno with rowby, colby, and formatting option. Results in frame tf7:{p_end}

        {cmd:. frame nlsw88: dtfreq union, df(tf7) rowby(collgrad) colby(race) yesno format(%8.2f)}
        {cmd:. frame tf7: describe}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:dtfreq} stores results in the specified frame (default: {cmd:_df}). The output dataset contains:

{synoptset 15 tabbed}{...}
{p2col 5 20 24 2: Variables}{p_end}
{synopt:{cmd:varname}}original variable name{p_end}
{synopt:{cmd:varlab}}variable label{p_end}
{synopt:{cmd:vallab}}value labels or string representation{p_end}
{synopt:{cmd:freq}}frequency count{p_end}
{synopt:{cmd:prop}}proportion (0-1){p_end}
{synopt:{cmd:pct}}percentage (0-100){p_end}
{synopt:{cmd:total}}total count for denominator{p_end}

{pstd}When {opt colby} is specified, variables are reshaped wide with suffixes for each column group value.{p_end}
{pstd}When {opt yesno} is specified, variables are reshaped with prefixes indicating response categories.{p_end}

{pstd}
The active frame remains unchanged unless an error occurs during frame switching.

{marker author}{...}
{title:Author}

{pstd}Hafiz Arfyanto{p_end}
{pstd}Email: {browse "mailto:hafizarfyanto@gmail.com":hafizarfyanto@gmail.com}{p_end}

{pstd}
Program Version: {bf:1.0.0} (25 May 2025)

{title:Dependencies}

{pstd}
{cmd:dtfreq} works with standard Stata commands. For enhanced performance with large datasets,
the optional {opt fast} option requires:

{phang2}{cmd:gtools} - Install with: {stata ssc install gtools} and then followed by {stata gtools, upgrade}{p_end}

{title:Also see}

{pstd}{helpb tabulate}, {helpb contract}, {helpb table}, {helpb tabstat}, {helpb gcontract} (if installed){p_end}