<#
POST-ZOICWARE AUDIT SCRIPT
Purpose:
- Audit likely changes from Zoicware RemoveWindowsAI
- Audit changes from the post-Zoicware cleanup script
- Output a readable HTML report and open it in your browser

Notes:
- Run in Windows PowerShell 5.1 as Administrator
- This is a best-effort audit of machine state
- Stops on unexpected errors to avoid console spam
- Expects microphone access to be USER CONTROLLED (0), not force denied
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param(
        [string]$Category,
        [string]$Item,
        [string]$Status,
        [string]$Details
    )

    $results.Add([pscustomobject]@{
        Category = $Category
        Item     = $Item
        Status   = $Status
        Details  = $Details
    })
}

function Encode-Html {
    param([AllowNull()][string]$Text)

    if ($null -eq $Text) { return "" }

    return ($Text `
        -replace '&', '&amp;' `
        -replace '<', '&lt;' `
        -replace '>', '&gt;' `
        -replace '"', '&quot;')
}

function Test-RegValue {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Expected,
        [string]$Category,
        [string]$Item
    )

    try {
        if (Test-Path $Path) {
            $value = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name
            if ($value -eq $Expected) {
                Add-Result $Category $Item "PASS" "Value is $value at ${Path}\$Name"
            } else {
                Add-Result $Category $Item "CHECK" "Expected $Expected, found $value at ${Path}\$Name"
            }
        } else {
            Add-Result $Category $Item "CHECK" "Registry path missing: $Path"
        }
    }
    catch {
        Add-Result $Category $Item "CHECK" "Registry value missing or unreadable: ${Path}\$Name"
    }
}

function Test-RegExists {
    param(
        [string]$Path,
        [string]$Name,
        [string]$Category,
        [string]$Item
    )

    try {
        if (Test-Path $Path) {
            $value = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name
            Add-Result $Category $Item "INFO" "Found value '$value' at ${Path}\$Name"
        } else {
            Add-Result $Category $Item "CHECK" "Registry path missing: $Path"
        }
    }
    catch {
        Add-Result $Category $Item "CHECK" "Registry value missing: ${Path}\$Name"
    }
}

function Test-TaskDisabledOrMissing {
    param(
        [string]$TaskPath,
        [string]$TaskName,
        [string]$Category,
        [string]$Item
    )

    try {
        $task = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction Stop
        if ($task.State -eq "Disabled") {
            Add-Result $Category $Item "PASS" "Scheduled task exists and is Disabled: $TaskPath$TaskName"
        } else {
            Add-Result $Category $Item "CHECK" "Scheduled task exists with state '$($task.State)': $TaskPath$TaskName"
        }
    }
    catch {
        Add-Result $Category $Item "PASS" "Scheduled task not found: $TaskPath$TaskName"
    }
}

function Test-AppxAbsentByPattern {
    param(
        [string[]]$Patterns,
        [string]$Category,
        [string]$Item
    )

    $matches = @()

    try {
        $all = Get-AppxPackage -AllUsers

        foreach ($p in $Patterns) {
            $matches += $all | Where-Object {
                $_.Name -match $p -or $_.PackageFullName -match $p
            }
        }

        $matches = $matches | Sort-Object PackageFullName -Unique

        if ($matches.Count -eq 0) {
            Add-Result $Category $Item "PASS" "No matching Appx packages found"
        } else {
            $names = ($matches | Select-Object -ExpandProperty PackageFullName) -join "; "
            Add-Result $Category $Item "CHECK" "Matching Appx packages still present: $names"
        }
    }
    catch {
        Add-Result $Category $Item "CHECK" "Could not enumerate Appx packages"
    }
}

function Test-OptionalFeatureRemovedOrDisabled {
    param(
        [string[]]$Patterns,
        [string]$Category,
        [string]$Item
    )

    try {
        $features = Get-WindowsOptionalFeature -Online
        $matches = foreach ($pat in $Patterns) {
            $features | Where-Object { $_.FeatureName -match $pat }
        }

        $matches = $matches | Sort-Object FeatureName -Unique

        if (-not $matches) {
            Add-Result $Category $Item "PASS" "No matching optional features found"
        } else {
            foreach ($m in $matches) {
                if ($m.State -match "Disabled") {
                    Add-Result $Category "$Item ($($m.FeatureName))" "PASS" "Feature state: $($m.State)"
                } else {
                    Add-Result $Category "$Item ($($m.FeatureName))" "CHECK" "Feature state: $($m.State)"
                }
            }
        }
    }
    catch {
        Add-Result $Category $Item "CHECK" "Could not enumerate optional features"
    }
}

