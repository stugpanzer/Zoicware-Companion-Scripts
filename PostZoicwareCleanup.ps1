<#
POST-ZOICWARE WINDOWS 11 CLEANUP
Purpose:
- Disable Widgets
- Disable Windows Spotlight promos / lock-screen promos
- Reduce Start / Settings suggested content
- Reduce File Explorer sync-provider promos
- Apply a conservative set of app-privacy restrictions for Windows apps
- Leave microphone access under USER CONTROL for apps like Discord

Notes:
- Run in an elevated PowerShell session
- HKLM policy settings affect the device
- HKCU settings affect only the current user
- Some changes may need sign-out or reboot
- App privacy restrictions in this script apply to Windows apps, not all classic desktop apps
#>

#Requires -RunAsAdministrator

Write-Host "Starting post-Zoicware Windows 11 cleanup..." -ForegroundColor Cyan

# -------------------------------
# Helper
# -------------------------------
function Ensure-Key {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
}

function Set-Dword {
    param(
        [string]$Path,
        [string]$Name,
        [int]$Value
    )
    Ensure-Key -Path $Path
    Set-ItemProperty -Path $Path -Name $Name -Type DWord -Value $Value -Force
}

# -------------------------------
# Registry paths
# -------------------------------
$paths = @(
    "HKLM:\SOFTWARE\Policies\Microsoft\Dsh",
    "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests",
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent",
    "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent",
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System",
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer",
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy",
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
)

foreach ($p in $paths) { Ensure-Key -Path $p }

# -------------------------------
# 1. Disable Widgets
# -------------------------------
Write-Host "[1/8] Disabling Widgets..." -ForegroundColor Yellow

Set-Dword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" `
    -Name "AllowNewsAndInterests" `
    -Value 0

Set-Dword -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" `
    -Name "value" `
    -Value 0

# -------------------------------
# 2. Disable lock-screen promos / Spotlight features
# -------------------------------
Write-Host "[2/8] Disabling lock-screen promos and Spotlight nags..." -ForegroundColor Yellow

Set-Dword -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" `
    -Name "DisableWindowsSpotlightFeatures" `
    -Value 1

Set-Dword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name "RotatingLockScreenEnabled" `
    -Value 0

Set-Dword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name "RotatingLockScreenOverlayEnabled" `
    -Value 0

Set-Dword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name "SubscribedContent-338387Enabled" `
    -Value 0

Set-Dword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name "SubscribedContent-338388Enabled" `
    -Value 0

Set-Dword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name "SubscribedContent-338389Enabled" `
    -Value 0

Set-Dword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name "SubscribedContent-338393Enabled" `
    -Value 0

# -------------------------------
# 3. Disable Start menu recommended section and promoted installs
# -------------------------------
Write-Host "[3/8] Cleaning up Start menu recommendations..." -ForegroundColor Yellow

Set-Dword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" `
    -Name "HideRecommendedSection" `
    -Value 1

Set-Dword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name "SilentInstalledAppsEnabled" `
    -Value 0

Set-Dword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name "PreInstalledAppsEnabled" `
    -Value 0

Set-Dword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name "PreInstalledAppsEverEnabled" `
    -Value 0

Set-Dword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name "OemPreInstalledAppsEnabled" `
    -Value 0

# -------------------------------
# 4. Disable suggested content in Settings and general ads/suggestions
# -------------------------------
Write-Host "[4/8] Disabling suggested content in Settings and Windows..." -ForegroundColor Yellow

Set-Dword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" `
    -Name "DisableCloudOptimizedContent" `
    -Value 1

Set-Dword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" `
    -Name "Enabled" `
    -Value 0

Set-Dword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
    -Name "DisableAdvertisingId" `
    -Value 1

Set-Dword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" `
    -Name "DisableWindowsConsumerFeatures" `
    -Value 1

Set-Dword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" `
    -Name "DisableConsumerFeatures" `
    -Value 1

Set-Dword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name "SoftLandingEnabled" `
    -Value 0

Set-Dword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name "SystemPaneSuggestionsEnabled" `
    -Value 0

Set-Dword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" `
    -Name "ScoobeSystemSettingEnabled" `
    -Value 0

# -------------------------------
# 5. Reduce File Explorer sync-provider promos
# -------------------------------
Write-Host "[5/8] Reducing File Explorer sync-provider promos..." -ForegroundColor Yellow

Set-Dword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name "ShowSyncProviderNotifications" `
    -Value 0

# -------------------------------
# 6. Optional app-privacy toggles for Windows apps
# -------------------------------
Write-Host "[6/8] Applying conservative app-privacy restrictions..." -ForegroundColor Yellow

# 0 = User in control
# 1 = Force allow
# 2 = Force deny

Set-Dword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" `
    -Name "LetAppsAccessAccountInfo" `
    -Value 2

Set-Dword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" `
    -Name "LetAppsAccessLocation" `
    -Value 2

Set-Dword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" `
    -Name "LetAppsAccessCamera" `
    -Value 2

# MICROPHONE LEFT USER-CONTROLLED
Set-Dword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" `
    -Name "LetAppsAccessMicrophone" `
    -Value 0

Set-Dword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" `
    -Name "LetAppsRunInBackground" `
    -Value 2

Set-Dword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" `
    -Name "LetAppsAccessRadios" `
    -Value 2

Set-Dword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" `
    -Name "DisableLocation" `
    -Value 1

# -------------------------------
# 7. Extra optional privacy toggles
# -------------------------------
Write-Host "[7/8] Applying extra optional privacy toggles..." -ForegroundColor Yellow

Set-Dword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" `
    -Name "LetAppsAccessCalendar" `
    -Value 2

Set-Dword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" `
    -Name "LetAppsAccessCallHistory" `
    -Value 2

Set-Dword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" `
    -Name "LetAppsAccessEmail" `
    -Value 2

Set-Dword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" `
    -Name "LetAppsAccessMessaging" `
    -Value 2

Set-Dword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" `
    -Name "LetAppsAccessPhone" `
    -Value 2

# -------------------------------
# 8. Wrap-up
# -------------------------------
Write-Host "[8/8] Done." -ForegroundColor Yellow
Write-Host ""
Write-Host "Post-Zoicware cleanup complete." -ForegroundColor Cyan
Write-Host "Recommended: sign out or reboot to apply everything cleanly." -ForegroundColor Cyan
Write-Host ""
Write-Host "Microphone access is left user-controlled for apps like Discord." -ForegroundColor Green
