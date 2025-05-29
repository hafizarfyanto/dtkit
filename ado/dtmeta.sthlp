{smcl}
{* *! version 2.1.0  29may2025}{...}
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
{synopt:{opt c:lear}}clear original data from memory after creating metadata{p_end}
{synopt:{opt s:aving(fileprefix)}}save metadata frames to files with specified prefix{p_end}
{synopt:{opt rep:lace}}replace existing frames and files{p_end}
{synopt:{opt m:erge}}create additional merged frame combining all metadata{p_end}
{synopt:{opt report}}display full metadata extraction report{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:dtmeta} extracts comprehensive metadata from a Stata dataset and organizes it into 
separate frames for easy analysis and documentation. The command creates up to four frames 
containing different aspects of dataset metadata:

{phang2}• Variable metadata including value labels ({cmd:_dtvars}){p_end}
{phang2}• Variable notes ({cmd:_dtnotes}){p_end}
{phang2}• Dataset-level notes ({cmd:_dtinfo}){p_end}
{phang2}• Optional merged metadata frame ({cmd:_dtmeta}){p_end}

{pstd}
{cmd:dtmeta} can process data currently in memory or read from an external file specified 
with the {cmd:using} qualifier. The command preserves and restores the original data unless 
the {cmd:clear} option is specified.

{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt clear} removes the original dataset from memory after creating the metadata frames. 
By default, {cmd:dtmeta} preserves and restores the original data.

{phang}
{opt saving(fprefix)} saves the metadata frames to disk using the specified string as a 
filename prefix. Four files are created: {it:fprefix}_vars.dta, {it:fprefix}_notes.dta, 
{it:fprefix}_info.dta, and optionally {it:fprefix}_meta.dta (if {cmd:merge} is specified).

{phang}
{opt replace} allows {cmd:dtmeta} to overwrite existing frames with the same names 
({cmd:_dtvars}, {cmd:_dtnotes}, {cmd:_dtinfo}, {cmd:_dtmeta}) and existing files 
when using the {cmd:saving()} option.

{phang}
{opt merge} creates an additional frame named {cmd:_dtmeta} that combines all metadata 
into a single frame. This frame includes a {cmd:frame_type} variable to distinguish 
between variable metadata, variable notes, and dataset notes.

{phang}
{opt report} displays detailed metadata extraction report. Some key information that will be displayed includes: number of observations and first five observations in each result frames. 

{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:dtmeta} creates a metadata documentation system using Stata's frame 
functionality. The command extracts and organizes metadata that is often scattered 
across different dataset characteristics.

{pstd}
{ul:{bf:Frame Structure and ID System}}

{pstd}
All frames use a consistent ID system for linking related information:

{phang2}• {cmd:var_id}: Sequential variable number (1, 2, 3, ...) for linking across frames{p_end}
{phang2}• {cmd:row_id}: Unique row identifier within each frame{p_end}
{phang2}• {cmd:dataset_id}: Constant identifier (=1) for dataset-level information{p_end}

{pstd}
{ul:{bf:Frame Contents}}

{pstd}
{it:_dtvars} frame contains one row for each variable-value label combination:

{phang2}• Variables without value labels: one row per variable{p_end}
{phang2}• Variables with value labels: one row per value-label pair{p_end}
{phang2}• Includes variable name, type, format, labels, and value mappings{p_end}

{pstd}
{it:_dtnotes} frame contains variable notes:

{phang2}• One row per note attached to each variable{p_end}
{phang2}• Empty frame if no variable notes exist{p_end}
{phang2}• Includes note sequence number and full note text{p_end}

{pstd}
{it:_dtinfo} frame contains dataset-level notes:

{phang2}• One row per dataset note{p_end}
{phang2}• Single row with empty note if no dataset notes exist{p_end}
{phang2}• Includes dataset label and basic dataset information{p_end}

{pstd}
{it:_dtmeta} frame (optional) combines all metadata:

{phang2}• Merges all three frames into a single structure{p_end}
{phang2}• Includes {cmd:frame_type} variable for filtering{p_end}
{phang2}• Useful for comprehensive metadata analysis{p_end}

{pstd}
{ul:{bf:Merging and Analysis}}

{pstd}
The frames are designed for easy merging and analysis:

