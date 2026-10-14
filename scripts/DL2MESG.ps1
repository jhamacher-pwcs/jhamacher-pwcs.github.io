#Requires -Modules ExchangeOnlineManagement

<#
    DL -> Mail-Enabled Security Group Cutover

    INPUT EXAMPLE:
        Sample_Staff

    EXPECTS:
        OLD Exchange Online DL:
            Sample_Staff

        NEW pre-created Mail-Enabled Security Group:
            Sample_Staff_new

    FINAL:
        Old Exchange Online DL is removed.

        Sample_Staff_new becomes:
            Name:         Sample_Staff
            DisplayName:  Sample_Staff
            Alias:        Sample_Staff
            Primary SMTP: Sample_Staff@example.org

        Old LegacyExchangeDN is preserved as X500.

    NOTE:
        This does NOT touch your separately-managed AD groups.
#>


# ============================================================
# CONNECT TO EXCHANGE ONLINE
# ============================================================

Connect-ExchangeOnline


# ============================================================
# GET OLD IDENTITY
# ============================================================

$OldIdentity = Read-Host "Enter OLD group identity (example: Sample_Staff)"

if ([string]::IsNullOrWhiteSpace($OldIdentity)) {
    Write-Host "No identity entered. Exiting." -ForegroundColor Red
    return
}

$NewIdentity = "${OldIdentity}_new"


# ============================================================
# FIND OLD GROUP
# ============================================================

try {

    $Old = Get-DistributionGroup `
        -Identity $OldIdentity `
        -ErrorAction Stop

}
catch {

    Write-Host ""
    Write-Host "ERROR: Could not find old group:" -ForegroundColor Red
    Write-Host "  $OldIdentity"
    return
}


# ============================================================
# FIND NEW GROUP
# ============================================================

try {

    $New = Get-DistributionGroup `
        -Identity $NewIdentity `
        -ErrorAction Stop

}
catch {

    Write-Host ""
    Write-Host "ERROR: Could not find replacement group:" -ForegroundColor Red
    Write-Host "  $NewIdentity"
    return
}


# ============================================================
# VERIFY NEW GROUP IS SECURITY ENABLED
# ============================================================

if ($New.GroupType -notmatch "SecurityEnabled") {

    Write-Host ""
    Write-Host "ERROR: Replacement group is not Security Enabled." -ForegroundColor Red
    Write-Host ""
    Write-Host "Group:     $($New.Name)"
    Write-Host "GroupType: $($New.GroupType)"

    return
}


# ============================================================
# CAPTURE OLD GROUP INFORMATION
# ============================================================

$OriginalName        = $Old.Name
$OriginalDisplayName = $Old.DisplayName
$OriginalAlias       = $Old.Alias

$OriginalPrimarySMTP = $Old.PrimarySmtpAddress.ToString()
$OriginalLegacyDN    = $Old.LegacyExchangeDN

$OldLegacyX500 = "X500:$OriginalLegacyDN"


# ============================================================
# CAPTURE SMTP ADDRESSES
#
# Do NOT copy onmicrosoft.com addresses.
# ============================================================

$SMTPAddressesToTransfer = @(
    $Old.EmailAddresses |
        ForEach-Object { $_.ToString() } |
        Where-Object {
            $_ -match "^(?i)smtp:" -and
            $_ -notmatch "(?i)\.onmicrosoft\.com$"
        }
)


# ============================================================
# CAPTURE EXISTING X500 ADDRESSES
# ============================================================

$X500AddressesToTransfer = @(
    $Old.EmailAddresses |
        ForEach-Object { $_.ToString() } |
        Where-Object {
            $_ -match "^(?i)x500:"
        }
)


# Add actual LegacyExchangeDN

if ($X500AddressesToTransfer -notcontains $OldLegacyX500) {

    $X500AddressesToTransfer += $OldLegacyX500
}


# ============================================================
# CAPTURE SETTINGS
# ============================================================

