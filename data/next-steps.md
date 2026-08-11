# Academic / Technical Archive Evidence Console
## GitHub Drop-In Development Plan

Current baseline:
- Phase 1 inventories a selected directory recursively.
- Phase 2 imports the Phase 1 CSV and classifies evidence.
- Windows PowerShell 5.1 compatible.
- Read-only against source files.
- Current GUI already includes:
  - Phase 1 button
  - Phase 2 button
  - Open Output Folder
  - Exit
  - Activity Console ListBox
- Current source already notes that the next drop-ins are the Year formatting fix and SessionID support. :contentReference[oaicite:0]{index=0}

==================================================
DROP-IN 1 - FIX YEAR DISPLAY
==================================================

GOAL
Prevent Out-GridView from displaying:

2,024
2,025
2,026

Instead display:

2024
2025
2026

CURRENT CODE

Year =
    $lastWrite.Year

REPLACE WITH

Year =
    $lastWrite.ToString('yyyy')

RESULT
Year becomes a four-character string instead of a numeric value.

Existing chronological sorting will still work correctly because all years use the same YYYY format.

==================================================
DROP-IN 2 - ADD SESSION PARSING FUNCTION
==================================================

GOAL
Move beyond individual files and begin reconstructing historical work sessions.

WORKING RULE

Files belong to the same session when the gap between consecutive LastWriteTime values is less than or equal to a configurable threshold.

Initial threshold:

120 minutes

If the gap is greater than 120 minutes:

Start a new SessionID.

ADD FUNCTION

function Add-WorkSessions {

    param(
        [Parameter(Mandatory)]
        [array]$Records,

        [int]$SessionGapMinutes = 120
    )

    $sortedRecords = @(
        $Records |
            Sort-Object LastWriteTime
    )

    $sessionNumber = 0
    $previousTime = $null

    $results = foreach ($record in $sortedRecords) {

        $currentTime =
            [datetime]$record.LastWriteTime

        if ($null -eq $previousTime) {

            $sessionNumber++
        }
        else {

            $gapMinutes =
                ($currentTime - $previousTime).TotalMinutes

            if ($gapMinutes -gt $SessionGapMinutes) {
                $sessionNumber++
            }
        }

        [pscustomobject][ordered]@{

            SessionID =
                ('S{0:D4}' -f $sessionNumber)

            Year =
                $currentTime.ToString('yyyy')

            Classification =
                $record.Classification

            LikelySubject =
                $record.LikelySubject

            EvidenceType =
                $record.EvidenceType

            AcademicSignal =
                $record.AcademicSignal

            TechnicalSignal =
                $record.TechnicalSignal

            EvidenceStrength =
                $record.EvidenceStrength

            FileName =
                $record.FileName

            Extension =
                $record.Extension

            Directory =
                $record.Directory

            FullPath =
                $record.FullPath

            CreationTime =
                $record.CreationTime

            LastWriteTime =
                $currentTime

            SizeKB =
                $record.SizeKB
        }

        $previousTime =
            $currentTime
    }

    return $results
}

==================================================
DROP-IN 3 - APPLY SESSION PARSING IN PHASE 2
==================================================

GOAL
Run session parsing after evidence classification is complete.

LOCATION
Inside Invoke-PhaseTwo, after $classifiedRecords has been created.

ADD

$classifiedRecords = @(
    Add-WorkSessions `
        -Records $classifiedRecords `
        -SessionGapMinutes 120
)

RESULT

Each record will now have:

SessionID
S0001
S0001
S0001
S0002
S0002
S0003

The existing Phase 2 export then becomes a session-aware evidence file.

==================================================
DROP-IN 4 - UPDATE PHASE 2 SORT ORDER
==================================================

GOAL
Keep session records grouped together chronologically.

REPLACE

Sort-Object `
    Year,
    LastWriteTime,
    FileName

WITH

Sort-Object `
    SessionID,
    LastWriteTime,
    FileName

