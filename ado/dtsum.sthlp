{smcl}
{* *! version 1.0.0  25may2025}{...}
{vieweralsosee "[R] summarize" "help summarize"}{...}
{vieweralsosee "[R] collapse" "help collapse"}{...}
{vieweralsosee "[R] tabstat" "help tabstat"}{...}
{vieweralsosee "[D] frame" "help frame"}{...}
{viewerjumpto "Syntax" "dtsum##syntax"}{...}
{viewerjumpto "Description" "dtsum##description"}{...}
{viewerjumpto "Options" "dtsum##options"}{...}
{viewerjumpto "Examples" "dtsum##examples"}{...}
{viewerjumpto "Stored results" "dtsum##results"}{...}
{viewerjumpto "Author" "dtsum##author"}{...}
{title:Title}

{phang}
{bf:dtsum} {hline 2} Produce descriptive statistics dataset


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:dtsum}
{varlist}
{ifin}
{weight}
[{cmd:using} {it:{help filename}}]
[{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt df(framename)}}specify frame name for output dataset; default is {cmd:_df}{p_end}
{synopt:{opt by(varlist)}}produce statistics by groups of variables{p_end}
{synopt:{opt stats(statlist)}}specify statistics to calculate; default is {cmd:count mean median min max}{p_end}
{synopt:{opt format(%fmt)}}specify number format for numeric variables{p_end}
{synopt:{opt nomiss}}exclude observations with missing values in variables{p_end}
{synopt:{opt fast}}use {cmd:gtools} commands for faster processing{p_end}

{syntab:Export}
{synopt:{opt exopt(export_options)}}specify additional options for Excel export{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:aweight}s, {cmd:fweight}s, {cmd:iweight}s, and {cmd:pweight}s are allowed;
see {help weight}.

{marker description}{...}
{title:Description}

{pstd}
{cmd:dtsum} creates a dataset containing descriptive statistics for the specified numeric variables.
The results are stored in a Stata frame, which can optionally be exported to Excel.
Unlike {cmd:summarize} or {cmd:tabstat}, {cmd:dtsum} produces a dataset that can be further
manipulated, merged, or exported for reporting purposes.

{pstd}
When used with the {opt by()} option, {cmd:dtsum} creates statistics for each group as well as
overall totals. The program automatically handles value labels and creates appropriate labels
for the total rows.

{pstd}
The program uses Stata {helpb frames} to manage data efficiently and can optionally use {cmd:gtools}
for faster processing with large datasets.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt df(framename)} specifies the name of the frame where the output dataset will be stored.
The default is {cmd:_df}. If a frame with this name already exists, it will be replaced.

{phang}
{opt by(varlist)} specifies that statistics should be calculated separately for each
combination of values in the specified variables. The program will also calculate
overall totals across all groups. Value labels are preserved and "Total" labels are
added for the total rows.

{phang}
{opt stats(statlist)} specifies which statistics to calculate. The default is
{cmd:count mean median min max}. Available statistics include all those supported
by the {cmd:collapse} command, such as:

{pmore2}
{cmd:count} - number of nonmissing observations{break}
{cmd:mean} - arithmetic mean{break}
{cmd:median} - median{break}
{cmd:min} - minimum value{break}
{cmd:max} - maximum value{break}
{cmd:sd} - standard deviation{break}
{cmd:sum} - sum{break}
{cmd:p##} - ##th percentile (e.g., p25, p75){break}
{cmd:iqr} - interquartile range{break}
{cmd:first}, {cmd:last} - first and last values{break}
{cmd:firstnm}, {cmd:lastnm} - first and last nonmissing values

{phang}
{opt format(%fmt)} specifies the {help format:display format} for numeric variables in the output.
If not specified, the program automatically applies appropriate formatting:
{cmd:%20.0fc} for integers and {cmd:%20.1fc} for decimal numbers.

{phang}
{opt nomiss} specifies that observations with missing values in any of the
analysis variables should be excluded from the sample. By default, observations
are excluded only if they have missing values in the currently processed variable.

{phang}
{opt fast} specifies that {cmd:gtools} commands should be used instead of standard
Stata commands for faster processing. This option requires {cmd:gtools} to be installed.
Install with: {stata ssc install gtools}, followed by {stata gtools, upgrade}.

{dlgtab:Export}

{phang}
{opt exopt(export_options)} specifies additional options to pass to the {help export_excel##export_excel_options:Excel export} command. 
These options are passed directly to the {help export_excel:export excel} 
command. This option can only be used with the {cmd:using} clause. If not specified,
the default export options are {cmd:sheet("dtsum_output", replace) firstrow(varlabels)}.

{marker examples}{...}
{title:Examples}

{pstd}Setup using a standard Stata dataset:{p_end}
        
        {cmd:. capture frame create nlsw88}
        {cmd:. frame nlsw88: sysuse nlsw88.dta, clear}

{pstd}1. One-way descriptive statistics for {cmd:age} and {cmd:grade}, results in frame {cmd:_df}:{p_end}

        {cmd:. frame nlsw88: dtsum age grade}
        {cmd:. frame _df: list, clean noobs}

{pstd}2. Descriptive statistics (default) for {cmd:age} and {cmd:grade} stratified by {cmd:married}, results in frame {cmd:df2}:{p_end}

        {cmd:. frame nlsw88: dtsum age grade, df(df2) by(married)}
        {cmd:. frame df2: list, noobs sepby(married)}

{pstd}3. Descriptive statistics (count, mean, and standard deviation) for {cmd:age} and {cmd:grade} stratified by {cmd:married}, results in frame {cmd:df3}:{p_end}

        {cmd:. frame nlsw88: dtsum age grade, df(df3) by(married) stats(count mean sd)}
        {cmd:. frame df3: list, noobs sepby(married)}

{pstd}4. Descriptive statistics (count, mean, and standard deviation) for {cmd:age} and {cmd:grade} stratified by {cmd:married} with {opt format} option (i.e. non-integer values are displayed with two decimal digit and both integer), results in frame {cmd:df4}:{p_end}

        {cmd:. frame nlsw88: dtsum age grade, df(df4) by(married) stats(count mean sd) format(}{bf:%}{cmd:8.2f)}
        {cmd:. frame df4: list, noobs sepby(married)}

{pstd}5. One-way descriptive statistics for {cmd:age} and {cmd:grade}, results in frame {cmd:_df}, export to excel:{p_end}

        {cmd:. frame nlsw88: dtsum age grade using "examples/_df"}
        {cmd:. frame _df: list, clean noobs}

{pstd}6. Descriptive statistics (default) for {cmd:age} and {cmd:grade} stratified by {cmd:married}, results in frame {cmd:df2}, export to excel:{p_end}

        {cmd:. frame nlsw88: dtsum age grade using "examples/df2", df(df2) by(married) exopt(sheet("sum", modify))}
        {cmd:. frame df2: list, noobs sepby(married)}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:dtsum} stores the following in the specified frame (default {cmd:_df}):

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Variables}{p_end}
{synopt:{cmd:varname}}variable name (string){p_end}
{synopt:{cmd:varlab}}variable label (string){p_end}
{synopt:{cmd:[byvar]}}grouping variables (if {opt by()} specified){p_end}
{synopt:{cmd:[statistics]}}requested statistics (numeric){p_end}

{pstd}
The output dataset contains one observation per variable per group (if {opt by()} is used)
or one observation per variable (if {opt by()} is not used). When {opt by()} is specified,
additional rows with value -1 in the grouping variables represent overall totals.


{marker author}{...}
{title:Author}

{pstd}Hafiz Arfyanto{p_end}
{pstd}Email: {browse "mailto:hafizarfyanto@gmail.com":hafizarfyanto@gmail.com}{p_end}

{pstd}
Program Version: {bf:1.0.0} (25 May 2025)

{title:Dependencies}

{pstd}
{cmd:dtsum} works with standard Stata commands. For enhanced performance with large datasets,
the optional {opt fast} option requires:

{phang2}{cmd:gtools} - Install with: {stata ssc install gtools} and then followed by {stata gtools, upgrade}{p_end}

{marker alsosee}{...}
{title:Also see}

{psee}
Manual: {hi:[R] summarize}, {hi:[R] collapse}, {hi:[R] tabstat}

{psee}
Online: {helpb summarize}, {helpb collapse}, {helpb tabstat}, {helpb frame}, {helpb export excel}
{p_end}