{smcl}
{* *! version 2.1.1  02June2025}{...}
{vieweralsosee "[R] summarize" "help summarize"}{...}
{vieweralsosee "[R] collapse" "help collapse"}{...}
{vieweralsosee "[R] tabstat" "help tabstat"}{...}
{vieweralsosee "[D] frame" "help frame"}{...}
{viewerjumpto "Syntax" "dtstat##syntax"}{...}
{viewerjumpto "Description" "dtstat##description"}{...}
{viewerjumpto "Options" "dtstat##options"}{...}
{viewerjumpto "Examples" "dtstat##examples"}{...}
{viewerjumpto "Stored results" "dtstat##results"}{...}
{viewerjumpto "Author" "dtstat##author"}{...}
{title:Title}

{phang}
{bf:dtstat} {hline 2} Produce descriptive statistics dataset


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:dtstat}
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
{synopt:{opt save(excelname)}}export results to Excel file{p_end}
{synopt:{opt excel(export_options)}}specify additional options for Excel export{p_end}
{synopt:{opt rep:lace}}specify that {it:excelname} should be replaced if it already exists{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:aweight}s, {cmd:fweight}s, {cmd:iweight}s, and {cmd:pweight}s are allowed;
see {help weight}.

{marker description}{...}
{title:Description}

{pstd}
{cmd:dtstat} creates a dataset containing descriptive statistics for the specified numeric {varlist}.
The results are stored in a Stata {help frame}, which can optionally be exported to an Excel file
using the {cmd:save()} option. Unlike {help summarize} or {help tabstat}, which primarily display
results, {cmd:dtstat} produces a new dataset (frame). This output dataset can be further
manipulated, merged with other datasets, or exported, making it suitable for reporting and complex data workflows.

{pstd}
When the {opt by(varlist)} option is specified, {cmd:dtstat} computes statistics separately for each group
defined by the {it:by_variables}. In this case, the output dataset includes rows for each group and
additional rows representing overall totals. The program automatically preserves and uses value labels
for the grouping variables and creates appropriate labels for the total rows (e.g., "Total").

{pstd}
{cmd:dtstat} leverages Stata {helpb frames} for efficient data management. For improved performance
with large datasets, the {opt fast} option can be used, which utilizes commands from the
{cmd:gtools} package (if installed; see {stata "ssc install gtools":ssc install gtools} and
{stata "ssc install gcollapse":ssc install gcollapse}).


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt df(framename)} specifies the name of the {help frame} that will contain the output dataset
of descriptive statistics. The default is {cmd:_df}. If a frame with the specified name
already exists, it will be replaced.

{phang}
{opt by(varlist)} specifies that statistics are to be computed separately for each group defined
by the combinations of values of the variables in {it:varlist}. The output dataset will include
rows for each of these groups. Overall totals across all groups are also calculated and included.
Value labels of the {it:by_variables} are preserved in the output. Rows corresponding to totals
are identified by a special value (typically -1, or another system missing value if -1 conflicts
with actual data values) in the {it:by_variables} columns and are labeled "Total" or with the
value label associated with that special value.

{phang}
{opt stats(statlist)} specifies the list of statistics to be calculated. The default is
{cmd:count mean median min max}. Any statistic supported by the {help collapse} command
may be specified. Common statistics include:

{pmore2}
{cmd:count} - number of nonmissing observations{break}
{cmd:mean} - arithmetic mean{break}
{cmd:median} - median (50th percentile){break}
{cmd:min} - minimum value{break}
{cmd:max} - maximum value{break}
{cmd:sd} - standard deviation{break}
{cmd:sum} - sum of values{break}
{cmd:p}{it:##} - ##th percentile (e.g., {cmd:p25} for the 25th percentile, {cmd:p75} for the 75th percentile){break}
{cmd:iqr} - interquartile range (difference between the 75th and 25th percentiles){break}
{cmd:first} - first observation in group{break}
{cmd:last} - last observation in group{break}
{cmd:firstnm} - first nonmissing observation in group{break}
{cmd:lastnm} - last nonmissing observation in group

{phang}
{opt format(%fmt)} specifies the {help format:display format} for all numeric variables containing
calculated statistics in the output dataset. If not specified, {cmd:dtstat} automatically applies
{cmd:%20.0fc} for integer statistics like count, and {cmd:%20.1fc} for statistics that may have
decimal values (e.g., mean, median, percentiles).

{phang}
{opt nomiss} specifies that observations with a missing value in any of the variables listed in
the main {varlist} (the variables for which statistics are being calculated) or in the {opt by(varlist)}
should be excluded from all computations. By default, {cmd:dtstat} performs calculations using all
nonmissing values for each variable or group individually (casewise deletion per statistic per group).

{phang}
{opt fast} specifies that commands from the {cmd:gtools} package (e.g., {cmd:gcollapse}) should be
used for computation where possible. This can significantly improve performance with large datasets.
This option requires the {cmd:gtools} package to be installed. If {cmd:gtools} is not installed,
{cmd:dtstat} will issue a warning and proceed using standard Stata commands.
(See {stata "ssc install gtools":ssc install gtools}, {stata "ssc install gcollapse":ssc install gcollapse}).

{dlgtab:Export}

{phang}
{opt save(excelname)} exports the results to an Excel file named {it:filename}.
When {cmd:save()} is specified, the statistics frame is exported to the Excel file.
If not specified, results are only stored in the Stata frame.

{phang}
{opt excel(export_options)} provides a way to pass additional options to the {help export_excel}
command when {cmd:dtstat} is used with the {cmd:save()} option to export results to an Excel file.
These {it:export_options} are passed directly to {cmd:export excel}. There is no need to wrap {it:export_excel_options} in double quotes. For example, to specify a sheet name
and replace an existing sheet, one might use {cmd:excel(sheet("SummaryStats"), replace)}.
If not specified, {cmd:dtstat} uses default export options:
{cmd:sheet("dtstat_output", modify) firstrow(varlabels)}.
This option is only valid when {cmd:save()} {it:excelname} is also specified.

{phang}
{opt replace} specifies that if the specified sheet in {it:excelname} file already exists, it should be replaced.

{marker examples}{...}
{title:Examples}

{pstd}Setup using a standard Stata dataset:{p_end}
        
        {cmd:. capture frame create nlsw88}
        {cmd:. frame nlsw88: sysuse nlsw88.dta, clear}

{pstd}1. One-way descriptive statistics for {cmd:age} and {cmd:grade}, results in frame {cmd:_df}:{p_end}

        {cmd:. frame nlsw88: dtstat age grade}
        {cmd:. frame _df: list, clean noobs}

{pstd}2. Descriptive statistics (default) for {cmd:age} and {cmd:grade} stratified by {cmd:married}, results in frame {cmd:df2}:{p_end}

        {cmd:. frame nlsw88: dtstat age grade, df(df2) by(married)}
        {cmd:. frame df2: list, noobs sepby(married)}

{pstd}3. Descriptive statistics (count, mean, and standard deviation) for {cmd:age} and {cmd:grade} stratified by {cmd:married}, results in frame {cmd:df3}:{p_end}

        {cmd:. frame nlsw88: dtstat age grade, df(df3) by(married) stats(count mean sd)}
        {cmd:. frame df3: list, noobs sepby(married)}

{pstd}4. Descriptive statistics (count, mean, and standard deviation) for {cmd:age} and {cmd:grade} stratified by {cmd:married} with {opt format} option (i.e. non-integer values are displayed with two decimal digit and both integer), results in frame {cmd:df4}:{p_end}

        {cmd:. frame nlsw88: dtstat age grade, df(df4) by(married) stats(count mean sd) format(}{bf:%}{cmd:8.2f)}
        {cmd:. frame df4: list, noobs sepby(married)}

{pstd}5. One-way descriptive statistics for {cmd:age} and {cmd:grade}, results in frame {cmd:_df}, export to excel:{p_end}

        {cmd:. frame nlsw88: dtstat age grade, save("examples/_df.xlsx")}
        {cmd:. frame _df: list, clean noobs}

{pstd}6. Descriptive statistics (default) for {cmd:age} and {cmd:grade} stratified by {cmd:married}, results in frame {cmd:df2}, export to excel:{p_end}

        {cmd:. frame nlsw88: dtstat age grade, df(df2) by(married) save("examples/df2.xlsx") excel(sheet("sum", modify))}
        {cmd:. frame df2: list, noobs sepby(married)}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:dtstat} creates an output dataset in the specified {help frame} (default {cmd:_df}). This dataset contains the following variables:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Variable Name}{Description}{p_end}
{synopt:{cmd:varname}}A string variable containing the names of the variables from the input {varlist} for which statistics were calculated.{p_end}
{synopt:{cmd:varlab}}A string variable containing the variable labels of the input variables, if present.{p_end}
{synopt:{it:by_variables}}If the {opt by(varlist)} option is specified, these variables (matching the names and types of those in {it:varlist}) identify the groups for which statistics were computed. For overall total rows, these variables will contain a special value (e.g., -1, or a system missing value if -1 has a defined value label for a {it:by_variable}) and will be labeled "Total" (or with the label for that special value).{p_end}
{synopt:{it:stat_names}}Variables corresponding to each statistic requested in the {opt stats(statlist)} option (e.g., {cmd:mean}, {cmd:median}, {cmd:sd}). These are numeric variables containing the calculated statistics.{p_end}
{p2colreset}{...}