RESULT
All files belonging to a reconstructed session appear together.

==================================================
DROP-IN 5 - ADD SESSION INFORMATION TO THE CONSOLE
==================================================

GOAL
Show how many work sessions Phase 2 reconstructed.

AFTER SESSION PARSING ADD

$sessionCount = @(
    $classifiedRecords |
        Select-Object -ExpandProperty SessionID -Unique
).Count

Add-ConsoleMessage "Work sessions reconstructed: $sessionCount"

EXAMPLE

[07:30:14] PHASE 2 started.
[07:30:15] Records imported: 1847
[07:30:15] Classifying evidence...
[07:30:17] Work sessions reconstructed: 263
[07:30:17] Academic evidence records: 312
[07:30:17] Technical evidence records: 487
[07:30:17] PHASE 2 complete.

==================================================
DROP-IN 6 - BUILD A SESSION SUMMARY
==================================================

GOAL
Create one record per reconstructed work session instead of only one record per file.

PLANNED FIELDS

SessionID
Year
SessionStart
SessionEnd
DurationMinutes
FileCount
PrimarySubject
AcademicFileCount
TechnicalFileCount
StrongEvidenceCount
DirectoriesTouched

EXAMPLE

SessionID:          S0042
Year:               2023
SessionStart:       09/07/2023 09:31
SessionEnd:         09/07/2023 16:46
DurationMinutes:    435
FileCount:          14
PrimarySubject:     Cybersecurity
AcademicFileCount:  12
TechnicalFileCount: 14
StrongEvidenceCount: 11

OUTPUT

Academic_Technical_Sessions_yyyy-MM-dd_HHmmss.csv

==================================================
DROP-IN 7 - ADD PHASE 3 BUTTON
==================================================

GOAL
Keep the current console design and add a dedicated session-analysis stage.

GUI BUTTON

Phase 3 - Build Sessions

PROPOSED FLOW

Phase 1
    Build raw filesystem timeline

Phase 2
    Classify evidence

Phase 3
    Reconstruct and summarize sessions

This keeps each transformation independently auditable.

==================================================
DROP-IN 8 - ADD UNC PATH SUPPORT
==================================================

GOAL
Allow Phase 1 to scan authorized cyber-range shares.

CURRENT
FolderBrowserDialog selects local or browsable filesystem locations.

PLANNED GUI OPTIONS

[ Browse Folder ]
[ Enter UNC Path ]

EXAMPLES

D:\CyberRange

\\Server01\CyberRange

\\Server01\Students\Archive

VALIDATION

if (-not (Test-Path -LiteralPath $RootPath)) {
    throw "Path not reachable: $RootPath"
}

IMPORTANT
The scanner remains read-only.

It will only perform operations such as:

Get-ChildItem
property reads
CSV export

It will not:

modify files
execute discovered files
rename files
move files
delete files

Only scan cyber-range paths where access and authorization are already provided.

==================================================
DROP-IN 9 - CAPTURE SCAN SOURCE
==================================================

GOAL
Preserve where the evidence came from.

ADD TO PHASE 1 OBJECT

ScanRoot =
    $rootPath

This becomes especially important when multiple:

local drives
backup drives
UNC shares
cyber-range shares

are eventually analyzed together.

==================================================
DROP-IN 10 - CAPTURE ACCESS / SCAN ERRORS
==================================================

GOAL
Do not silently lose evidence when a recursive scan encounters inaccessible directories.

CURRENT VERSION

-ErrorAction SilentlyContinue

FUTURE VERSION

Capture errors into a separate collection.

PLANNED OUTPUT

Scan_Errors_yyyy-MM-dd_HHmmss.csv

FIELDS

Timestamp
ScanRoot
Path
ErrorType
Message

This allows the project to distinguish:

"No evidence found"

from:

"Directory could not be inspected"

==================================================
DROP-IN 11 - IMPROVE SESSION RULES
==================================================