$RequireAuth = $Old.RequireSenderAuthenticationEnabled
$HiddenGAL   = $Old.HiddenFromAddressListsEnabled


# ============================================================
# DISPLAY CURRENT CONFIGURATION
# ============================================================

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host " OLD DISTRIBUTION GROUP" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "Name:              $OriginalName"
Write-Host "DisplayName:       $OriginalDisplayName"
Write-Host "Alias:             $OriginalAlias"
Write-Host "Primary SMTP:      $OriginalPrimarySMTP"
Write-Host "LegacyExchangeDN:  $OriginalLegacyDN"

Write-Host ""
Write-Host "Email Addresses:" -ForegroundColor Cyan

$Old.EmailAddresses |
    ForEach-Object {
        Write-Host "  $_"
    }


Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host " NEW MAIL-ENABLED SECURITY GROUP" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan

Write-Host ""

$New |
    Select-Object `
        Name,
        DisplayName,
        Alias,
        GroupType,
        PrimarySmtpAddress,
        LegacyExchangeDN,
        EmailAddresses |
    Format-List


# ============================================================
# SHOW WHAT WILL TRANSFER
# ============================================================

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Yellow
Write-Host " MIGRATION PLAN" -ForegroundColor Yellow
Write-Host "=====================================================" -ForegroundColor Yellow


Write-Host ""
Write-Host "OLD GROUP WILL BE REMOVED FROM EXCHANGE ONLINE:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  $OriginalName"


Write-Host ""
Write-Host "NEW GROUP:" -ForegroundColor Green
Write-Host ""
Write-Host "  $NewIdentity"
Write-Host "       ->"
Write-Host "  $OriginalName"


Write-Host ""
Write-Host "Primary SMTP:" -ForegroundColor Green
Write-Host ""
Write-Host "  $OriginalPrimarySMTP"


Write-Host ""
Write-Host "SMTP addresses to transfer:" -ForegroundColor Green

foreach ($Address in $SMTPAddressesToTransfer) {
    Write-Host "  $Address"
}


Write-Host ""
Write-Host "X500 addresses to transfer:" -ForegroundColor Green

foreach ($Address in $X500AddressesToTransfer) {
    Write-Host "  $Address"
}


# ============================================================
# SAFETY CHECK
# ============================================================

if (
    [string]::IsNullOrWhiteSpace($OriginalPrimarySMTP) -or
    [string]::IsNullOrWhiteSpace($OriginalLegacyDN)
) {

    Write-Host ""
    Write-Host "ERROR: Missing Primary SMTP or LegacyExchangeDN." -ForegroundColor Red
    Write-Host "Migration cancelled." -ForegroundColor Red

    return
}


# ============================================================
# EXPORT BACKUP
# ============================================================

$SafeFileName = $OriginalName -replace '[\\/:*?"<>|]', '_'

$BackupFile = Join-Path `
    -Path $PSScriptRoot `
    -ChildPath "$($SafeFileName)_ExchangeBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"


$Backup = @"

============================================================
Exchange Online Group Backup
============================================================

Date:
$(Get-Date)

Name:
$OriginalName

DisplayName:
$OriginalDisplayName

Alias:
$OriginalAlias

Primary SMTP:
$OriginalPrimarySMTP

LegacyExchangeDN:
$OriginalLegacyDN

RequireSenderAuthenticationEnabled:
$RequireAuth

HiddenFromAddressListsEnabled:
$HiddenGAL


EMAIL ADDRESSES
------------------------------------------------------------

$($Old.EmailAddresses -join "`r`n")


X500 TO ADD TO REPLACEMENT
------------------------------------------------------------

$($X500AddressesToTransfer -join "`r`n")


REPLACEMENT GROUP
------------------------------------------------------------

Name:
$($New.Name)

DisplayName:
$($New.DisplayName)

Alias:
$($New.Alias)

Primary SMTP:
$($New.PrimarySmtpAddress)

LegacyExchangeDN:
$($New.LegacyExchangeDN)

Email Addresses:
$($New.EmailAddresses -join "`r`n")

"@

$Backup | Out-File `
    -FilePath $BackupFile `
    -Encoding UTF8


Write-Host ""
Write-Host "Backup written to:" -ForegroundColor Green
Write-Host "  $BackupFile"


# ============================================================
# FINAL CONFIRMATION
# ============================================================

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Red
Write-Host " IMPORTANT" -ForegroundColor Red
Write-Host "=====================================================" -ForegroundColor Red

Write-Host ""
Write-Host "This will REMOVE the old Exchange Online DL:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  $OriginalName"
Write-Host ""
Write-Host "and transfer its mail identity to:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  $NewIdentity"
Write-Host ""

$Confirmation = Read-Host "Type CUTOVER to continue"

if ($Confirmation -cne "CUTOVER") {

    Write-Host ""
    Write-Host "Cancelled. No changes made." -ForegroundColor Yellow
    return
}


# ============================================================
# REMOVE OLD EXCHANGE ONLINE DL
# ============================================================

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host " REMOVING OLD EXCHANGE ONLINE DL" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan

Remove-DistributionGroup `
    -Identity $Old.Identity `
    -Confirm:$false `
    -ErrorAction Stop


