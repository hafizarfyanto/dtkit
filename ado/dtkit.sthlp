{smcl}
{* *! version 2.1.0 29May2025}{...}
{viewerjumpto "Syntax" "dtkit##syntax"}{...}
{viewerjumpto "Description" "dtkit##description"}{...}
{viewerjumpto "Commands" "dtkit##commands"}{...}
{viewerjumpto "Examples" "dtkit##examples"}{...}
{viewerjumpto "Authors" "dtkit##authors"}{...}

{title:Title}

{phang}
{cmd:dtkit} {hline 2} Data toolkit for enhanced data exploration and summary statistics

{marker syntax}{...}
{title:Syntax}

{pstd}
{opt dtkit} is a collection of Stata commands designed to provide enhanced data exploration 
and summary statistics capabilities. The package includes the following commands:

{p 8 17 2}
{manhelp dtstat R:dtstat} - Enhanced descriptive statistics with frame output{p_end}

{p 8 17 2}
{manhelp dtfreq R:dtfreq} - Comprehensive frequency datasets and cross-tabulations{p_end}

{p 8 17 2}
{manhelp dtmeta R:dtmeta} - Dataset metadata extraction into multiple frames{p_end}

{marker description}{...}
{title:Description}

{pstd}
{opt dtkit} is a Stata package that provides a comprehensive set of tools for data exploration 
and analysis. The package extends Stata's built-in capabilities with enhanced summary statistics, 
detailed frequency analysis, and comprehensive metadata reporting. All commands utilize Stata's 
frame functionality to organize output for further analysis and can export results to Excel.

{pstd}
The {opt dtkit} package is designed to streamline the initial data exploration process by 
providing more informative and detailed output than standard Stata commands. Each command 
in the package offers unique features that complement Stata's existing functionality while 
providing additional insights into your data through structured datasets rather than just display output.

{marker commands}{...}
{title:Commands in dtkit}

{dlgtab:Descriptive Statistics}

{phang}
{cmd:dtstat} {varlist} [{it:{help if}}] [{it:{help in}}] [{it:{help weight}}] [{cmd:using} {it:{help filename}}] [{cmd:,} {it:options}]

{pmore}
Creates a dataset containing descriptive statistics for the specified numeric variables.
Unlike {cmd:summarize} or {cmd:tabstat}, {cmd:dtstat} produces a dataset stored in a frame that can be further
manipulated, merged, or exported for reporting purposes. When used with the {opt by()} option, creates 
statistics for each group as well as overall totals with automatic value label preservation.

{pmore}
Main options: {opt df(framename)} to specify output frame name, {opt by(varlist)} for group statistics,
{opt stats(statlist)} to specify statistics (default: count mean median min max), {opt format(%fmt)} for 
number formatting, {opt nomiss} to exclude missing values, {opt fast} to use gtools commands, and 
{opt exopt(export_options)} for Excel export options.

{dlgtab:Frequency Analysis}

{phang}
{cmd:dtfreq} {varlist} [{it:{help if}}] [{it:{help in}}] [{it:{help weight}}] [{cmd:using} {it:filename}] [{cmd:,} {it:options}]

{pmore}
Produces comprehensive frequency datasets from one or more variables with counts, proportions, and percentages.
Provides cross-tabulation capabilities with row and column groupings, flexible statistics calculation 
(row, column, or cell proportions/percentages), automatic total calculations, value label preservation, 
binary variable reshaping for yes/no analysis, and direct Excel export functionality.

{pmore}
Main options: {opt df(framename)} to specify output frame name, {opt by(varname)} for row groups,
{opt cross(varname)} for column groups, {opt binary} for binary variable reshaping, {opt stats(statlist)} 
for statistics direction (row, col, cell), {opt type(typelist)} for statistics type (prop, pct), 
{opt format(%fmt)} for number formatting, {opt nomiss} to exclude missing values, and 
{opt exopt(export_options)} for Excel export options.

{dlgtab:Dataset Metadata}

{phang}
{cmd:dtmeta} [{cmd:using} {it:{help filename}}] [{cmd:,} {it:options}]

{pmore}
Extracts comprehensive metadata from a Stata dataset and organizes it into separate frames 
for easy analysis and documentation. Creates up to four frames containing variable metadata ({cmd:_dtvars}), 
value label metadata ({cmd:_dtlabel}), variable notes ({cmd:_dtnotes}), and dataset information ({cmd:_dtinfo}).
Can process data currently in memory or read from external files.

{pmore}
Main options: {opt clear} to remove original data from memory after loading external data,
{opt replace} to replace existing metadata frames, {opt report} to display metadata extraction report, 
and {opt excel(excelname)} to export metadata frames to Excel file.

{marker examples}{...}
{title:Examples}