function Test-FileMissing {
    param(
        [string]$Path,
        [string]$Category,
        [string]$Item
    )

    try {
        if ($Path -like '*`**' -or $Path -like '*[*?]*') {
            $found = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue
            if ($found) {
                $names = ($found | ForEach-Object { $_.FullName }) -join "; "
                Add-Result $Category $Item "CHECK" "Matching file/folder(s) still exist: $names"
            } else {
                Add-Result $Category $Item "PASS" "Missing as expected: $Path"
            }
        } else {
            if (Test-Path $Path) {
                Add-Result $Category $Item "CHECK" "File/folder still exists: $Path"
            } else {
                Add-Result $Category $Item "PASS" "Missing as expected: $Path"
            }
        }
    }
    catch {
        Add-Result $Category $Item "CHECK" "Could not test path: $Path"
    }
}

# -------------------------------------------------
# 1. Audit your post-Zoicware cleanup script
# -------------------------------------------------

Test-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" 0 "PostScript" "Widgets disabled"
Test-RegValue "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" "value" 0 "PostScript" "Widgets policy backing store"

Test-RegValue "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsSpotlightFeatures" 1 "PostScript" "Windows Spotlight features disabled"
Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "RotatingLockScreenEnabled" 0 "PostScript" "Lock screen rotation disabled"
Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "RotatingLockScreenOverlayEnabled" 0 "PostScript" "Lock screen promo overlay disabled"

Test-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" "HideRecommendedSection" 1 "PostScript" "Start Recommended section hidden"
Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SilentInstalledAppsEnabled" 0 "PostScript" "Silent installed apps disabled"
Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "PreInstalledAppsEnabled" 0 "PostScript" "Preinstalled apps disabled"
Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "PreInstalledAppsEverEnabled" 0 "PostScript" "Preinstalled apps ever disabled"
Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "OemPreInstalledAppsEnabled" 0 "PostScript" "OEM preinstalled apps disabled"

Test-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableCloudOptimizedContent" 1 "PostScript" "Settings suggested content disabled"
Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0 "PostScript" "Advertising ID disabled"
Test-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "DisableAdvertisingId" 1 "PostScript" "Advertising ID policy disabled"
Test-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" 1 "PostScript" "Windows consumer features disabled"
Test-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableConsumerFeatures" 1 "PostScript" "Consumer features disabled"
Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SoftLandingEnabled" 0 "PostScript" "Soft landing disabled"
Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SystemPaneSuggestionsEnabled" 0 "PostScript" "System pane suggestions disabled"
Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" "ScoobeSystemSettingEnabled" 0 "PostScript" "Finish setting up device nags disabled"

Test-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowSyncProviderNotifications" 0 "PostScript" "Explorer sync provider promos disabled"

# App privacy values
$privacyChecks = @(
    @{ Name = "LetAppsAccessAccountInfo"; Expected = 2; Label = "LetAppsAccessAccountInfo forced deny" },
    @{ Name = "LetAppsAccessLocation";    Expected = 2; Label = "LetAppsAccessLocation forced deny" },
    @{ Name = "LetAppsAccessCamera";      Expected = 2; Label = "LetAppsAccessCamera forced deny" },
    @{ Name = "LetAppsAccessMicrophone";  Expected = 0; Label = "LetAppsAccessMicrophone user controlled" },
    @{ Name = "LetAppsRunInBackground";   Expected = 2; Label = "LetAppsRunInBackground forced deny" },
    @{ Name = "LetAppsAccessRadios";      Expected = 2; Label = "LetAppsAccessRadios forced deny" },
    @{ Name = "LetAppsAccessCalendar";    Expected = 2; Label = "LetAppsAccessCalendar forced deny" },
    @{ Name = "LetAppsAccessCallHistory"; Expected = 2; Label = "LetAppsAccessCallHistory forced deny" },
    @{ Name = "LetAppsAccessEmail";       Expected = 2; Label = "LetAppsAccessEmail forced deny" },
    @{ Name = "LetAppsAccessMessaging";   Expected = 2; Label = "LetAppsAccessMessaging forced deny" },
    @{ Name = "LetAppsAccessPhone";       Expected = 2; Label = "LetAppsAccessPhone forced deny" }
)