{phang2}• Use {cmd:var_id} to merge {cmd:_dtvars} and {cmd:_dtnotes}{p_end}
{phang2}• Each frame includes dataset context variables{p_end}
{phang2}• All frames are compressed for efficient storage{p_end}

{pstd}
{ul:{bf:Data Preservation}}

{pstd}
{cmd:dtmeta} automatically preserves the current dataset and restores it after processing, 
unless {cmd:clear} is specified. When using {cmd:using}, the external file is loaded 
temporarily without affecting data in memory.

{marker examples}{...}
{title:Examples}

{pstd}{bf:Basic metadata extraction from data in memory}{p_end}

        {cmd:. sysuse auto}
        {cmd:. dtmeta}

{pstd}{bf:Extract metadata from external file}{p_end}

        {cmd:. dtmeta using "https://www.stata-press.com/data/r18/nlswork.dta", replace}

{pstd}{bf:Save metadata to files with replace}{p_end}

        {cmd:. dtmeta using "https://www.stata-press.com/data/r18/nlswork.dta", saving("meta_output") replace}

{pstd}{bf:Create merged metadata frame}{p_end}

        {cmd:. dtmeta, merge replace}
        {cmd:. frame _dtmeta: tab frame_type}

{pstd}{bf:Work with metadata}{p_end}

        {cmd:. dtmeta using "https://www.stata-press.com/data/r18/nlswork.dta", merge replace}
        {cmd:. frame _dtmeta: keep if frame_type == "variable"}

{pstd}{bf:Analyze value label coverage}{p_end}

        {cmd:. dtmeta, replace}
        {cmd:. frame _dtvars: generate has_vallab = (value_code != "")}
        {cmd:. frame _dtvars: bysort name: egen max_vallab = max(has_vallab)}
        {cmd:. frame _dtvars: by name: keep if _n == 1}
        {cmd:. frame _dtvars: tab max_vallab}

{pstd}{bf:Document variables with notes}{p_end}

        {cmd:. dtmeta, replace}
        {cmd:. frame _dtnotes: list name note_text}

{pstd}{bf:Comprehensive metadata report}{p_end}

        {cmd:. dtmeta, merge saving("project_meta") replace report}
        {cmd:. frame _dtmeta: list if frame_type == "dataset_note"}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:dtmeta} stores the following in frames:

{synoptset 15 tabbed}{...}
{synopthdr:Frames}
{synoptline}
{p2col:{cmd:_dtvars}}Variable metadata and value labels{p_end}
{p2col:{cmd:_dtnotes}}Variable notes{p_end}
{p2col:{cmd:_dtinfo}}Dataset notes and information{p_end}
{p2col:{cmd:_dtmeta}}Merged metadata (if {cmd:merge} specified){p_end}
{synoptline}
{p2colreset}{...}

{pstd}
Key variables in frames:

{synoptset 15 tabbed}{...}
{synopthdr:Variables}
{synoptline}
{p2col:{cmd:var_id}}Variable ID for linking frames{p_end}
{p2col:{cmd:row_id}}Row ID within frame{p_end}
{p2col:{cmd:name}}Variable name{p_end}
{p2col:{cmd:type}}Variable type{p_end}
{p2col:{cmd:value_code}}Value code from value labels{p_end}
{p2col:{cmd:value_label}}Value label text{p_end}
{p2col:{cmd:note_text}}Note text content{p_end}
{p2col:{cmd:frame_type}}Type of metadata (in _dtmeta only){p_end}
{p2col:{cmd:meta_created}}Metadata creation timestamp{p_end}
{synoptline}
{p2colreset}{...}

{marker author}{...}
{title:Author}

{pstd}Hafiz Arfyanto{p_end}
{pstd}Email: {browse "mailto:hafizarfyanto@gmail.com":hafizarfyanto@gmail.com}{p_end}

{pstd}
Program Version: {bf:1.0.0} (25 May 2025)

{pstd}
For questions and suggestions, please contact the author.

{marker also_see}{...}
{title:Also see}

{psee}
Manual: {manlink R describe}, {manlink R notes}, {manlink R label}, {manlink D frames}

{psee}
Online: {helpb describe}, {helpb notes}, {helpb label}, {helpb frames}