{pstd}Load example dataset{p_end}
{p 8 4 2}{stata sysuse auto, clear}{p_end}

{pstd}{cmd:dtstat} - Enhanced descriptive statistics{p_end}
{p 8 4 2}{stata dtstat price mpg weight}{p_end}
{p 8 4 2}{stata dtstat price mpg, by(foreign) stats(count mean sd)}{p_end}
{p 8 4 2}{stata dtstat age grade using "output", df(summary) format(%8.2f)}{p_end}

{pstd}{cmd:dtfreq} - Comprehensive frequency analysis{p_end}
{p 8 4 2}{stata dtfreq foreign}{p_end}
{p 8 4 2}{stata dtfreq rep78, by(foreign) cross(gear_ratio > 3) type(pct)}{p_end}
{p 8 4 2}{stata dtfreq foreign, binary cross(rep78) stats(row col) type(prop pct)}{p_end}

{pstd}{cmd:dtmeta} - Dataset metadata extraction{p_end}
{p 8 4 2}{stata dtmeta, report}{p_end}
{p 8 4 2}{stata dtmeta using "nlsw88.dta", excel("metadata.xlsx") replace clear}{p_end}

{pstd}Combined workflow example{p_end}
{p 8 4 2}{stata sysuse nlsw88, clear}{p_end}
{p 8 4 2}{stata dtmeta, replace report}{p_end}
{p 8 4 2}{stata dtstat age grade, df(summary) by(married) stats(count mean sd)}{p_end}
{p 8 4 2}{stata dtfreq race, df(frequencies) cross(collgrad) stats(col) type(pct)}{p_end}
{p 8 4 2}{stata frame summary: list, noobs sepby(married)}{p_end}
{p 8 4 2}{stata frame frequencies: list, clean noobs}{p_end}

{marker remarks}{...}
{title:Remarks}

{pstd}
The {opt dtkit} package is designed to work seamlessly with existing Stata workflows. 
All commands respect standard Stata conventions for {it:if} and {it:in} qualifiers, 
weights, and variable lists. The package utilizes Stata's frame functionality to organize 
output efficiently and all commands can export results to Excel format.

{pstd}
Key features across all commands:

{p 8 12 2}• Frame-based output for further manipulation and analysis{p_end}
{p 8 12 2}• Excel export capabilities with customizable options{p_end}
{p 8 12 2}• Automatic formatting and value label preservation{p_end}
{p 8 12 2}• Support for all Stata weight types{p_end}
{p 8 12 2}• Optional gtools integration for improved performance{p_end}

{pstd}
For detailed information about each command's syntax and options, see the individual 
help files:

{p 8 12 2}• {help dtstat} for enhanced descriptive statistics{p_end}
{p 8 12 2}• {help dtfreq} for frequency analysis and cross-tabulations{p_end}
{p 8 12 2}• {help dtmeta} for dataset metadata extraction{p_end}

{pstd}
Each command can be used independently or as part of a comprehensive data exploration 
workflow. The commands are optimized for both interactive use and inclusion in 
do-files and programs. All output is stored in frames with descriptive names that 
can be easily accessed for further analysis.

{marker compatibility}{...}
{title:Compatibility}

{pstd}
{opt dtkit} requires Stata 16.0 or later. All commands are tested on Stata/MP and 
utilize frame functionality introduced in Stata 16. The package has been tested on Windows 11.

{pstd}
Optional dependencies for enhanced performance:

{p 8 12 2}• {cmd:gtools} - for faster processing with {cmd:dtstat} when using the {opt fast} option{p_end}
{p 8 12 2}Install with: {stata ssc install gtools} followed by {stata gtools, upgrade}{p_end}

{marker authors}{...}
{title:Authors}

{pstd}Hafiz Arfyanto{p_end}
{pstd}Email: {browse "mailto:hafizarfyanto@gmail.com":hafizarfyanto@gmail.com}{p_end}
{pstd}GitHub: {browse "https://github.com/hafizarfyanto/dtkit":https://github.com/hafizarfyanto/dtkit}{p_end}

{pstd}
Program Version: {bf:2.1.0} (30 May 2025)

{pstd}
{opt dtkit} package was developed to enhance Stata's data exploration capabilities 
through structured dataset output rather than display-only results. For questions, 
suggestions, or bug reports, please contact the author.

{pstd}
The individual commands in this package were designed to complement rather than 
replace Stata's built-in commands, providing additional functionality for modern 
data analysis workflows with frame-based organization and Excel export capabilities.

{marker alsosee}{...}
{title:Also see}

{p 4 13 2}
{manhelp summarize R}, {manhelp tabulate R}, {manhelp describe R}, {manhelp codebook R}, {manhelp frames D}, {manhelp export_excel D}{p_end}