Write-Host ""
Write-Host "Old DL removed." -ForegroundColor Green


# ============================================================
# WAIT FOR EXCHANGE TO RELEASE RECIPIENT ADDRESSES
# ============================================================

Write-Host ""
Write-Host "Waiting for Exchange Online to release old recipient..." -ForegroundColor Cyan

$Released = $false

for ($i = 1; $i -le 12; $i++) {

    Start-Sleep -Seconds 5

    $Conflict = Get-Recipient `
        -Filter "EmailAddresses -eq 'smtp:$OriginalPrimarySMTP'" `
        -ErrorAction SilentlyContinue

    if (-not $Conflict) {

        $Released = $true
        break
    }

    Write-Host "  Still waiting... attempt $i of 12"
}


if (-not $Released) {

    Write-Host ""
    Write-Host "WARNING:" -ForegroundColor Red
    Write-Host "Exchange still reports the old SMTP as assigned." -ForegroundColor Red
    Write-Host ""
    Write-Host "The old DL has already been removed." -ForegroundColor Yellow
    Write-Host "Do NOT create another object." -ForegroundColor Yellow
    Write-Host "Wait for Exchange Online propagation and continue manually." -ForegroundColor Yellow

    return
}


# ============================================================
# REFRESH NEW GROUP
# ============================================================

$New = Get-DistributionGroup `
    -Identity $NewIdentity `
    -ErrorAction Stop


# ============================================================
# ADD OLD X500 ADDRESSES
# ============================================================

Write-Host ""
Write-Host "Adding historical X500 addresses..." -ForegroundColor Cyan

foreach ($X500 in $X500AddressesToTransfer) {

    try {

        Set-DistributionGroup `
            -Identity $New.Identity `
            -EmailAddresses @{Add=$X500} `
            -IgnoreNamingPolicy `
            -ErrorAction Stop

        Write-Host "  Added: $X500" -ForegroundColor Green

    }
    catch {

        Write-Host ""
        Write-Host "FAILED TO ADD X500:" -ForegroundColor Red
        Write-Host "  $X500"
        Write-Host ""
        Write-Host $_.Exception.Message -ForegroundColor Red

        return
    }
}


# ============================================================
# ADD SMTP ALIASES
#
# Add them lowercase first.
# Primary SMTP is set separately.
# ============================================================

Write-Host ""
Write-Host "Adding SMTP addresses..." -ForegroundColor Cyan