{pstd}
The structure of the output dataset is as follows:
{p_end}
{pstd}
• If {opt by(varlist)} is {ul:not} specified, the dataset contains one observation for each variable in the input {varlist}. Each row represents the summary statistics for one variable.
{p_end}
{pstd}
• If {opt by(varlist)} {ul:is} specified, the dataset contains one observation for each variable in the input {varlist} {it:for each combination} of the values of the {it:by_variables}. Additional observations are included for overall totals across all groups for each variable in the input {varlist}.
For example, if statistics are calculated for variables {cmd:v1} and {cmd:v2}, and the option {cmd:by(groupvar)} is specified where {cmd:groupvar} has two unique values (A and B), the output dataset will typically have rows for:
{p_end}
{phang2}- {cmd:v1} for group A{p_end}
{phang2}- {cmd:v2} for group A{p_end}
{phang2}- {cmd:v1} for group B{p_end}
{phang2}- {cmd:v2} for group B{p_end}
{phang2}- {cmd:v1} for Total{p_end}
{phang2}- {cmd:v2} for Total{p_end}

{marker author}{...}
{title:Author}

{pstd}Hafiz Arfyanto{p_end}
{pstd}Email: {browse "mailto:hafizarfyanto@gmail.com":hafizarfyanto@gmail.com}{p_end}
{pstd}GitHub: {browse "https://github.com/hafizarfyanto/dtkit":https://github.com/hafizarfyanto/dtkit}{p_end}

{pstd}
Program Version: {bf:2.1.1} (02 June 2025)

{title:Dependencies}

{pstd}
{cmd:dtstat} works with standard Stata commands. For enhanced performance with large datasets,
the optional {opt fast} option requires:

{phang2}{cmd:gtools} - Install with: {stata ssc install gtools} and then followed by {stata gtools, upgrade}{p_end}

{marker alsosee}{...}
{title:Also see}

{psee}
Manual: {hi:[R] summarize}, {hi:[R] collapse}, {hi:[R] tabstat}

{psee}
Online: {helpb summarize}, {helpb collapse}, {helpb tabstat}, {helpb frame}, {helpb export excel}
{p_end}