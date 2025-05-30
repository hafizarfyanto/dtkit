{smcl}
{* *! version 2.1.0  30may2025}{...}
{vieweralsosee "[R] describe" "help describe"}{...}
{vieweralsosee "[R] notes" "help notes"}{...}
{vieweralsosee "[R] label" "help label"}{...}
{vieweralsosee "[D] frames" "help frames"}{...}
{viewerjumpto "Syntax" "dtmeta##syntax"}{...}
{viewerjumpto "Description" "dtmeta##description"}{...}
{viewerjumpto "Options" "dtmeta##options"}{...}
{viewerjumpto "Remarks" "dtmeta##remarks"}{...}
{viewerjumpto "Examples" "dtmeta##examples"}{...}
{viewerjumpto "Stored results" "dtmeta##results"}{...}
{viewerjumpto "Author" "dtmeta##author"}{...}
{title:Title}

{phang}
{bf:dtmeta} {hline 2} Extract dataset metadata into multiple frames

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:dtmeta}
[{cmd:using} {it:{help filename}}]
[{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt c:lear}}clear original data from memory after loading external data{p_end}
{synopt:{opt rep:lace}}replace existing metadata frames{p_end}
{synopt:{opt report}}display metadata extraction report{p_end}
{synopt:{opt excel(string)}}export metadata frames to Excel file{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:dtmeta} extracts comprehensive metadata from a Stata dataset and organizes it into 
separate frames for easy analysis and documentation. The command creates up to four frames 
containing different aspects of dataset metadata:

{phang2}• Variable metadata ({cmd:_dtvars}){p_end}
{phang2}• Value label metadata ({cmd:_dtlabel}){p_end}
{phang2}• Variable notes ({cmd:_dtnotes}){p_end}
{phang2}• Dataset information and notes ({cmd:_dtinfo}){p_end}

{pstd}
{cmd:dtmeta} can process data currently in memory or read from an external file specified 
with the {cmd:using} qualifier. The command preserves the original data in memory unless 
the {cmd:clear} option is specified with external data loading.

{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt clear} removes the original dataset from memory after loading external data with 
{cmd:using}. Only valid when used together with {cmd:using}. When data is loaded from 
an external file, {cmd:clear} prevents preservation of the original data in memory.

{phang}
{opt replace} allows {cmd:dtmeta} to overwrite existing Excel files when using the 
{cmd:excel()} option. Only valid when used together with {cmd:excel()}. When not specified, 
the command will attempt to modify existing Excel files by adding new sheets.

{phang}
{opt report} displays a comprehensive metadata extraction report showing:
- Source dataset information (filename, variables, observations)
- Summary of created frames with row counts
- Clickable frame access commands for easy navigation
This option provides detailed feedback about the metadata extraction process.

{phang}
{opt excel(string)} exports all metadata frames to an Excel file with the specified filename. 
Each frame is saved as a separate worksheet within the Excel file. Only valid when used 
together with the {cmd:replace} option.

{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:dtmeta} creates a metadata documentation system using Stata's frame 
functionality. The command extracts and organizes metadata that is often scattered 
across different dataset characteristics.

{pstd}
{ul:{bf:Frame Structure}}

{pstd}
All frames include a {cmd:_level} variable to identify the metadata level and are labeled 
with descriptive dataset labels for easy identification.

{pstd}
{ul:{bf:Frame Contents}}

{pstd}
{it:_dtvars} frame contains variable metadata:

{phang2}• {cmd:_level}: Metadata level indicator ("variable"){p_end}
{phang2}• {cmd:varname}: Variable name{p_end}
{phang2}• {cmd:position}: Variable order in the dataset{p_end}
{phang2}• {cmd:type}: Storage type{p_end}
{phang2}• {cmd:format}: Display format{p_end}
{phang2}• {cmd:vallab}: Value label name{p_end}
{phang2}• {cmd:varlab}: Variable label{p_end}

{pstd}
{it:_dtlabel} frame contains value label metadata:

{phang2}• {cmd:_level}: Metadata level indicator ("value label"){p_end}
{phang2}• {cmd:varname}: Variable name using the value label{p_end}
{phang2}• {cmd:index}: Value index within label{p_end}
{phang2}• {cmd:vallab}: Value label name{p_end}
{phang2}• {cmd:value}: Numeric value{p_end}
{phang2}• {cmd:label}: Value label text{p_end}
{phang2}• {cmd:trunc}: Indicator if label text is truncated{p_end}

{pstd}
{it:_dtnotes} frame contains variable notes:

{phang2}• {cmd:_level}: Metadata level indicator ("variable"){p_end}
{phang2}• {cmd:varname}: Variable name{p_end}
{phang2}• {cmd:_note_id}: Note sequence number{p_end}
{phang2}• {cmd:_note_text}: Note content (strL type){p_end}

{pstd}
{it:_dtinfo} frame contains dataset-level information:

{phang2}• {cmd:_level}: Metadata level indicator ("dataset"){p_end}
{phang2}• {cmd:dta_note_id}: Dataset note sequence number{p_end}
{phang2}• {cmd:dta_note}: Dataset note content (strL type){p_end}
{phang2}• {cmd:dta_obs}: Number of observations{p_end}
{phang2}• {cmd:dta_vars}: Number of variables{p_end}
{phang2}• {cmd:dta_label}: Dataset label{p_end}
{phang2}• {cmd:dta_ts}: Dataset timestamp{p_end}

