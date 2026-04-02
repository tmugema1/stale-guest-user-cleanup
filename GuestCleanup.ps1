# ============================================
# Stale Guest User Cleanup Script
# Author: Tom
# Description: Identifies and removes stale
# guest users from Entra ID using Graph API
# ============================================

# ---- CONFIGURATION ----
$tenantId      = "f00c89c4-5c8a-445b-b3c9-91c40742b02f"
$clientId      = "bcde5b93-b236-49ae-8723-a8518fce0e22"
$clientSecret  = "YOUR_CLIENT_SECRET_HERE"
$thresholdDays = 90
$dryRun        = $false
$exportPath    = "/Users/sankara/StaleGuestUsers.csv"

# ---- AUTHENTICATION ----
Disconnect-MgGraph -ErrorAction SilentlyContinue
$secureSecret = ConvertTo-SecureString $clientSecret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($clientId, $secureSecret)
Connect-MgGraph -TenantId $tenantId -ClientSecretCredential $credential -NoWelcome

# ---- GET GUEST USERS ----
$guestUsers = Get-MgUser -Filter "userType eq 'Guest'" -All -Property "displayName,mail,userPrincipalName,createdDateTime,id"
Write-Host "Total guest users found: $($guestUsers.Count)"

# ---- CHECK SIGN-IN ACTIVITY ----
$today = Get-Date
$staleUsers = foreach ($guest in $guestUsers) {
    $signIns = Get-MgAuditLogSignIn -Filter "userId eq '$($guest.Id)'" -Top 1 | Select-Object -First 1

    if ($signIns) {
        $lastSignIn      = $signIns.CreatedDateTime
        $daysSinceSignIn = ($today - $lastSignIn).Days
    } else {
        $lastSignIn      = "Never"
        $daysSinceSignIn = 999
    }

    if ($daysSinceSignIn -ge $thresholdDays) {
        [PSCustomObject]@{
            Id           = $guest.Id
            DisplayName  = $guest.DisplayName
            Email        = $guest.Mail
            LastSignIn   = $lastSignIn
            DaysInactive = $daysSinceSignIn
        }
    }
}

Write-Host "Stale guest users found: $($staleUsers.Count)"
$staleUsers | Format-Table -AutoSize

# ---- EXPORT REPORT ----
$staleUsers | Export-Csv -Path $exportPath -NoTypeInformation
Write-Host "Report exported to: $exportPath"

# ---- CLEANUP ----
if ($dryRun) {
    Write-Host "`nDRY RUN MODE - No users will be deleted"
    Write-Host "The following users would be deleted:"
    $staleUsers | Format-Table -AutoSize
} else {
    Write-Host "`nLIVE MODE - Deleting stale users..."
    foreach ($user in $staleUsers) {
        Remove-MgUser -UserId $user.Id
        Write-Host "Deleted: $($user.DisplayName) | $($user.Email)"
    }
    Write-Host "Cleanup complete."
}