foreach ($SMTPAddress in $SMTPAddressesToTransfer) {

    $AddressOnly = $SMTPAddress -replace "^(?i)smtp:", ""

    # Primary SMTP gets assigned separately

    if ($AddressOnly -ieq $OriginalPrimarySMTP) {
        continue
    }

    $ProxyAddress = "smtp:$AddressOnly"

    try {

        Set-DistributionGroup `
            -Identity $New.Identity `
            -EmailAddresses @{Add=$ProxyAddress} `
            -ErrorAction Stop

        Write-Host "  Added: $ProxyAddress" -ForegroundColor Green

    }
    catch {

        Write-Host ""
        Write-Host "FAILED TO ADD SMTP:" -ForegroundColor Red
        Write-Host "  $ProxyAddress"
        Write-Host ""
        Write-Host $_.Exception.Message -ForegroundColor Red

        return
    }
}


# ============================================================
# SET ORIGINAL PRIMARY SMTP
# ============================================================

Write-Host ""
Write-Host "Setting Primary SMTP:" -ForegroundColor Cyan
Write-Host "  $OriginalPrimarySMTP"

Set-DistributionGroup `
    -Identity $New.Identity `
    -PrimarySmtpAddress $OriginalPrimarySMTP `
    -ErrorAction Stop


# ============================================================
# COPY MAIL SETTINGS
# ============================================================

Write-Host ""
Write-Host "Applying original mail settings..." -ForegroundColor Cyan

Set-DistributionGroup `
    -Identity $New.Identity `
    -RequireSenderAuthenticationEnabled $RequireAuth `
    -HiddenFromAddressListsEnabled $HiddenGAL `
    -ErrorAction Stop


# ============================================================
# RENAME REPLACEMENT
# ============================================================

Write-Host ""
Write-Host "Applying original identity..." -ForegroundColor Cyan

Set-DistributionGroup `
    -Identity $New.Identity `
    -Name $OriginalName `
    -DisplayName $OriginalDisplayName `
    -Alias $OriginalAlias `
    -ErrorAction Stop


# ============================================================
# WAIT A FEW SECONDS AND VERIFY
# ============================================================

Start-Sleep -Seconds 5


$Final = Get-DistributionGroup `
    -Identity $OriginalPrimarySMTP `
    -ErrorAction Stop


# ============================================================
# FINAL RESULTS
# ============================================================

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Green
Write-Host " MIGRATION COMPLETE" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green

Write-Host ""

$Final |
    Select-Object `
        Name,
        DisplayName,
        Alias,
        GroupType,
        PrimarySmtpAddress,
        LegacyExchangeDN,
        RequireSenderAuthenticationEnabled,
        HiddenFromAddressListsEnabled,
        EmailAddresses |
    Format-List


# ============================================================
# VERIFY OLD LEGACY DN IS NOW X500
# ============================================================

$FinalAddresses = @(
    $Final.EmailAddresses |
        ForEach-Object { $_.ToString() }
)


Write-Host ""
Write-Host "LegacyExchangeDN / X500 test:" -ForegroundColor Cyan

if ($FinalAddresses -contains $OldLegacyX500) {

    Write-Host "  PASS" -ForegroundColor Green
    Write-Host "  Old LegacyExchangeDN preserved as:"
    Write-Host "  $OldLegacyX500" -ForegroundColor Green

}
else {

    Write-Host "  FAIL" -ForegroundColor Red
    Write-Host "  Old LegacyExchangeDN was NOT found as X500." -ForegroundColor Red
}


# ============================================================
# VERIFY PRIMARY SMTP
# ============================================================

Write-Host ""
Write-Host "Primary SMTP test:" -ForegroundColor Cyan

if ($Final.PrimarySmtpAddress.ToString() -ieq $OriginalPrimarySMTP) {

    Write-Host "  PASS - $OriginalPrimarySMTP" -ForegroundColor Green

}
else {

    Write-Host "  FAIL" -ForegroundColor Red
}


Write-Host ""
Write-Host "=====================================================" -ForegroundColor Green
Write-Host " DONE" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
