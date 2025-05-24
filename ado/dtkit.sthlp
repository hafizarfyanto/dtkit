{smcl}
{* *! version 1.0.0 24May2025}{...}
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
{manhelp dtsum R:dtsum} - Enhanced summary statistics with additional measures{p_end}

{p 8 17 2}
{manhelp dtfreq R:dtfreq} - Comprehensive frequency tables and distributions{p_end}

{p 8 17 2}
{manhelp dtmeta R:dtmeta} - Dataset metadata and variable information summary{p_end}

{marker description}{...}
{title:Description}

{pstd}
{opt dtkit} is a Stata package that provides a comprehensive set of tools for data exploration 
and analysis. The package extends Stata's built-in capabilities with enhanced summary statistics, 
detailed frequency analysis, and comprehensive metadata reporting.

{pstd}
The {opt dtkit} package is designed to streamline the initial data exploration process by 
providing more informative and detailed output than standard Stata commands. Each command 
in the package offers unique features that complement Stata's existing functionality while 
providing additional insights into your data.

{marker commands}{...}
{title:Commands in dtkit}

{dlgtab:Summary Statistics}

{phang}
{cmd:dtsum} [{varlist}] [{it:{help if}}] [{it:{help in}}] [{it:{help weight}}] [, {it:options}]

{pmore}
Provides enhanced summary statistics including additional measures beyond Stata's standard 
{cmd:summarize} command. Features include extended percentiles, measures of distribution 
shape, and customizable output formatting.

{dlgtab:Frequency Analysis}

{phang}
{cmd:dtfreq} {varlist} [{it:{help if}}] [{it:{help in}}] [{it:{help weight}}] [, {it:options}]

{pmore}
Generates comprehensive frequency tables and distribution analysis. Includes cumulative 
frequencies, relative frequencies, and statistical measures for categorical and discrete 
numerical variables.

{dlgtab:Dataset Metadata}

{phang}
{cmd:dtmeta} [{varlist}] [, {it:options}]

{pmore}
Provides detailed metadata about the dataset and variables, including variable types, 
labels, value labels, missing value patterns, and storage information. Useful for 
understanding dataset structure and quality assessment.

{marker examples}{...}
{title:Examples}

{pstd}Load example dataset{p_end}
{p 8 4 2}{stata sysuse auto, clear}{p_end}

{pstd}{cmd:dtsum} - Enhanced summary statistics{p_end}
{p 8 4 2}{stata dtsum price mpg weight}{p_end}
{p 8 4 2}{stata dtsum if foreign == 1}{p_end}

{pstd}{cmd:dtfreq} - Frequency analysis{p_end}
{p 8 4 2}{stata dtfreq foreign make}{p_end}
{p 8 4 2}{stata dtfreq price if mpg > 20}{p_end}

{pstd}{cmd:dtmeta} - Dataset metadata{p_end}
{p 8 4 2}{stata dtmeta, replace}{p_end}

{pstd}Combined workflow example{p_end}
{p 8 4 2}{stata sysuse nlsw88, clear}{p_end}
{p 8 4 2}{stata dtmeta, merge replace}{p_end}
{p 8 4 2}{stata dtsum age grade, df(sum1) by(married) stats(count mean sd)}{p_end}
{p 8 4 2}{stata dtfreq race, df(freq1) rowby(collgrad) colby(married)}{p_end}

{marker remarks}{...}
{title:Remarks}

{pstd}
The {opt dtkit} package is designed to work seamlessly with existing Stata workflows. 
All commands respect standard Stata conventions for {it:if} and {it:in} qualifiers, 
weights, and variable lists.

{pstd}
For detailed information about each command's syntax and options, see the individual 
help files:

{p 8 12 2}• {help dtsum} for enhanced summary statistics{p_end}
{p 8 12 2}• {help dtfreq} for frequency analysis{p_end}
{p 8 12 2}• {help dtmeta} for dataset metadata{p_end}

{pstd}
Each command can be used independently or as part of a comprehensive data exploration 
workflow. The commands are optimized for both interactive use and inclusion in 
do-files and programs.

{marker compatibility}{...}
{title:Compatibility}

{pstd}
{opt dtkit} requires Stata 16.0 or later. All commands are tested only on Stata/MP. The package has been tested on Windows 11 only.

{marker authors}{...}
{title:Authors}

{pstd}Hafiz Arfyanto{p_end}
{pstd}Email: {browse "mailto:hafizarfyanto@gmail.com":hafizarfyanto@gmail.com}{p_end}

{pstd}
{opt dtkit} package was developed to enhance Stata's data exploration capabilities. 
For questions, suggestions, or bug reports, please contact the author.

{pstd}
The individual commands in this package were designed to complement rather than 
replace Stata's built-in commands, providing additional functionality for modern 
data analysis workflows.

{marker alsosee}{...}
{title:Also see}

{p 4 13 2}
{manhelp summarize R}, {manhelp tabulate R}, {manhelp describe R}, {manhelp codebook R}{p_end}