{pstd}
{ul:{bf:Frame Management}}}

{pstd}
{cmd:dtmeta} automatically replaces any existing metadata frames ({cmd:_dtvars}, {cmd:_dtlabel}, 
{cmd:_dtnotes}, {cmd:_dtinfo}) each time it runs. This ensures that the metadata always reflects 
the current state of the source dataset.

{pstd}
{ul:{bf:Excel Export}}}

{pstd}
When using the {cmd:excel()} option, the command exports all created metadata frames to separate 
worksheets within a single Excel file. Without the {cmd:replace} option, the command attempts 
to modify existing Excel files by adding new sheets. With {cmd:replace}, it creates a new file, 
overwriting any existing file with the same name.

{pstd}
{ul:{bf:Empty Frames}}

{pstd}
If a dataset has no variable notes, the {cmd:_dtnotes} frame will not be created and 
a note will be displayed. Similarly, if a dataset has no value labels, the {cmd:_dtlabel} 
frame will not be created. The {cmd:_dtvars} and {cmd:_dtinfo} frames are always created 
as they contain essential dataset information.

{pstd}
{ul:{bf:Reporting and Navigation}}}

{pstd}
The command always displays clickable frame access commands after completion, making it easy 
to navigate between the created metadata frames and return to the source data. When the 
{cmd:report} option is specified, additional detailed information is shown including:

{phang2}• Source dataset information (filename, variable count, observation count){p_end}
{phang2}• Summary of created frames with row counts{p_end}
{phang2}• Detailed breakdown of metadata extraction results{p_end}

{pstd}
{ul:{bf:Data Preservation}}

{pstd}
{cmd:dtmeta} automatically preserves the current dataset when working with data in memory. 
When using {cmd:using} to load external data, the command can optionally preserve the 
original data unless {cmd:clear} is specified.

{marker examples}{...}
{title:Examples}

{pstd}{bf:Basic metadata extraction from data in memory}{p_end}

        {cmd:. sysuse auto}
        {cmd:. dtmeta}

{pstd}{bf:Extract metadata from external file}{p_end}

        {cmd:. dtmeta using "https://www.stata-press.com/data/r18/nlswork.dta"}

{pstd}{bf:Show detailed report with frame access commands}{p_end}

        {cmd:. dtmeta, report}

{pstd}{bf:Export to Excel with file replacement}{p_end}

        {cmd:. dtmeta, excel("dataset_metadata.xlsx") replace}

{pstd}{bf:Work with variable metadata}{p_end}

        {cmd:. dtmeta, replace}
        {cmd:. frame _dtvars: list varname type format vallab}

{pstd}{bf:Analyze value label coverage}{p_end}

        {cmd:. dtmeta, replace}
        {cmd:. frame _dtvars: generate has_vallab = (vallab != "")}
        {cmd:. frame _dtvars: tab has_vallab}

{pstd}{bf:Examine variable notes}{p_end}

        {cmd:. dtmeta, replace}
        {cmd:. frame _dtnotes: list varname _note_text}

{pstd}{bf:Review dataset information}{p_end}

        {cmd:. dtmeta, replace}
        {cmd:. frame _dtnotes: list name note_text}

{pstd}{bf:Comprehensive workflow with external data and export}{p_end}

        {cmd:. dtmeta using "mydata.dta", excel("mydata_metadata.xlsx") replace report clear}

{pstd}{bf:Clear memory after loading external data}{p_end}

        {cmd:. dtmeta using "mydata.dta", clear}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:dtmeta} stores the following in {cmd:r()}:

{synoptset 18 tabbed}{...}
{synopthdr:Scalars}
{synoptline}
{p2col:{cmd:r(N)}}number of observations{p_end}
{p2col:{cmd:r(k)}}number of variables{p_end}
{synoptline}
{p2colreset}{...}

{synoptset 18 tabbed}{...}
{synopthdr:Macros}
{synoptline}
{p2col:{cmd:r(varlist)}}variable names{p_end}
{p2col:{cmd:r(source_frame)}}name of source data frame{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{cmd:dtmeta} creates the following frames:

{synoptset 18 tabbed}{...}
{synopthdr:Frames}
{synoptline}
{p2col:{cmd:_dtvars}}Variable metadata (always created){p_end}
{p2col:{cmd:_dtlabel}}Value label metadata (if value labels exist){p_end}
{p2col:{cmd:_dtnotes}}Variable notes (if variable notes exist){p_end}
{p2col:{cmd:_dtinfo}}Dataset information and notes (always created){p_end}
{synoptline}
{p2colreset}{...}

{marker author}{...}
{title:Author}

{pstd}Hafiz Arfyanto{p_end}
{pstd}Email: {browse "mailto:hafizarfyanto@gmail.com":hafizarfyanto@gmail.com}{p_end}
{pstd}GitHub: {browse "https://github.com/hafizarfyanto/dtkit":https://github.com/hafizarfyanto/dtkit}{p_end}

{pstd}
Program Version: {bf:2.1.0} (30 May 2025)

{pstd}
For questions and suggestions, please contact the author.

{marker also_see}{...}
{title:Also see}

{psee}
Manual: {manlink R describe}, {manlink R notes}, {manlink R label}, {manlink D frames}

{psee}
Online: {helpb describe}, {helpb notes}, {helpb notes_}, {helpb label}, {helpb frames}