FIRST VERSION
Session boundary = 120-minute inactivity gap.

LATER TESTS

60 minutes
90 minutes
120 minutes
180 minutes

We should compare results against known coursework activity before deciding which threshold best represents real working sessions.

The threshold should ultimately become configurable in the GUI.

POSSIBLE CONTROL

Session Gap:
[ 120 ] minutes

==================================================
DROP-IN 12 - SUBJECT-AWARE SESSION GROUPING
==================================================

GOAL
Prevent unrelated activity from being treated as a single logical work session solely because timestamps are close together.

FUTURE SESSION RULE MAY CONSIDER:

Time gap
LikelySubject
Directory
Classification
Course folder
Project folder

EXAMPLE

09:00 Cybersecurity Lab
09:30 Cybersecurity Screenshot
10:00 Cybersecurity Notes

Likely one session.

But:

09:00 Cybersecurity Lab
09:15 Personal WAV file
09:30 PortableApps update

should not automatically imply one academic work session.

==================================================
DROP-IN 13 - METADATA ENRICHMENT
==================================================

GOAL
Strengthen historical date evidence beyond filesystem timestamps.

FUTURE SOURCES

Office document metadata
PDF metadata
filename dates
directory names
embedded titles
script comments
course codes
semester folders

RULE
Never overwrite:

CreationTime
LastWriteTime

Instead add separate fields such as:

MetadataCreated
MetadataModified
FilenameDate
DetectedCourse
DetectedSemester

==================================================
DROP-IN 14 - EVIDENCE CONFIDENCE
==================================================

GOAL
Move EvidenceStrength from simple classification toward traceable reasoning.

FUTURE FIELDS

EvidenceStrength
EvidenceReason

EXAMPLE

EvidenceStrength = Strong

EvidenceReason =
"Path contains VALENCIA COLLEGE, filename contains VM LAB, and file is dated 2023."

This keeps classification explainable and auditable.

==================================================
DROP-IN 15 - SESSION EVIDENCE REPORT
==================================================

LONGER-TERM GOAL

Turn reconstructed sessions into a historical academic / technical timeline.

EXAMPLE

2023

Session S0042
Network Security / Cybersecurity

09/07/2023
09:31 AM - 04:46 PM

14 files

Evidence included:
- VM lab material
- screenshots
- security notes
- network/security documents

2024

Session S0117
Network Engineering

Files included:
- network diagrams
- topology work
- lab documentation

==================================================
DEVELOPMENT ORDER
==================================================

NEXT DROP-INS TO IMPLEMENT

1. Fix Year formatting.
2. Add Add-WorkSessions.
3. Assign SessionID during Phase 2.
4. Sort Phase 2 by SessionID and LastWriteTime.
5. Display session count in Activity Console.
6. Validate the 120-minute session rule.
7. Build session-summary CSV.
8. Add Phase 3 button.
9. Add UNC path input.
10. Add scan-error reporting.
11. Test against authorized cyber-range directories.
12. Tune classification and session rules from real results.

==================================================
DESIGN PRINCIPLES
==================================================

READ ONLY
Never modify source evidence.

PRESERVE RAW DATA
Phase 1 output remains the original inventory.

SEPARATE TRANSFORMATIONS
Each phase produces a new artifact.

AUDITABLE
Every classification and session traces back to original files.

WINDOWS POWERSHELL 5.1
No external modules required where practical.

SIMPLE CODE
Prefer readable PowerShell over unnecessary abstraction.

VALIDATE BEFORE EXPANDING
Each drop-in should be tested and committed before adding the next one.

==================================================
PROJECT DIRECTION
==================================================

Phase 1
Filesystem Inventory

        ↓

Phase 2
Evidence Classification

        ↓

Phase 3
Session Reconstruction

        ↓

Phase 4
Metadata Enrichment

        ↓

Phase 5
Historical Academic / Technical Evidence Report