foreach ($check in $privacyChecks) {
    Test-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" $check.Name $check.Expected "PostScript" $check.Label
}

Test-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" "DisableLocation" 1 "PostScript" "System location disabled"

# -------------------------------------------------
# 2. Audit likely Zoicware registry outcomes
# -------------------------------------------------

Test-RegExists "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" "Zoicware" "Windows Copilot user policy"
Test-RegExists "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" "Zoicware" "Windows Copilot machine policy"
Test-RegExists "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" "Zoicware" "Windows AI policy path present"
Test-RegExists "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "HubsSidebarEnabled" "Zoicware" "Edge sidebar/Copilot policy present"
Test-RegExists "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "CopilotPageContext" "Zoicware" "Edge Copilot page context policy present"
Test-RegExists "HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\OfficeExperiments" "OfficeCopilotDisabled" "Zoicware" "Office Copilot policy present"
Test-RegExists "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Notepad" "DisableAIRewrite" "Zoicware" "Notepad Rewrite policy present"

# -------------------------------------------------
# 3. Audit Appx package absence
# -------------------------------------------------

Test-AppxAbsentByPattern @(
    "Copilot",
    "WindowsAI",
    "Recall",
    "AIX",
    "MicrosoftWindows\.Client\.CBS",
    "WindowsWorkload",
    "Microsoft\.Paint",
    "Microsoft\.ScreenSketch",
    "Microsoft\.WindowsNotepad"
) "Zoicware" "AI-related Appx packages absent"

# -------------------------------------------------
# 4. Audit optional features
# -------------------------------------------------

Test-OptionalFeatureRemovedOrDisabled @(
    "Recall",
    "WindowsRecall"
) "Zoicware" "Recall / AI optional feature"

# -------------------------------------------------
# 5. Audit scheduled tasks
# -------------------------------------------------

