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
{opt dtkit} is a Stata package that provides a collection of commands for data exploration
and analysis. The package extends Stata's built-in capabilities by offering tools for
enhanced summary statistics, detailed frequency analysis, and comprehensive metadata reporting.
All commands in {opt dtkit} utilize Stata's {help frame} functionality to organize their output
into datasets, facilitating further analysis, merging, or export, for instance, to Excel.

{pstd}
The {opt dtkit} package is designed to streamline the initial data exploration process.
It provides more detailed and structured output datasets compared with the display-only output
of some standard Stata commands. Each command in the package offers unique features that
complement Stata's existing functionality, aiming to provide deeper insights into data
characteristics through datasets organized in frames.

{marker commands}{...}
{title:Commands in dtkit}

{dlgtab:Descriptive Statistics}

{phang}
{cmd:dtstat} {varlist} [{it:{help if}}] [{it:{help in}}] [{it:{help weight}}] [{cmd:using} {it:{help filename}}] [{cmd:,} {it:options}]

{pmore}
Creates a dataset in a {help frame} containing descriptive statistics for the specified numeric {varlist}.
Unlike {help summarize} or {help tabstat}, {cmd:dtstat} produces an output dataset that can be further
manipulated, merged, or exported. When used with the {opt by()} option, {cmd:dtstat} computes
statistics for each group and includes overall totals, preserving value labels.

{pmore}
Main options: {opt df(framename)} specifies the output frame name; {opt by(varlist)} computes statistics by group;
{opt stats(statlist)} specifies statistics to calculate (default: {cmd:count mean median min max});
{opt format(%fmt)} sets the display format for statistic variables;
{opt nomiss} excludes observations with missing values; {opt fast} uses {cmd:gtools} for faster processing;
and {opt exopt(export_options)} passes options to {cmd:export excel}.

{dlgtab:Frequency Analysis}

{phang}
{cmd:dtfreq} {varlist} [{it:{help if}}] [{it:{help in}}] [{it:{help weight}}] [{cmd:using} {it:filename}] [{cmd:,} {it:options}]

{pmore}
Produces comprehensive frequency datasets (counts, proportions, percentages) in a {help frame}.
Offers cross-tabulation capabilities with row and column groupings, flexible calculation of statistics
(row, column, or cell proportions/percentages), automatic totals, value label preservation,
binary variable reshaping, and direct Excel export.

{pmore}
Main options: {opt df(framename)} specifies the output frame name; {opt by(varname)} defines row groups;
{opt cross(varname)} defines column groups; {opt binary} reshapes binary variables;
{opt stats(statlist)} specifies direction for statistics (row, col, cell);
{opt type(typelist)} sets statistic type (prop, pct);
{opt format(%fmt)} sets display format; {opt nomiss} excludes missing values from analysis;
and {opt exopt(export_options)} passes options to {cmd:export excel}.

{dlgtab:Dataset Metadata}

{phang}
{cmd:dtmeta} [{cmd:using} {it:{help filename}}] [{cmd:,} {it:options}]

{pmore}
Extracts comprehensive metadata from a Stata dataset and organizes it into separate {help frame:frames}.
Creates frames for variable metadata ({cmd:_dtvars}), value label metadata ({cmd:_dtlabel}),
variable notes ({cmd:_dtnotes}), and dataset information/characteristics ({cmd:_dtinfo}).
Processes data in memory or from external Stata {cmd:.dta} files.

{pmore}
Main options: {opt clear} drops current data in memory when loading from an external file;
{opt replace} allows overwriting an existing Excel export file; {opt report} displays a metadata extraction summary;
and {opt excel(excelname)} exports metadata frames to a specified Excel file.

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
The {opt dtkit} package is designed to integrate with standard Stata workflows.
All commands adhere to Stata conventions for {it:if} and {it:in} qualifiers,
{help weight:weights}, and {help varlist:varlists}. The package leverages Stata's
{help frame:frame} functionality for managing output datasets and provides options
for exporting these frames to Excel.

{pstd}
Key features of the {opt dtkit} commands include:

{p 8 12 2}• Output datasets stored in {help frame:frames}, allowing for further manipulation, merging, or analysis.{p_end}
{p 8 12 2}• Capability to export results to Excel files, with options for customization via {cmd:export excel} sub-options.{p_end}
{p 8 12 2}• Automatic application of appropriate display formats and preservation of value labels in output datasets.{p_end}
{p 8 12 2}• Support for all Stata {help weight:weight} types.{p_end}
{p 8 12 2}• Optional integration with the {cmd:gtools} package for improved performance with large datasets, particularly in {cmd:dtstat} via the {opt fast} option.{p_end}

{pstd}
For detailed information about each command's syntax, options, and stored results,
refer to the individual help files:

{p 8 12 2}• {help dtstat} for creating datasets of descriptive statistics.{p_end}
{p 8 12 2}• {help dtfreq} for producing comprehensive frequency datasets and cross-tabulations.{p_end}
{p 8 12 2}• {help dtmeta} for extracting and organizing dataset metadata.{p_end}

{pstd}
Each command can be used independently or as part of a larger data exploration and
reporting workflow. They are suitable for both interactive use and for inclusion in
do-files and Stata programs.

{marker compatibility}{...}
{title:Compatibility}

{pstd}
{opt dtkit} requires Stata version 16.0 or later due to its use of {help frame:frames},
which were introduced in Stata 16. The commands have been tested in Stata/MP
and on Windows platforms.

{pstd}
Optional dependencies for enhanced performance:

{p 8 12 2}• {cmd:gtools}: Required by {cmd:dtstat} if the {opt fast} option is specified.
Installation: {stata ssc install gtools}, then {stata gtools, upgrade}.
Also consider {stata ssc install gcollapse} if using older versions of gtools.{p_end}

{marker authors}{...}
{title:Authors}

{pstd}Hafiz Arfyanto{p_end}
{pstd}Email: {browse "mailto:hafizarfyanto@gmail.com":hafizarfyanto@gmail.com}{p_end}
{pstd}GitHub: {browse "https://github.com/hafizarfyanto/dtkit":https://github.com/hafizarfyanto/dtkit}{p_end}

{pstd}
Program Version: {bf:2.1.0} (30 May 2025)

{pstd}
The {opt dtkit} package was developed to provide Stata users with tools that enhance
data exploration by producing structured datasets in frames, rather than display-only output.
For questions, suggestions, or bug reports, please contact the author.

{pstd}
These commands are intended to complement Stata's native commands by offering
additional functionalities suited for modern data analysis workflows that benefit
from frame-based data organization and flexible export options.

{marker alsosee}{...}
{title:Also see}

{p 4 13 2}
{manhelp summarize R}, {manhelp tabulate R}, {manhelp describe R}, {manhelp codebook R}, {manhelp frames D}, {manhelp export_excel D}{p_end}