$recallTaskCandidates = @(
    @{ Path = "\Microsoft\Windows\"; Name = "Recall" },
    @{ Path = "\Microsoft\Windows\Recall\"; Name = "Recall" },
    @{ Path = "\Microsoft\Windows\Application Experience\"; Name = "Recall" },
    @{ Path = "\Microsoft\Windows\Shell\"; Name = "Recall" }
)

foreach ($t in $recallTaskCandidates) {
    Test-TaskDisabledOrMissing $t.Path $t.Name "Zoicware" "Recall task candidate $($t.Path)$($t.Name)"
}

try {
    $allTasks = Get-ScheduledTask | Where-Object {
        $_.TaskName -match "RemoveAI|WindowsAI|Zoicware|Recall|Copilot"
    }

    if ($allTasks) {
        foreach ($t in $allTasks) {
            Add-Result "Zoicware" "AI-related scheduled task" "INFO" "$($t.TaskPath)$($t.TaskName) state=$($t.State)"
        }
    } else {
        Add-Result "Zoicware" "AI-related scheduled tasks" "CHECK" "No obvious Zoicware-related scheduled tasks found"
    }
}
catch {
    Add-Result "Zoicware" "AI-related scheduled tasks" "CHECK" "Could not enumerate scheduled tasks"
}

# -------------------------------------------------
# 6. Audit files and folders
# -------------------------------------------------

Test-FileMissing "$env:SystemRoot\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy" "Zoicware" "Client CBS system app folder"
Test-FileMissing "C:\Program Files\WindowsApps\MicrosoftWindows.Client.CBS*" "Zoicware" "Client CBS WindowsApps folder wildcard note"
Test-FileMissing "$env:SystemRoot\System32\Recall" "Zoicware" "Recall system folder"

# -------------------------------------------------
# 7. Audit CBS package keys
# -------------------------------------------------

try {
    $cbsKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages"

    if (Test-Path $cbsKey) {
        $aiCbs = Get-ChildItem $cbsKey -ErrorAction SilentlyContinue | Where-Object {
            $_.PSChildName -match "Copilot|Recall|WindowsAI"
        }

        if ($aiCbs) {
            $names = ($aiCbs | Select-Object -ExpandProperty PSChildName) -join "; "
            Add-Result "Zoicware" "CBS AI-related package keys" "CHECK" "Still present: $names"
        } else {
            Add-Result "Zoicware" "CBS AI-related package keys" "PASS" "No obvious AI-related CBS package keys found"
        }
    } else {
        Add-Result "Zoicware" "CBS AI-related package keys" "CHECK" "CBS package registry path missing or unreadable"
    }
}
catch {
    Add-Result "Zoicware" "CBS AI-related package keys" "CHECK" "Could not enumerate CBS package keys"
}

# -------------------------------------------------
# 8. Output HTML report
# -------------------------------------------------

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportPath = "$env:USERPROFILE\Desktop\PostZoicware_Audit_$timestamp.html"

$passCount  = ($results | Where-Object { $_.Status -eq "PASS" }).Count
$checkCount = ($results | Where-Object { $_.Status -eq "CHECK" }).Count
$infoCount  = ($results | Where-Object { $_.Status -eq "INFO" }).Count
$totalCount = $results.Count

$style = @"
<style>
body {
    font-family: Segoe UI, Arial, sans-serif;
    background: #1e1e1e;
    color: #ddd;
    margin: 20px;
}
h1, h2 {
    color: #6ab0ff;
}
.summary {
    display: flex;
    gap: 20px;
    margin-bottom: 20px;
    flex-wrap: wrap;
}
.card {
    padding: 12px 16px;
    border-radius: 8px;
    min-width: 140px;
    font-weight: bold;
    box-shadow: 0 0 6px rgba(0,0,0,0.35);
}
.passcard {
    background: #133913;
}
.checkcard {
    background: #3a2f0d;
}
.infocard {
    background: #0d2b3a;
}
.totalcard {
    background: #333;
}
table {
    border-collapse: collapse;
    width: 100%;
    margin-top: 15px;
}
th {
    background: #333;
    padding: 10px;
    text-align: left;
    position: sticky;
    top: 0;
}
td {
    padding: 8px;
    border-bottom: 1px solid #444;
    vertical-align: top;
}
tr.pass {
    background: #133913;
}
tr.check {
    background: #3a2f0d;
}
tr.info {
    background: #0d2b3a;
}
tr:hover {
    filter: brightness(1.08);
}
.meta {
    margin-bottom: 20px;
    line-height: 1.6;
}
.small {
    color: #aaa;
    font-size: 0.92em;
}
</style>
"@

$htmlRows = foreach ($r in ($results | Sort-Object Category, Item)) {
    $class = switch ($r.Status) {
        "PASS"  { "pass" }
        "CHECK" { "check" }
        "INFO"  { "info" }
        default { "info" }
    }

    $category = Encode-Html $r.Category
    $item     = Encode-Html $r.Item
    $status   = Encode-Html $r.Status
    $details  = Encode-Html $r.Details

@"
<tr class="$class">
    <td>$category</td>
    <td>$item</td>
    <td>$status</td>
    <td>$details</td>
</tr>
"@
}

$html = @"
<html>
<head>
<meta charset="utf-8">
<title>Post Zoicware Audit</title>
$style
</head>
<body>

<h1>Post Zoicware Audit Report</h1>

<div class="meta">
    <b>Computer:</b> $(Encode-Html $env:COMPUTERNAME)<br>
    <b>User:</b> $(Encode-Html $env:USERNAME)<br>
    <b>Date:</b> $(Encode-Html (Get-Date).ToString())<br>
    <span class="small">PASS = expected state detected, CHECK = missing/different/could not verify, INFO = informative only</span>
</div>

<div class="summary">
    <div class="card passcard">PASS: $passCount</div>
    <div class="card checkcard">CHECK: $checkCount</div>
    <div class="card infocard">INFO: $infoCount</div>
    <div class="card totalcard">TOTAL: $totalCount</div>
</div>

<table>
    <tr>
        <th style="width: 16%;">Category</th>
        <th style="width: 28%;">Item</th>
        <th style="width: 10%;">Status</th>
        <th style="width: 46%;">Details</th>
    </tr>
    $($htmlRows -join "`n")
</table>

</body>
</html>
"@

$html | Set-Content -Path $reportPath -Encoding UTF8

Write-Host ""
Write-Host "Audit complete." -ForegroundColor Cyan
Write-Host "HTML report saved to: $reportPath" -ForegroundColor Green
Write-Host ""

Start-Process $reportPath